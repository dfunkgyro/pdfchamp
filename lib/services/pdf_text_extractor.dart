// lib/services/pdf_text_extractor.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_text/pdf_text.dart';
import 'package:pdf_editor_macos/models/pdf_font.dart';

class PDFTextExtractor {
  final PDFDoc _pdfDoc;

  PDFTextExtractor(this._pdfDoc);

  Future<List<TextBlock>> extractTextWithStyles() async {
    final List<TextBlock> textBlocks = [];
    
    try {
      for (int pageNum = 0; pageNum < _pdfDoc.length; pageNum++) {
        final page = _pdfDoc.page(pageNum);
        final text = await page.text;
        
        // Extract text with positions
        final words = await page.words;
        
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
    } catch (e) {
      print('Error extracting text: $e');
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
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> analyzeDocumentFonts() async {
    final fontMap = <String, Map<String, dynamic>>{};
    
    try {
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
          } else {
            final pages = fontMap[fontName]!['pages'] as List<int>;
            if (!pages.contains(i + 1)) {
              pages.add(i + 1);
            }
          }
        }
      }
    } catch (e) {
      print('Error analyzing fonts: $e');
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