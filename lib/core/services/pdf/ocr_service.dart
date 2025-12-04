import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../logging/app_logger.dart';
import '../../exceptions/app_exceptions.dart';

/// Service for OCR (Optical Character Recognition) on PDF pages
class OCRService {
  static final AppLogger _logger = AppLogger('OCRService');
  static final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// OCR cache to avoid re-processing
  static final Map<String, Map<int, String>> _ocrCache = {};

  /// Extract text from a PDF page using OCR
  static Future<String> extractTextFromPage(
    String pdfPath,
    int pageIndex,
  ) async {
    try {
      _logger.info('Extracting text from page using OCR',
          data: {'path': pdfPath, 'page': pageIndex});

      // Check cache first
      final cacheKey = '$pdfPath:$pageIndex';
      if (_ocrCache.containsKey(pdfPath) &&
          _ocrCache[pdfPath]!.containsKey(pageIndex)) {
        _logger.debug('Returning cached OCR result');
        return _ocrCache[pdfPath]![pageIndex]!;
      }

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Load PDF document
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      // Render page to image
      final page = document.pages[pageIndex];
      final imageData = await page.toImage();
      final image = await imageData.toByteData(format: ui.ImageByteFormat.png);

      document.dispose();

      if (image == null) {
        throw PDFProcessingException('Failed to render page to image');
      }

      // Save image to temp file for ML Kit
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/ocr_temp_$pageIndex.png';
      final tempFile = File(tempImagePath);
      await tempFile.writeAsBytes(image.buffer.asUint8List());

      // Perform OCR
      final inputImage = InputImage.fromFilePath(tempImagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Clean up temp file
      await tempFile.delete();

      final extractedText = recognizedText.text;

      // Cache result
      if (!_ocrCache.containsKey(pdfPath)) {
        _ocrCache[pdfPath] = {};
      }
      _ocrCache[pdfPath]![pageIndex] = extractedText;

      _logger.info('OCR completed',
          data: {'textLength': extractedText.length, 'blocks': recognizedText.blocks.length});

      return extractedText;
    } catch (e, stackTrace) {
      _logger.error('Failed to extract text from page',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to perform OCR on page',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract text from all pages in PDF
  static Future<String> extractTextFromAllPages(String pdfPath) async {
    try {
      _logger.info('Extracting text from all pages', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Get page count
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      final allText = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        _logger.debug('Processing page ${i + 1} of $pageCount');
        final pageText = await extractTextFromPage(pdfPath, i);
        allText.writeln('--- Page ${i + 1} ---');
        allText.writeln(pageText);
        allText.writeln();
      }

      _logger.info('OCR completed for all pages', data: {'pages': pageCount});
      return allText.toString();
    } catch (e, stackTrace) {
      _logger.error('Failed to extract text from all pages',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to perform OCR on PDF',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract structured data from page
  static Future<OCRResult> extractStructuredData(
    String pdfPath,
    int pageIndex,
  ) async {
    try {
      _logger.info('Extracting structured data from page',
          data: {'path': pdfPath, 'page': pageIndex});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Load PDF document
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      // Render page to image
      final page = document.pages[pageIndex];
      final imageData = await page.toImage();
      final image = await imageData.toByteData(format: ui.ImageByteFormat.png);

      document.dispose();

      if (image == null) {
        throw PDFProcessingException('Failed to render page to image');
      }

      // Save image to temp file
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/ocr_temp_$pageIndex.png';
      final tempFile = File(tempImagePath);
      await tempFile.writeAsBytes(image.buffer.asUint8List());

      // Perform OCR
      final inputImage = InputImage.fromFilePath(tempImagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Clean up temp file
      await tempFile.delete();

      // Extract structured data
      final blocks = <OCRBlock>[];
      for (final block in recognizedText.blocks) {
        final lines = <OCRLine>[];
        for (final line in block.lines) {
          final elements = <OCRElement>[];
          for (final element in line.elements) {
            elements.add(OCRElement(
              text: element.text,
              confidence: element.confidence,
              boundingBox: element.boundingBox,
            ));
          }
          lines.add(OCRLine(
            text: line.text,
            confidence: line.confidence,
            boundingBox: line.boundingBox,
            elements: elements,
          ));
        }
        blocks.add(OCRBlock(
          text: block.text,
          confidence: block.confidence,
          boundingBox: block.boundingBox,
          lines: lines,
        ));
      }

      final result = OCRResult(
        fullText: recognizedText.text,
        blocks: blocks,
        pageIndex: pageIndex,
      );

      _logger.info('Structured OCR completed',
          data: {'blocks': blocks.length, 'confidence': _calculateAverageConfidence(blocks)});

      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to extract structured data',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to extract structured data',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search for text in PDF using OCR
  static Future<List<OCRSearchResult>> searchText(
    String pdfPath,
    String query,
  ) async {
    try {
      _logger.info('Searching for text in PDF',
          data: {'path': pdfPath, 'query': query});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Get page count
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      final results = <OCRSearchResult>[];
      final lowerQuery = query.toLowerCase();

      for (int i = 0; i < pageCount; i++) {
        final structuredData = await extractStructuredData(pdfPath, i);

        for (final block in structuredData.blocks) {
          if (block.text.toLowerCase().contains(lowerQuery)) {
            results.add(OCRSearchResult(
              pageIndex: i,
              text: block.text,
              boundingBox: block.boundingBox,
              confidence: block.confidence,
            ));
          }
        }
      }

      _logger.info('Search completed', data: {'results': results.length});
      return results;
    } catch (e, stackTrace) {
      _logger.error('Failed to search text',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to search text in PDF',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear OCR cache
  static void clearCache([String? pdfPath]) {
    if (pdfPath != null) {
      _ocrCache.remove(pdfPath);
      _logger.debug('Cleared OCR cache for PDF');
    } else {
      _ocrCache.clear();
      _logger.debug('Cleared all OCR cache');
    }
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
    _ocrCache.clear();
    _logger.debug('OCR service disposed');
  }

  // ======================
  // Private Methods
  // ======================

  /// Calculate average confidence
  static double _calculateAverageConfidence(List<OCRBlock> blocks) {
    if (blocks.isEmpty) return 0.0;
    final total = blocks.fold<double>(
        0.0, (sum, block) => sum + (block.confidence ?? 0.0));
    return total / blocks.length;
  }
}

/// OCR Result with structured data
class OCRResult {
  final String fullText;
  final List<OCRBlock> blocks;
  final int pageIndex;

  const OCRResult({
    required this.fullText,
    required this.blocks,
    required this.pageIndex,
  });

  @override
  String toString() {
    return 'OCRResult(page: $pageIndex, blocks: ${blocks.length}, '
        'textLength: ${fullText.length})';
  }
}

/// OCR Block (paragraph)
class OCRBlock {
  final String text;
  final double? confidence;
  final Rect boundingBox;
  final List<OCRLine> lines;

  const OCRBlock({
    required this.text,
    this.confidence,
    required this.boundingBox,
    required this.lines,
  });
}

/// OCR Line
class OCRLine {
  final String text;
  final double? confidence;
  final Rect boundingBox;
  final List<OCRElement> elements;

  const OCRLine({
    required this.text,
    this.confidence,
    required this.boundingBox,
    required this.elements,
  });
}

/// OCR Element (word)
class OCRElement {
  final String text;
  final double? confidence;
  final Rect boundingBox;

  const OCRElement({
    required this.text,
    this.confidence,
    required this.boundingBox,
  });
}

/// OCR Search Result
class OCRSearchResult {
  final int pageIndex;
  final String text;
  final Rect boundingBox;
  final double? confidence;

  const OCRSearchResult({
    required this.pageIndex,
    required this.text,
    required this.boundingBox,
    this.confidence,
  });

  @override
  String toString() {
    return 'OCRSearchResult(page: $pageIndex, text: "$text", '
        'confidence: ${confidence?.toStringAsFixed(2)})';
  }
}
