import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../core/theme/app_theme_constants.dart';
import '../core/logging/app_logger.dart';

/// Professional PDF viewer with advanced features
class PdfViewerWidget extends StatefulWidget {
  final String pdfPath;
  final bool isEditing;
  final Function(String)? onTextTap;
  final Function(int)? onPageChanged;

  const PdfViewerWidget({
    super.key,
    required this.pdfPath,
    this.isEditing = false,
    this.onTextTap,
    this.onPageChanged,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  static final AppLogger _logger = AppLogger('PdfViewerWidget');

  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  double _zoomLevel = 1.0;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _logger.info('Initializing PDF viewer', data: {'path': widget.pdfPath});
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // PDF Viewer
        SfPdfViewer.file(
          widget.pdfPath,
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          onDocumentLoaded: _onDocumentLoaded,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          onPageChanged: _onPageChanged,
          onTextSelectionChanged: _onTextSelectionChanged,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          interactionMode: widget.isEditing
              ? PdfInteractionMode.selection
              : PdfInteractionMode.pan,
        ),

        // Zoom Controls
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: _buildZoomControls(theme),
        ),

        // Page Navigation
        if (_totalPages > 1)
          Positioned(
            left: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _buildPageNavigation(theme),
          ),

        // Loading Overlay
        if (_isLoading)
          Container(
            color: theme.colorScheme.background.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading PDF...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZoomControls(ThemeData theme) {
    return Card(
      elevation: AppElevation.md,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Zoom In',
            onPressed: _zoomIn,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: AppTypography.monoFont,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Zoom Out',
            onPressed: _zoomOut,
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit to Width',
            onPressed: _fitToWidth,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Fit to Page',
            onPressed: _fitToPage,
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavigation(ThemeData theme) {
    return Card(
      elevation: AppElevation.md,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'First Page',
              onPressed: _currentPage > 1 ? _goToFirstPage : null,
            ),
            IconButton(
              icon: const Icon(Icons.navigate_before),
              tooltip: 'Previous Page',
              onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: AppTypography.monoFont,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              tooltip: 'Next Page',
              onPressed: _currentPage < _totalPages ? _goToNextPage : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Last Page',
              onPressed: _currentPage < _totalPages ? _goToLastPage : null,
            ),
          ],
        ),
      ),
    );
  }

  // Event Handlers
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });
    _logger.info('PDF loaded successfully', data: {'pages': _totalPages});
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() => _isLoading = false);
    _logger.error('PDF load failed', error: details.error, data: {
      'description': details.description,
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
    widget.onPageChanged?.call(_currentPage);
    _logger.debug('Page changed', data: {'page': _currentPage});
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (details.selectedText != null && details.selectedText!.isNotEmpty) {
      _logger.debug('Text selected', data: {'length': details.selectedText!.length});
      widget.onTextTap?.call(details.selectedText!);
    }
  }

  // Zoom Controls
  void _zoomIn() {
    if (_zoomLevel < 3.0) {
      setState(() {
        _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
        _pdfViewerController.zoomLevel = _zoomLevel;
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 0.5) {
      setState(() {
        _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
        _pdfViewerController.zoomLevel = _zoomLevel;
      });
    }
  }

  void _fitToWidth() {
    _pdfViewerController.zoomLevel = 1.0;
    setState(() => _zoomLevel = 1.0);
  }

  void _fitToPage() {
    _pdfViewerController.zoomLevel = 1.0;
    setState(() => _zoomLevel = 1.0);
  }

  // Page Navigation
  void _goToFirstPage() {
    _pdfViewerController.jumpToPage(1);
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _goToLastPage() {
    _pdfViewerController.jumpToPage(_totalPages);
  }

  // Public Methods
  void searchText(String text) {
    _pdfViewerController.searchText(text);
  }

  void clearTextSelection() {
    _pdfViewerController.clearSelection();
  }

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  double get zoomLevel => _zoomLevel;
}
