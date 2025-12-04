import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme_constants.dart';
import '../../core/logging/app_logger.dart';

/// Widget for displaying PDF page thumbnails for quick navigation
class PageThumbnailsWidget extends StatefulWidget {
  final String pdfPath;
  final int? currentPage;
  final Function(int)? onPageSelected;
  final bool isVertical;
  final double thumbnailWidth;
  final double thumbnailHeight;

  const PageThumbnailsWidget({
    super.key,
    required this.pdfPath,
    this.currentPage,
    this.onPageSelected,
    this.isVertical = true,
    this.thumbnailWidth = 120,
    this.thumbnailHeight = 160,
  });

  @override
  State<PageThumbnailsWidget> createState() => _PageThumbnailsWidgetState();
}

class _PageThumbnailsWidgetState extends State<PageThumbnailsWidget> {
  final AppLogger _logger = AppLogger('PageThumbnailsWidget');

  int _pageCount = 0;
  bool _isLoading = true;
  final Map<int, ui.Image?> _thumbnailCache = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPageCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _thumbnailCache.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(PageThumbnailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfPath != widget.pdfPath) {
      _thumbnailCache.clear();
      _loadPageCount();
    }
    if (oldWidget.currentPage != widget.currentPage && widget.currentPage != null) {
      _scrollToCurrentPage();
    }
  }

  Future<void> _loadPageCount() async {
    try {
      setState(() => _isLoading = true);

      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        _logger.error('PDF file not found: ${widget.pdfPath}');
        return;
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      setState(() {
        _pageCount = document.pages.count;
        _isLoading = false;
      });

      document.dispose();

      _logger.info('Loaded PDF with $_pageCount pages');

      // Pre-load visible thumbnails
      _preloadThumbnails();
    } catch (e, stackTrace) {
      _logger.error('Failed to load page count', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<ui.Image?> _loadThumbnail(int pageIndex) async {
    // Check cache first
    if (_thumbnailCache.containsKey(pageIndex)) {
      return _thumbnailCache[pageIndex];
    }

    try {
      final file = File(widget.pdfPath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        return null;
      }

      final page = document.pages[pageIndex];

      // Render page to image at lower resolution for thumbnails
      final image = await page.toImage(dpi: 72); // Lower DPI for thumbnails

      document.dispose();

      // Cache the thumbnail
      _thumbnailCache[pageIndex] = image;

      return image;
    } catch (e) {
      _logger.error('Failed to load thumbnail for page $pageIndex', error: e);
      return null;
    }
  }

  void _preloadThumbnails() {
    // Preload first few pages
    for (int i = 0; i < (_pageCount < 5 ? _pageCount : 5); i++) {
      _loadThumbnail(i);
    }
  }

  void _scrollToCurrentPage() {
    if (widget.currentPage == null || widget.currentPage! < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemExtent = widget.isVertical
            ? widget.thumbnailHeight + AppSpacing.md
            : widget.thumbnailWidth + AppSpacing.md;
        final offset = widget.currentPage! * itemExtent;

        _scrollController.animateTo(
          offset,
          duration: AppDurations.normal,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Loading pages...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (_pageCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No pages found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: widget.isVertical
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).dividerColor),
          top: widget.isVertical
              ? BorderSide(color: Theme.of(context).dividerColor)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Pages ($_pageCount)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, size: 16),
                  iconSize: 16,
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                  onPressed: () {
                    _thumbnailCache.clear();
                    _loadPageCount();
                  },
                  tooltip: 'Refresh thumbnails',
                ),
              ],
            ),
          ),

          // Thumbnails List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(AppSpacing.sm),
              scrollDirection: widget.isVertical ? Axis.vertical : Axis.horizontal,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                return _buildThumbnailItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailItem(int pageIndex) {
    final isCurrentPage = widget.currentPage == pageIndex;

    return GestureDetector(
      onTap: () => widget.onPageSelected?.call(pageIndex),
      child: Container(
        width: widget.isVertical ? null : widget.thumbnailWidth,
        height: widget.isVertical ? widget.thumbnailHeight : null,
        margin: EdgeInsets.only(
          bottom: widget.isVertical ? AppSpacing.sm : 0,
          right: widget.isVertical ? 0 : AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            Container(
              width: widget.thumbnailWidth,
              height: widget.thumbnailHeight - 32, // Reserve space for page number
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isCurrentPage
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                  width: isCurrentPage ? 2 : 1,
                ),
                boxShadow: isCurrentPage
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                child: FutureBuilder<ui.Image?>(
                  future: _loadThumbnail(pageIndex),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      );
                    }

                    return RawImage(
                      image: snapshot.data,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: AppSpacing.xs),

            // Page number
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isCurrentPage
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                '${pageIndex + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isCurrentPage
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isCurrentPage
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for bottom navigation
class CompactPageThumbnailsWidget extends StatelessWidget {
  final String pdfPath;
  final int? currentPage;
  final int totalPages;
  final Function(int)? onPageSelected;

  const CompactPageThumbnailsWidget({
    super.key,
    required this.pdfPath,
    this.currentPage,
    required this.totalPages,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: PageThumbnailsWidget(
        pdfPath: pdfPath,
        currentPage: currentPage,
        onPageSelected: onPageSelected,
        isVertical: false,
        thumbnailWidth: 60,
        thumbnailHeight: 80,
      ),
    );
  }
}
