// lib/services/font_manager.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../core/logging/app_logger.dart';
import '../core/error/error_codes.dart';
import '../core/exceptions/app_exceptions.dart';

class FontManager {
  static final AppLogger _logger = AppLogger('FontManager');
  static final FontManager _instance = FontManager._internal();
  factory FontManager() => _instance;
  FontManager._internal();

  final Map<String, Uint8List> _fontCache = {};
  final Map<String, PDFFont> _systemFonts = {};

  // Standard PDF font families
  static const List<String> standardPDFFonts = [
    'Helvetica',
    'Times-Roman',
    'Courier',
    'Symbol',
    'ZapfDingbats',
  ];

  // Font substitution map for missing fonts
  static const Map<String, String> fontSubstitution = {
    'Arial': 'Helvetica',
    'Times New Roman': 'Times-Roman',
    'Courier New': 'Courier',
    'Verdana': 'Helvetica',
    'Georgia': 'Times-Roman',
    'Comic Sans MS': 'Helvetica',
    'Trebuchet MS': 'Helvetica',
    'Impact': 'Helvetica',
    'Tahoma': 'Helvetica',
  };

  Future<void> initialize() async {
    await _loadSystemFonts();
    await _loadGoogleFonts();
  }

  Future<void> _loadSystemFonts() async {
    if (Platform.isMacOS) {
      // macOS font directories
      final fontDirectories = [
        '/System/Library/Fonts/',
        '/Library/Fonts/',
        '~/Library/Fonts/',
      ];

      for (final dir in fontDirectories) {
        await _loadFontsFromDirectory(dir);
      }
    }
  }

  Future<void> _loadFontsFromDirectory(String directory) async {
    try {
      final dir = Directory(directory.replaceFirst('~', Platform.environment['HOME']!));
      if (!await dir.exists()) return;

      final fontFiles = await dir.list().where((entity) {
        final path = entity.path.toLowerCase();
        return path.endsWith('.ttf') || 
               path.endsWith('.otf') ||
               path.endsWith('.ttc');
      }).toList();

      for (final file in fontFiles) {
        try {
          final bytes = await File(file.path).readAsBytes();
          final fontName = _extractFontName(bytes, file.path);
          if (fontName != null) {
            _fontCache[fontName] = bytes;
            _logger.debug('Loaded font: $fontName from ${file.path}');
          }
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to load font',
            data: {'path': file.path, 'error': e.toString()},
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to read font directory',
        data: {'directory': directory, 'error': e.toString()},
      );
    }
  }

  String? _extractFontName(Uint8List bytes, String path) {
    try {
      final name = path.split('/').last.split('.').first;
      return name;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadGoogleFonts() async {
    // Pre-load common Google Fonts
    final commonFonts = [
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Poppins',
      'Inter',
    ];

    _logger.info('Loading common Google Fonts');
    int loadedCount = 0;

    for (final font in commonFonts) {
      try {
        final fontLoader = GoogleFonts.getFont(font);
        await fontLoader.load();
        loadedCount++;
        _logger.debug('Loaded Google Font: $font');
      } catch (e, stackTrace) {
        _logger.warning(
          'Failed to load Google Font',
          data: {'font': font, 'error': e.toString()},
        );
      }
    }

    _logger.info('Google Fonts loaded', data: {
      'loaded': loadedCount,
      'total': commonFonts.length,
    });
  }

  Future<PDFFont?> getFontForEditing({
    required String fontName,
    FontWeight weight = FontWeight.normal,
    FontStyle style = FontStyle.normal,
  }) async {
    // Try to find the exact font
    if (_fontCache.containsKey(fontName)) {
      return PDFFont(
        name: fontName,
        family: fontName,
        weight: weight,
        style: style,
        fontData: _fontCache[fontName],
        isEmbedded: true,
      );
    }

    // Check for substituted font
    final substituted = fontSubstitution[fontName];
    if (substituted != null) {
      return PDFFont(
        name: substituted,
        family: substituted,
        weight: weight,
        style: style,
        isEmbedded: false,
      );
    }

    // Fallback to system font
    return _getSystemFallbackFont(fontName, weight, style);
  }

  PDFFont _getSystemFallbackFont(String requestedFont, FontWeight weight, FontStyle style) {
    // Check if it's a standard PDF font
    if (standardPDFFonts.contains(requestedFont)) {
      return PDFFont(
        name: requestedFont,
        family: requestedFont,
        weight: weight,
        style: style,
        isEmbedded: false,
      );
    }

    // Fallback to Helvetica (most common PDF font)
    return PDFFont(
      name: 'Helvetica',
      family: 'Helvetica',
      weight: weight,
      style: style,
      isEmbedded: false,
    );
  }

  Future<Uint8List?> loadFontFile(String fontPath) async {
    try {
      final file = File(fontPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _logger.debug('Loaded font file', data: {'path': fontPath});
        return bytes;
      } else {
        _logger.warning('Font file not found', data: {'path': fontPath});
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load font file',
        error: e,
        stackTrace: stackTrace,
        data: {'path': fontPath},
      );
    }
    return null;
  }

  List<String> getAvailableFonts() {
    final allFonts = [
      ...standardPDFFonts,
      ..._fontCache.keys,
      ...fontSubstitution.keys,
    ];
    return allFonts.toSet().toList()..sort();
  }

  Map<FontWeight, String> getFontWeights(String fontFamily) {
    return {
      FontWeight.w100: 'Thin',
      FontWeight.w200: 'ExtraLight',
      FontWeight.w300: 'Light',
      FontWeight.w400: 'Regular',
      FontWeight.w500: 'Medium',
      FontWeight.w600: 'SemiBold',
      FontWeight.w700: 'Bold',
      FontWeight.w800: 'ExtraBold',
      FontWeight.w900: 'Black',
    };
  }
}