// lib/services/pdf_processor.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_text/pdf_text.dart' as pdf_text;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:printing/printing.dart';

class PDFProcessor {
  // Extract text with metadata
  Future<List<TextElement>> extractTextWithMetadata(String pdfPath) async {
    final doc = await pdf_text.PDFDoc.fromPath(pdfPath);
    final List<TextElement> elements = [];
    
    for (int i = 0; i < doc.length; i++) {
      final page = doc.page(i);
      final words = await page.words;
      
      for (final word in words) {
        elements.add(TextElement(
          text: word.text,
          page: i + 1,
          bounds: PdfRect(
            word.xStart,
            word.yStart,
            word.width,
            word.height,
          ),
          fontSize: word.fontSize ?? 12,
          fontName: word.fontName ?? 'Unknown',
        ));
      }
    }
    
    return elements;
  }
  
  // Edit existing PDF
  Future<void> editPDFWithNewText({
    required String inputPath,
    required String outputPath,
    required List<TextEdit> edits,
  }) async {
    // Load existing PDF
    final sf.PdfDocument document = sf.PdfDocument(
      inputBytes: await File(inputPath).readAsBytes(),
    );
    
    // Apply edits
    for (final edit in edits) {
      final page = document.pages[edit.page - 1];
      final sf.PdfFont font = sf.PdfStandardFont(
        sf.PdfFontFamily.helvetica,
        edit.font.size,
        style: _getPdfFontStyle(edit.font),
      );
      
      final sf.PdfBrush brush = sf.PdfSolidBrush(
        sf.PdfColor(
          edit.font.color.r,
          edit.font.color.g,
          edit.font.color.b,
          (edit.font.color.a * 255).toInt(),
        ),
      );
      
      page.graphics.drawString(
        edit.text,
        font,
        brush: brush,
        bounds: sf.Rect.fromLTRB(
          edit.position.left,
          edit.position.top,
          edit.position.right,
          edit.position.bottom,
        ),
      );
    }
    
    // Save document
    final List<int> bytes = document.save();
    await File(outputPath).writeAsBytes(bytes);
    document.dispose();
  }
  
  sf.PdfFontStyle _getPdfFontStyle(PDFFont font) {
    sf.PdfFontStyle style = sf.PdfFontStyle.regular;
    
    if (font.weight == FontWeight.bold) {
      style |= sf.PdfFontStyle.bold;
    }
    if (font.style == FontStyle.italic) {
      style |= sf.PdfFontStyle.italic;
    }
    
    return style;
  }
  
  // Convert PDF to images for preview
  Future<List<Uint8List>> pdfToImages(String pdfPath, {double scale = 2.0}) async {
    return await Printing.raster(
      await File(pdfPath).readAsBytes(),
      dpi: (scale * 72).toInt(),
    );
  }
}

class TextElement {
  final String text;
  final int page;
  final PdfRect bounds;
  final double fontSize;
  final String fontName;
  
  TextElement({
    required this.text,
    required this.page,
    required this.bounds,
    required this.fontSize,
    required this.fontName,
  });
}

class TextEdit {
  final String text;
  final int page;
  final PdfRect position;
  final PDFFont font;
  
  TextEdit({
    required this.text,
    required this.page,
    required this.position,
    required this.font,
  });
}

class PdfRect {
  final double left;
  final double top;
  final double width;
  final double height;
  
  PdfRect(this.left, this.top, this.width, this.height);
  
  double get right => left + width;
  double get bottom => top + height;
}