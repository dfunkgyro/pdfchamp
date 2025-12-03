import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme_constants.dart';
import '../../core/state/app_state.dart';
import '../ai/ai_chat_widget.dart';

/// Right sidebar with AI assistant and PDF properties
class RightSidebar extends StatefulWidget {
  final String? pdfContent;
  final Map<String, dynamic>? pdfMetadata;

  const RightSidebar({
    super.key,
    this.pdfContent,
    this.pdfMetadata,
  });

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Switch to AI tab if AI assistant is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.isAiAssistantVisible) {
        _tabController.index = 0;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: AppCurves.easeInOut,
      width: appState.isRightSidebarVisible ? appState.rightSidebarWidth : 0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: appState.isRightSidebarVisible
          ? _buildSidebarContent(context, theme)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSidebarContent(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.smart_toy, size: 18),
              text: 'AI',
            ),
            Tab(
              icon: Icon(Icons.info_outline, size: 18),
              text: 'Properties',
            ),
            Tab(
              icon: Icon(Icons.history, size: 18),
              text: 'History',
            ),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primary,
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AIChatWidget(pdfContent: widget.pdfContent),
              _buildPropertiesTab(context, theme),
              _buildHistoryTab(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesTab(BuildContext context, ThemeData theme) {
    if (widget.pdfMetadata == null) {
      return _buildEmptyState(
        context,
        theme,
        Icons.description,
        'No PDF loaded',
        'Open a PDF to view its properties',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSectionHeader(theme, 'Document Information'),
        _buildPropertyCard(
          theme,
          [
            _buildPropertyItem(theme, 'File Name',
                widget.pdfMetadata!['fileName'] ?? 'Unknown'),
            _buildPropertyItem(
                theme, 'File Size', _formatFileSize(widget.pdfMetadata!['fileSize'])),
            _buildPropertyItem(theme, 'Pages',
                '${widget.pdfMetadata!['pageCount'] ?? 0}'),
            _buildPropertyItem(theme, 'Created',
                _formatDate(widget.pdfMetadata!['created'])),
            _buildPropertyItem(theme, 'Modified',
                _formatDate(widget.pdfMetadata!['modified'])),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(theme, 'Metadata'),
        _buildPropertyCard(
          theme,
          [
            _buildPropertyItem(
                theme, 'Title', widget.pdfMetadata!['title'] ?? 'N/A'),
            _buildPropertyItem(
                theme, 'Author', widget.pdfMetadata!['author'] ?? 'N/A'),
            _buildPropertyItem(
                theme, 'Subject', widget.pdfMetadata!['subject'] ?? 'N/A'),
            _buildPropertyItem(
                theme, 'Keywords', widget.pdfMetadata!['keywords'] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionHeader(theme, 'Security'),
        _buildPropertyCard(
          theme,
          [
            _buildPropertyItem(theme, 'Encrypted',
                widget.pdfMetadata!['encrypted'] == true ? 'Yes' : 'No'),
            _buildPropertyItem(theme, 'Permissions',
                widget.pdfMetadata!['permissions'] ?? 'Full access'),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, ThemeData theme) {
    // Placeholder for edit history
    return _buildEmptyState(
      context,
      theme,
      Icons.history,
      'No edit history',
      'Your PDF edits will appear here',
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: AppTypography.semiBold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPropertyCard(ThemeData theme, List<Widget> children) {
    return Card(
      elevation: AppElevation.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildPropertyItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: AppTypography.medium,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'Unknown';
    final bytes = size is int ? size : 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is DateTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
