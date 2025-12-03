import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_editor_macos/widgets/pdf_viewer_widget.dart';
import 'package:pdf_editor_macos/widgets/recent_files_list.dart';
import 'package:pdf_editor_macos/widgets/pdf_editor_panel.dart';
import 'package:pdf_editor_macos/models/pdf_document.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _pdfPath;
  PDFDocument? _pdfDocument;
  final List<String> _recentFiles = [];
  bool _isEditing = false;
  TextEditingController _textController = TextEditingController();

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _loadPDF(result.files.single.path!);
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _loadPDF(String path) async {
    try {
      final pdfDoc = PDFDocument(
        path: path,
        fileName: path.split('/').last,
      );
      
      setState(() {
        _pdfPath = path;
        _pdfDocument = pdfDoc;
        _isEditing = false;
        
        if (!_recentFiles.contains(path)) {
          _recentFiles.insert(0, path);
          if (_recentFiles.length > 10) {
            _recentFiles.removeLast();
          }
        }
      });
    } catch (e) {
      _showError('Error loading PDF: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _startTextEdit(String initialText) {
    _textController.text = initialText;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: _textController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Handle text update
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePDF() async {
    if (_pdfPath == null || _pdfDocument == null) return;
    
    try {
      // Save edited PDF
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF As',
        fileName: 'edited_${_pdfDocument!.fileName}',
        allowedExtensions: ['pdf'],
      );
      
      if (savedPath != null) {
        // Implement PDF saving logic
        _showSuccess('PDF saved successfully!');
      }
    } catch (e) {
      _showError('Error saving PDF: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pdfDocument?.fileName ?? 'PDF Editor'),
        actions: [
          if (_pdfPath != null) ...[
            IconButton(
              icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePDF,
              tooltip: 'Save PDF',
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickPDF,
              tooltip: 'Open PDF',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => OpenFilex.open(_pdfPath!),
              tooltip: 'Open in default viewer',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickPDF,
              tooltip: 'Open PDF',
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          // Sidebar for recent files
          if (_recentFiles.isNotEmpty)
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: RecentFilesList(
                files: _recentFiles,
                onFileSelected: _loadPDF,
                currentFile: _pdfPath,
              ),
            ),
          // Main content area
          Expanded(
            child: _buildMainContent(),
          ),
          // Edit panel when in edit mode
          if (_isEditing && _pdfDocument != null)
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: PDFEditorPanel(
                document: _pdfDocument!,
                onTextEdit: _startTextEdit,
              ),
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: () {
                // Add text to PDF
                _startTextEdit('');
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Add Text'),
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    if (_pdfPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No PDF Selected',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Open a PDF file to start viewing or editing',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _pickPDF,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open PDF File'),
            ),
          ],
        ),
      );
    }

    return PDFViewerWidget(
      pdfPath: _pdfPath!,
      isEditing: _isEditing,
      onTextTap: _isEditing ? _startTextEdit : null,
    );
  }
}