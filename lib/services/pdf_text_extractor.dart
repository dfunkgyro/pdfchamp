// lib/services/pdf_text_extractor.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_editor_macos/models/pdf_font.dart';
import '../core/logging/app_logger.dart';
import '../core/error/error_codes.dart';
import '../core/exceptions/app_exceptions.dart';

class PDFTextExtractor {
  static final AppLogger _logger = AppLogger('PDFTextExtractor');
  final PDFDoc _pdfDoc;

  PDFTextExtractor(this._pdfDoc);

  Future<List<TextBlock>> extractTextWithStyles() async {
    final List<TextBlock> textBlocks = [];

    try {
      _logger.info('Starting text extraction', data: {'pages': _pdfDoc.length});

      for (int pageNum = 0; pageNum < _pdfDoc.length; pageNum++) {
        final page = _pdfDoc.page(pageNum);
        final text = await page.text;

        // Extract text with positions
        final words = await page.words;
        _logger.debug('Extracted words from page ${pageNum + 1}', data: {'wordCount': words.length});

        for (final word in words) {
          final block = TextBlock(
            text: word.text,
            page: pageNum + 1,
            bounds: Rect.fromLTRB(
              word.xStart,
              word.yStart,
              word.xEnd,
              word.yEnd,
            ),
            // Extract font information if available
            font: await _extractFontInfo(page, word),
          );
          textBlocks.add(block);
        }
      }

      _logger.info('Text extraction completed', data: {'totalBlocks': textBlocks.length});
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to extract text from PDF',
        error: e,
        stackTrace: stackTrace,
      );
      throw PDFProcessingException(
        message: 'Failed to extract text from PDF',
        code: ErrorCode.pdfTextExtractionError.code,
        operation: 'extractTextWithStyles',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    return textBlocks;
  }

  Future<PDFFont?> _extractFontInfo(PDFPage page, PDFWord word) async {
    try {
      // This is simplified - actual font extraction is complex
      // You might need to use a more advanced PDF library

      return PDFFont(
        name: 'Extracted',
        family: 'Unknown',
        size: word.fontSize ?? 12,
        color: PdfColor(0, 0, 0),
      );
    } catch (e, stackTrace) {
      _logger.debug(
        'Failed to extract font info for word',
        data: {'word': word.text, 'error': e.toString()},
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeDocumentFonts() async {
    final fontMap = <String, Map<String, dynamic>>{};

    try {
      _logger.info('Starting font analysis', data: {'pages': _pdfDoc.length});

      for (int i = 0; i < _pdfDoc.length; i++) {
        final page = _pdfDoc.page(i);
        final fonts = await page.fonts;

        for (final font in fonts) {
          final fontName = font.name;
          if (!fontMap.containsKey(fontName)) {
            fontMap[fontName] = {
              'name': fontName,
              'type': font.type,
              'isEmbedded': font.isEmbedded,
              'encoding': font.encoding,
              'pages': [i + 1],
            };
            _logger.debug('Discovered font', data: {
              'name': fontName,
              'isEmbedded': font.isEmbedded,
            });
          } else {
            final pages = fontMap[fontName]!['pages'] as List<int>;
            if (!pages.contains(i + 1)) {
              pages.add(i + 1);
            }
          }
        }
      }

      _logger.info('Font analysis completed', data: {
        'totalFonts': fontMap.length,
        'embeddedFonts': fontMap.values.where((f) => f['isEmbedded'] == true).length,
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to analyze document fonts',
        error: e,
        stackTrace: stackTrace,
      );
      throw PDFProcessingException(
        message: 'Failed to analyze document fonts',
        code: ErrorCode.fontExtractionError.code,
        operation: 'analyzeDocumentFonts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    return {
      'fonts': fontMap,
      'totalFonts': fontMap.length,
      'hasEmbeddedFonts': fontMap.values.any((f) => f['isEmbedded'] == true),
    };
  }
}

class TextBlock {
  final String text;
  final int page;
  final Rect bounds;
  final PDFFont? font;

  TextBlock({
    required this.text,
    required this.page,
    required this.bounds,
    this.font,
  });
}