import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/pdf_annotation.dart';
import '../../logging/app_logger.dart';
import '../../exceptions/app_exceptions.dart';
import '../supabase/supabase_service.dart';
import '../../config/app_config.dart';

/// Service for managing PDF annotations
class AnnotationService {
  static final AppLogger _logger = AppLogger('AnnotationService');
  static final SupabaseService _supabase = SupabaseService();

  /// Storage for annotations (in-memory cache)
  static final Map<String, List<PdfAnnotation>> _annotationsCache = {};

  /// Get all annotations for a PDF file
  static Future<List<PdfAnnotation>> getAnnotations(String pdfPath) async {
    try {
      _logger.debug('Getting annotations for PDF', data: {'path': pdfPath});

      // Check cache first
      if (_annotationsCache.containsKey(pdfPath)) {
        _logger.debug('Returning cached annotations');
        return _annotationsCache[pdfPath]!;
      }

      // Try to load from Supabase if configured
      if (AppConfig.hasSupabaseConfig && AppConfig.enableCloudSync) {
        try {
          final annotations = await _loadFromSupabase(pdfPath);
          _annotationsCache[pdfPath] = annotations;
          return annotations;
        } catch (e) {
          _logger.warning('Failed to load from Supabase, trying local',
              data: {'error': e.toString()});
        }
      }

      // Load from local storage
      final annotations = await _loadFromLocal(pdfPath);
      _annotationsCache[pdfPath] = annotations;
      return annotations;
    } catch (e, stackTrace) {
      _logger.error('Failed to get annotations',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to load annotations',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add annotation to a PDF
  static Future<void> addAnnotation(
    String pdfPath,
    PdfAnnotation annotation,
  ) async {
    try {
      _logger.info('Adding annotation',
          data: {'path': pdfPath, 'type': annotation.type});

      // Update cache
      if (!_annotationsCache.containsKey(pdfPath)) {
        _annotationsCache[pdfPath] = [];
      }
      _annotationsCache[pdfPath]!.add(annotation);

      // Save to Supabase if configured
      if (AppConfig.hasSupabaseConfig && AppConfig.enableCloudSync) {
        try {
          await _saveToSupabase(pdfPath, annotation);
        } catch (e) {
          _logger.warning('Failed to save to Supabase, saving locally',
              data: {'error': e.toString()});
        }
      }

      // Always save to local storage as backup
      await _saveToLocal(pdfPath, _annotationsCache[pdfPath]!);

      _logger.debug('Annotation added successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to add annotation',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add annotation',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update an existing annotation
  static Future<void> updateAnnotation(
    String pdfPath,
    PdfAnnotation annotation,
  ) async {
    try {
      _logger.info('Updating annotation',
          data: {'path': pdfPath, 'id': annotation.id});

      if (!_annotationsCache.containsKey(pdfPath)) {
        throw PDFProcessingException('No annotations loaded for this PDF');
      }

      final annotations = _annotationsCache[pdfPath]!;
      final index = annotations.indexWhere((a) => a.id == annotation.id);

      if (index == -1) {
        throw PDFProcessingException('Annotation not found');
      }

      annotations[index] = annotation;

      // Save to Supabase if configured
      if (AppConfig.hasSupabaseConfig && AppConfig.enableCloudSync) {
        try {
          await _updateInSupabase(pdfPath, annotation);
        } catch (e) {
          _logger.warning('Failed to update in Supabase',
              data: {'error': e.toString()});
        }
      }

      // Save to local storage
      await _saveToLocal(pdfPath, annotations);

      _logger.debug('Annotation updated successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to update annotation',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to update annotation',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete an annotation
  static Future<void> deleteAnnotation(
    String pdfPath,
    String annotationId,
  ) async {
    try {
      _logger.info('Deleting annotation',
          data: {'path': pdfPath, 'id': annotationId});

      if (!_annotationsCache.containsKey(pdfPath)) {
        throw PDFProcessingException('No annotations loaded for this PDF');
      }

      final annotations = _annotationsCache[pdfPath]!;
      annotations.removeWhere((a) => a.id == annotationId);

      // Delete from Supabase if configured
      if (AppConfig.hasSupabaseConfig && AppConfig.enableCloudSync) {
        try {
          await _deleteFromSupabase(annotationId);
        } catch (e) {
          _logger.warning('Failed to delete from Supabase',
              data: {'error': e.toString()});
        }
      }

      // Save to local storage
      await _saveToLocal(pdfPath, annotations);

      _logger.debug('Annotation deleted successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete annotation',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to delete annotation',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get annotations for a specific page
  static List<PdfAnnotation> getPageAnnotations(
    String pdfPath,
    int pageNumber,
  ) {
    if (!_annotationsCache.containsKey(pdfPath)) {
      return [];
    }

    return _annotationsCache[pdfPath]!
        .where((a) => a.pageNumber == pageNumber)
        .toList();
  }

  /// Clear all annotations for a PDF
  static Future<void> clearAnnotations(String pdfPath) async {
    try {
      _logger.info('Clearing all annotations', data: {'path': pdfPath});

      _annotationsCache.remove(pdfPath);

      // Clear from Supabase if configured
      if (AppConfig.hasSupabaseConfig && AppConfig.enableCloudSync) {
        try {
          await _clearFromSupabase(pdfPath);
        } catch (e) {
          _logger.warning('Failed to clear from Supabase',
              data: {'error': e.toString()});
        }
      }

      // Clear local storage
      final file = await _getLocalAnnotationsFile(pdfPath);
      if (await file.exists()) {
        await file.delete();
      }

      _logger.debug('Annotations cleared successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to clear annotations',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Export annotations to JSON
  static Future<String> exportAnnotations(String pdfPath) async {
    try {
      final annotations = await getAnnotations(pdfPath);
      final json = {
        'pdfPath': pdfPath,
        'exportedAt': DateTime.now().toIso8601String(),
        'annotations': annotations.map((a) => a.toJson()).toList(),
      };
      return jsonEncode(json);
    } catch (e, stackTrace) {
      _logger.error('Failed to export annotations',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to export annotations',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Import annotations from JSON
  static Future<void> importAnnotations(
    String pdfPath,
    String jsonData,
  ) async {
    try {
      final json = jsonDecode(jsonData) as Map<String, dynamic>;
      final annotationsJson = json['annotations'] as List<dynamic>;

      final annotations = <PdfAnnotation>[];
      for (final annotationJson in annotationsJson) {
        final type = annotationJson['type'] as String;
        final annotation = _deserializeAnnotation(type, annotationJson);
        annotations.add(annotation);
      }

      _annotationsCache[pdfPath] = annotations;
      await _saveToLocal(pdfPath, annotations);

      _logger.info('Imported ${annotations.length} annotations');
    } catch (e, stackTrace) {
      _logger.error('Failed to import annotations',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to import annotations',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Private Methods
  // ======================

  /// Load annotations from local storage
  static Future<List<PdfAnnotation>> _loadFromLocal(String pdfPath) async {
    try {
      final file = await _getLocalAnnotationsFile(pdfPath);

      if (!await file.exists()) {
        _logger.debug('No local annotations file found');
        return [];
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final annotationsJson = json['annotations'] as List<dynamic>;

      final annotations = <PdfAnnotation>[];
      for (final annotationJson in annotationsJson) {
        final type = annotationJson['type'] as String;
        final annotation = _deserializeAnnotation(type, annotationJson);
        annotations.add(annotation);
      }

      _logger.debug('Loaded ${annotations.length} annotations from local');
      return annotations;
    } catch (e, stackTrace) {
      _logger.error('Failed to load from local',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Save annotations to local storage
  static Future<void> _saveToLocal(
    String pdfPath,
    List<PdfAnnotation> annotations,
  ) async {
    try {
      final file = await _getLocalAnnotationsFile(pdfPath);
      final json = {
        'pdfPath': pdfPath,
        'savedAt': DateTime.now().toIso8601String(),
        'annotations': annotations.map((a) => a.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(json));
      _logger.debug('Saved ${annotations.length} annotations to local');
    } catch (e, stackTrace) {
      _logger.error('Failed to save to local',
          error: e, stackTrace: stackTrace);
      throw FileOperationException(
        'Failed to save annotations locally',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get local annotations file
  static Future<File> _getLocalAnnotationsFile(String pdfPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final annotationsDir = Directory('${directory.path}/annotations');

    if (!await annotationsDir.exists()) {
      await annotationsDir.create(recursive: true);
    }

    // Create filename from PDF path
    final fileName =
        '${pdfPath.hashCode.abs()}_annotations.json';
    return File('${annotationsDir.path}/$fileName');
  }

  /// Load annotations from Supabase
  static Future<List<PdfAnnotation>> _loadFromSupabase(String pdfPath) async {
    final results = await _supabase.query(
      table: 'pdf_annotations',
      filters: {'pdf_path': pdfPath},
    );

    final annotations = <PdfAnnotation>[];
    for (final result in results) {
      final type = result['type'] as String;
      final data = result['data'] as Map<String, dynamic>;
      final annotation = _deserializeAnnotation(type, data);
      annotations.add(annotation);
    }

    _logger.debug('Loaded ${annotations.length} annotations from Supabase');
    return annotations;
  }

  /// Save annotation to Supabase
  static Future<void> _saveToSupabase(
    String pdfPath,
    PdfAnnotation annotation,
  ) async {
    await _supabase.insert(
      table: 'pdf_annotations',
      data: {
        'id': annotation.id,
        'pdf_path': pdfPath,
        'type': annotation.type,
        'page_number': annotation.pageNumber,
        'data': annotation.toJson(),
        'created_at': annotation.createdAt.toIso8601String(),
      },
    );
  }

  /// Update annotation in Supabase
  static Future<void> _updateInSupabase(
    String pdfPath,
    PdfAnnotation annotation,
  ) async {
    await _supabase.update(
      table: 'pdf_annotations',
      id: annotation.id,
      data: {
        'data': annotation.toJson(),
        'modified_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Delete annotation from Supabase
  static Future<void> _deleteFromSupabase(String annotationId) async {
    await _supabase.delete(
      table: 'pdf_annotations',
      id: annotationId,
    );
  }

  /// Clear all annotations from Supabase
  static Future<void> _clearFromSupabase(String pdfPath) async {
    // This would require a custom RPC or multiple deletes
    _logger.warning('Clear from Supabase not fully implemented');
  }

  /// Deserialize annotation based on type
  static PdfAnnotation _deserializeAnnotation(
    String type,
    Map<String, dynamic> json,
  ) {
    switch (type) {
      case 'highlight':
        return HighlightAnnotation.fromJson(json);
      case 'comment':
        return CommentAnnotation.fromJson(json);
      case 'drawing':
        return DrawingAnnotation.fromJson(json);
      case 'text':
        return TextAnnotation.fromJson(json);
      case 'shape':
        return ShapeAnnotation.fromJson(json);
      case 'redaction':
        return RedactionAnnotation.fromJson(json);
      default:
        throw PDFProcessingException('Unknown annotation type: $type');
    }
  }
}
