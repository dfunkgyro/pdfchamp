import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../logging/app_logger.dart';
import '../../exceptions/app_exceptions.dart';
import '../../../models/pdf_annotation.dart';
import 'annotation_service.dart';

/// Comprehensive PDF Editor Service
/// Handles all PDF editing operations including page manipulation,
/// content editing, export, and advanced features
class PdfEditorService {
  static final AppLogger _logger = AppLogger('PdfEditorService');

  // ======================
  // Page Management
  // ======================

  /// Add a blank page to PDF
  static Future<String> addBlankPage(
    String pdfPath, {
    int? atIndex,
    PdfPageSize pageSize = PdfPageSize.a4,
  }) async {
    try {
      _logger.info('Adding blank page to PDF', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Add page at index or at end
      final PdfPage newPage;
      if (atIndex != null && atIndex >= 0 && atIndex <= document.pages.count) {
        newPage = document.pages.insert(atIndex, pageSize);
      } else {
        newPage = document.pages.add();
      }

      _logger.debug('Blank page added', data: {
        'index': atIndex ?? document.pages.count - 1,
        'totalPages': document.pages.count,
      });

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_with_page');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with new page');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to add blank page', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add blank page',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete page from PDF
  static Future<String> deletePage(String pdfPath, int pageIndex) async {
    try {
      _logger.info('Deleting page from PDF',
          data: {'path': pdfPath, 'page': pageIndex});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      if (document.pages.count == 1) {
        document.dispose();
        throw PDFProcessingException('Cannot delete the only page in PDF');
      }

      document.pages.removeAt(pageIndex);

      _logger.debug('Page deleted', data: {
        'remainingPages': document.pages.count,
      });

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_page_deleted');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with page deleted');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to delete page', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to delete page',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Reorder pages in PDF
  static Future<String> reorderPages(
    String pdfPath,
    List<int> newOrder,
  ) async {
    try {
      _logger.info('Reordering pages', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final sourceDoc = PdfDocument(inputBytes: bytes);

      if (newOrder.length != sourceDoc.pages.count) {
        sourceDoc.dispose();
        throw PDFProcessingException('New order must include all pages');
      }

      // Create new document with reordered pages
      final newDoc = PdfDocument();

      for (final pageIndex in newOrder) {
        if (pageIndex < 0 || pageIndex >= sourceDoc.pages.count) {
          newDoc.dispose();
          sourceDoc.dispose();
          throw PDFProcessingException('Invalid page index in new order: $pageIndex');
        }

        // Import page from source to new document
        newDoc.pages.add().graphics.drawPdfTemplate(
          sourceDoc.pages[pageIndex].createTemplate(),
        );
      }

      sourceDoc.dispose();

      _logger.debug('Pages reordered');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_reordered');
      final outputBytes = await newDoc.save();
      newDoc.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with reordered pages');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to reorder pages', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to reorder pages',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Rotate page
  static Future<String> rotatePage(
    String pdfPath,
    int pageIndex,
    PdfPageRotateAngle angle,
  ) async {
    try {
      _logger.info('Rotating page', data: {
        'path': pdfPath,
        'page': pageIndex,
        'angle': angle.toString(),
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      document.pages[pageIndex].rotation = angle;

      _logger.debug('Page rotated');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_rotated');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with rotated page');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to rotate page', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to rotate page',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract pages to new PDF
  static Future<String> extractPages(
    String pdfPath,
    List<int> pageIndices,
  ) async {
    try {
      _logger.info('Extracting pages', data: {
        'path': pdfPath,
        'pages': pageIndices,
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final sourceDoc = PdfDocument(inputBytes: bytes);

      // Create new document with selected pages
      final newDoc = PdfDocument();

      for (final pageIndex in pageIndices) {
        if (pageIndex < 0 || pageIndex >= sourceDoc.pages.count) {
          newDoc.dispose();
          sourceDoc.dispose();
          throw PDFProcessingException('Invalid page index: $pageIndex');
        }

        newDoc.pages.add().graphics.drawPdfTemplate(
          sourceDoc.pages[pageIndex].createTemplate(),
        );
      }

      sourceDoc.dispose();

      _logger.debug('Pages extracted', data: {
        'pageCount': newDoc.pages.count,
      });

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_extracted');
      final outputBytes = await newDoc.save();
      newDoc.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('Extracted pages saved');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to extract pages', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to extract pages',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Merge & Split
  // ======================

  /// Merge multiple PDFs
  static Future<String> mergePdfs(List<String> pdfPaths) async {
    try {
      _logger.info('Merging PDFs', data: {'count': pdfPaths.length});

      if (pdfPaths.isEmpty) {
        throw PDFProcessingException('No PDFs to merge');
      }

      final mergedDoc = PdfDocument();

      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (!await file.exists()) {
          _logger.warning('PDF not found, skipping', data: {'path': pdfPath});
          continue;
        }

        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);

        // Import all pages
        for (int i = 0; i < doc.pages.count; i++) {
          mergedDoc.pages.add().graphics.drawPdfTemplate(
            doc.pages[i].createTemplate(),
          );
        }

        doc.dispose();
      }

      _logger.debug('PDFs merged', data: {
        'totalPages': mergedDoc.pages.count,
      });

      // Save to new file
      final outputDir = await getTemporaryDirectory();
      final outputPath = path.join(
        outputDir.path,
        'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final outputBytes = await mergedDoc.save();
      mergedDoc.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('Merged PDF saved');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to merge PDFs', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to merge PDFs',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Split PDF into individual pages
  static Future<List<String>> splitPdf(String pdfPath) async {
    try {
      _logger.info('Splitting PDF', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final sourceDoc = PdfDocument(inputBytes: bytes);

      final outputPaths = <String>[];
      final outputDir = await getTemporaryDirectory();

      for (int i = 0; i < sourceDoc.pages.count; i++) {
        final newDoc = PdfDocument();
        newDoc.pages.add().graphics.drawPdfTemplate(
          sourceDoc.pages[i].createTemplate(),
        );

        final outputPath = path.join(
          outputDir.path,
          'page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        final outputBytes = await newDoc.save();
        newDoc.dispose();

        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(outputBytes);
        outputPaths.add(outputPath);
      }

      sourceDoc.dispose();

      _logger.info('PDF split into pages', data: {'count': outputPaths.length});
      return outputPaths;
    } catch (e, stackTrace) {
      _logger.error('Failed to split PDF', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to split PDF',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Content Editing
  // ======================

  /// Add text to PDF page
  static Future<String> addText(
    String pdfPath, {
    required int pageIndex,
    required String text,
    required Offset position,
    PdfFont? font,
    PdfBrush? brush,
    double fontSize = 14,
  }) async {
    try {
      _logger.info('Adding text to PDF', data: {
        'path': pdfPath,
        'page': pageIndex,
        'text': text.substring(0, text.length > 50 ? 50 : text.length),
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      final page = document.pages[pageIndex];
      final graphics = page.graphics;

      final textFont = font ?? PdfStandardFont(PdfFontFamily.helvetica, fontSize);
      final textBrush = brush ?? PdfSolidBrush(PdfColor(0, 0, 0));

      graphics.drawString(
        text,
        textFont,
        brush: textBrush,
        bounds: Rect.fromLTWH(position.dx, position.dy, page.size.width - position.dx, page.size.height - position.dy),
      );

      _logger.debug('Text added to page');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_with_text');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with text');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to add text', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add text',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add image to PDF page
  static Future<String> addImage(
    String pdfPath, {
    required int pageIndex,
    required Uint8List imageBytes,
    required Rect bounds,
  }) async {
    try {
      _logger.info('Adding image to PDF', data: {
        'path': pdfPath,
        'page': pageIndex,
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      final page = document.pages[pageIndex];
      final graphics = page.graphics;

      final image = PdfBitmap(imageBytes);
      graphics.drawImage(image, bounds);

      _logger.debug('Image added to page');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_with_image');
      final outputBytes = await document.save();
      document.dispose();

      _logger.info('PDF saved with image');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to add image', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add image',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add watermark to PDF
  static Future<String> addWatermark(
    String pdfPath, {
    required String watermarkText,
    double opacity = 0.3,
    double fontSize = 48,
    double rotation = 45,
    Color color = Colors.grey,
  }) async {
    try {
      _logger.info('Adding watermark to PDF', data: {
        'path': pdfPath,
        'text': watermarkText,
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
      final brush = PdfSolidBrush(
        PdfColor(color.red, color.green, color.blue, (opacity * 255).toInt()),
      );

      // Add watermark to all pages
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final graphics = page.graphics;

        // Save graphics state
        graphics.save();

        // Calculate center position
        final centerX = page.size.width / 2;
        final centerY = page.size.height / 2;

        // Rotate and draw watermark
        graphics.translateTransform(centerX, centerY);
        graphics.rotateTransform(-rotation);

        final textSize = font.measureString(watermarkText);
        graphics.drawString(
          watermarkText,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
        );

        // Restore graphics state
        graphics.restore();
      }

      _logger.debug('Watermark added to all pages');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_watermarked');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with watermark');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to add watermark', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add watermark',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Export Functions
  // ======================

  /// Export PDF page as image (PNG, JPEG)
  static Future<String> exportPageAsImage(
    String pdfPath,
    int pageIndex, {
    ImageFormat format = ImageFormat.png,
    double scale = 2.0,
  }) async {
    try {
      _logger.info('Exporting page as image', data: {
        'path': pdfPath,
        'page': pageIndex,
        'format': format.toString(),
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      final page = document.pages[pageIndex];
      final imageData = await page.toImage(dpi: 300 * scale);
      final image = await imageData.toByteData(
        format: format == ImageFormat.png
            ? ui.ImageByteFormat.png
            : ui.ImageByteFormat.rawRgba,
      );

      document.dispose();

      if (image == null) {
        throw PDFProcessingException('Failed to convert page to image');
      }

      // Save image file
      final outputDir = await getTemporaryDirectory();
      final extension = format == ImageFormat.png ? 'png' : 'jpg';
      final outputPath = path.join(
        outputDir.path,
        'page_${pageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(image.buffer.asUint8List());

      _logger.info('Page exported as image');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to export page as image', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to export page as image',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Export all pages as images
  static Future<List<String>> exportAllPagesAsImages(
    String pdfPath, {
    ImageFormat format = ImageFormat.png,
    double scale = 2.0,
  }) async {
    try {
      _logger.info('Exporting all pages as images', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final outputPaths = <String>[];

      for (int i = 0; i < document.pages.count; i++) {
        final imagePath = await exportPageAsImage(pdfPath, i, format: format, scale: scale);
        outputPaths.add(imagePath);
      }

      document.dispose();

      _logger.info('All pages exported', data: {'count': outputPaths.length});
      return outputPaths;
    } catch (e, stackTrace) {
      _logger.error('Failed to export all pages', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to export all pages as images',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // PDF Metadata & Properties
  // ======================

  /// Get PDF metadata
  static Future<PdfMetadata> getMetadata(String pdfPath) async {
    try {
      _logger.info('Getting PDF metadata', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final metadata = PdfMetadata(
        title: document.documentInformation.title,
        author: document.documentInformation.author,
        subject: document.documentInformation.subject,
        keywords: document.documentInformation.keywords,
        creator: document.documentInformation.creator,
        producer: document.documentInformation.producer,
        creationDate: document.documentInformation.creationDate,
        modificationDate: document.documentInformation.modificationDate,
        pageCount: document.pages.count,
        fileSize: bytes.length,
        hasAttachments: document.attachments.count > 0,
        hasBookmarks: document.bookmarks.count > 0,
        hasForm: document.form != null,
      );

      document.dispose();

      _logger.debug('Metadata retrieved');
      return metadata;
    } catch (e, stackTrace) {
      _logger.error('Failed to get metadata', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to get PDF metadata',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update PDF metadata
  static Future<String> updateMetadata(
    String pdfPath, {
    String? title,
    String? author,
    String? subject,
    String? keywords,
  }) async {
    try {
      _logger.info('Updating PDF metadata', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (title != null) document.documentInformation.title = title;
      if (author != null) document.documentInformation.author = author;
      if (subject != null) document.documentInformation.subject = subject;
      if (keywords != null) document.documentInformation.keywords = keywords;
      document.documentInformation.modificationDate = DateTime.now();

      _logger.debug('Metadata updated');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_metadata_updated');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with updated metadata');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to update metadata', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to update PDF metadata',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Bookmarks & Links
  // ======================

  /// Get all bookmarks from PDF
  static Future<List<PdfBookmarkInfo>> getBookmarks(String pdfPath) async {
    try {
      _logger.info('Getting PDF bookmarks', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final bookmarks = <PdfBookmarkInfo>[];

      for (int i = 0; i < document.bookmarks.count; i++) {
        final bookmark = document.bookmarks[i];
        bookmarks.add(PdfBookmarkInfo(
          title: bookmark.title,
          pageIndex: bookmark.destination?.page.pageIndex ?? -1,
          color: bookmark.color,
        ));
      }

      document.dispose();

      _logger.info('Bookmarks retrieved', data: {'count': bookmarks.length});
      return bookmarks;
    } catch (e, stackTrace) {
      _logger.error('Failed to get bookmarks', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to get PDF bookmarks',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add bookmark to PDF
  static Future<String> addBookmark(
    String pdfPath, {
    required String title,
    required int pageIndex,
    Color color = Colors.black,
  }) async {
    try {
      _logger.info('Adding bookmark', data: {
        'path': pdfPath,
        'title': title,
        'page': pageIndex,
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        throw PDFProcessingException('Invalid page index: $pageIndex');
      }

      final bookmark = document.bookmarks.add(title);
      bookmark.destination = PdfDestination(document.pages[pageIndex]);
      bookmark.color = PdfColor(color.red, color.green, color.blue);

      _logger.debug('Bookmark added');

      // Save to new file
      final outputPath = await _getOutputPath(pdfPath, '_with_bookmark');
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('PDF saved with bookmark');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to add bookmark', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to add bookmark',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Attachments
  // ======================

  /// Get all attachments from PDF
  static Future<List<PdfAttachmentInfo>> getAttachments(String pdfPath) async {
    try {
      _logger.info('Getting PDF attachments', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final attachments = <PdfAttachmentInfo>[];

      for (int i = 0; i < document.attachments.count; i++) {
        final attachment = document.attachments[i];
        attachments.add(PdfAttachmentInfo(
          fileName: attachment.fileName,
          description: attachment.description ?? '',
          mimeType: attachment.mimeType,
          creationDate: attachment.creationDate,
          modificationDate: attachment.modificationDate,
        ));
      }

      document.dispose();

      _logger.info('Attachments retrieved', data: {'count': attachments.length});
      return attachments;
    } catch (e, stackTrace) {
      _logger.error('Failed to get attachments', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to get PDF attachments',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract attachment from PDF
  static Future<String> extractAttachment(
    String pdfPath,
    int attachmentIndex,
  ) async {
    try {
      _logger.info('Extracting attachment', data: {
        'path': pdfPath,
        'index': attachmentIndex,
      });

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (attachmentIndex < 0 || attachmentIndex >= document.attachments.count) {
        document.dispose();
        throw PDFProcessingException('Invalid attachment index: $attachmentIndex');
      }

      final attachment = document.attachments[attachmentIndex];
      final attachmentData = attachment.data;

      // Save attachment
      final outputDir = await getTemporaryDirectory();
      final outputPath = path.join(outputDir.path, attachment.fileName);

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(attachmentData);

      document.dispose();

      _logger.info('Attachment extracted');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to extract attachment', error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to extract attachment',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ======================
  // Helper Methods
  // ======================

  /// Get output path for edited PDF
  static Future<String> _getOutputPath(String originalPath, String suffix) async {
    final outputDir = await getTemporaryDirectory();
    final originalFile = File(originalPath);
    final baseName = path.basenameWithoutExtension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(outputDir.path, '${baseName}${suffix}_$timestamp.pdf');
  }
}

/// PDF Metadata model
class PdfMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;
  final String? producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int pageCount;
  final int fileSize;
  final bool hasAttachments;
  final bool hasBookmarks;
  final bool hasForm;

  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    required this.pageCount,
    required this.fileSize,
    required this.hasAttachments,
    required this.hasBookmarks,
    required this.hasForm,
  });

  @override
  String toString() {
    return 'PdfMetadata(title: $title, author: $author, pages: $pageCount, size: $fileSize bytes)';
  }
}

/// PDF Bookmark Info
class PdfBookmarkInfo {
  final String title;
  final int pageIndex;
  final PdfColor color;

  const PdfBookmarkInfo({
    required this.title,
    required this.pageIndex,
    required this.color,
  });
}

/// PDF Attachment Info
class PdfAttachmentInfo {
  final String fileName;
  final String description;
  final String mimeType;
  final DateTime? creationDate;
  final DateTime? modificationDate;

  const PdfAttachmentInfo({
    required this.fileName,
    required this.description,
    required this.mimeType,
    this.creationDate,
    this.modificationDate,
  });
}

/// Image export format
enum ImageFormat {
  png,
  jpeg,
}
