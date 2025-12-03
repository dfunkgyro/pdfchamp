import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerWidget extends StatefulWidget {
  final String pdfPath;
  final bool isEditing;
  final Function(String)? onTextTap;

  const PDFViewerWidget({
    super.key,
    required this.pdfPath,
    this.isEditing = false,
    this.onTextTap,
  });

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final List<TextAnnotation> _annotations = [];
  TextAnnotation? _selectedAnnotation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF Viewer
        SfPdfViewer.file(
          File(widget.pdfPath),
          controller: _pdfViewerController,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          interactionMode: widget.isEditing 
              ? PdfInteractionMode.selection
              : PdfInteractionMode.pan,
          enableTextSelection: widget.isEditing,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          onTextSelectionChanged: widget.isEditing ? _onTextSelected : null,
        ),
        
        // Editing overlay when in edit mode
        if (widget.isEditing)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onTextSelected(PdfTextSelectionChangedDetails details) {
    if (details.selectedText == null) return;
    
    if (widget.onTextTap != null) {
      widget.onTextTap!(details.selectedText!);
    }
    
    // Show text selection menu
    _showTextSelectionMenu(details);
  }

  void _showTextSelectionMenu(PdfTextSelectionChangedDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalSelectedRegion!.center.dx,
        details.globalSelectedRegion!.center.dy,
        details.globalSelectedRegion!.center.dx,
        details.globalSelectedRegion!.center.dy,
      ),
      items: [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Text'),
          ),
          onTap: () {
            if (widget.onTextTap != null) {
              widget.onTextTap!(details.selectedText!);
            }
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.format_color_text),
            title: Text('Change Format'),
          ),
          onTap: () => _showFormatDialog(details),
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.highlight),
            title: Text('Highlight'),
          ),
          onTap: () => _addHighlight(details),
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.comment),
            title: Text('Add Comment'),
          ),
          onTap: () => _addComment(details),
        ),
      ],
    );
  }

  void _showFormatDialog(PdfTextSelectionChangedDetails details) {
    // Show formatting options dialog
  }

  void _addHighlight(PdfTextSelectionChangedDetails details) {
    // Add highlight annotation
    final annotation = TextAnnotation(
      text: details.selectedText!,
      bounds: details.globalSelectedRegion!,
      type: AnnotationType.highlight,
    );
    _annotations.add(annotation);
    setState(() {});
  }

  void _addComment(PdfTextSelectionChangedDetails details) {
    showDialog(
      context: context,
      builder: (context) => CommentDialog(
        onSave: (comment) {
          final annotation = TextAnnotation(
            text: details.selectedText!,
            bounds: details.globalSelectedRegion!,
            type: AnnotationType.comment,
            comment: comment,
          );
          _annotations.add(annotation);
          setState(() {});
        },
      ),
    );
  }
}

class TextAnnotation {
  final String text;
  final Rect bounds;
  final AnnotationType type;
  final String? comment;
  final Color color;

  TextAnnotation({
    required this.text,
    required this.bounds,
    required this.type,
    this.comment,
    this.color = Colors.yellow,
  });
}

enum AnnotationType {
  highlight,
  underline,
  strikeThrough,
  comment,
}

class CommentDialog extends StatefulWidget {
  final Function(String) onSave;

  const CommentDialog({super.key, required this.onSave});

  @override
  State<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Comment'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter your comment...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}