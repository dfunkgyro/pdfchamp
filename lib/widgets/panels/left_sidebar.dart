import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_theme_constants.dart';
import '../../core/state/app_state.dart';

/// Left sidebar with folder navigation and recent files
class LeftSidebar extends StatefulWidget {
  final List<String> recentFiles;
  final String? currentFile;
  final Function(String)? onFileSelected;
  final VoidCallback? onNewFolder;

  const LeftSidebar({
    super.key,
    required this.recentFiles,
    this.currentFile,
    this.onFileSelected,
    this.onNewFolder,
  });

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _folders = ['All Documents', 'Recent', 'Favorites', 'Shared'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      width: appState.isLeftSidebarVisible ? appState.leftSidebarWidth : 0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: appState.isLeftSidebarVisible
          ? _buildSidebarContent(context, theme)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSidebarContent(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Folders'),
            Tab(text: 'Recent'),
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
              _buildFoldersTab(context, theme),
              _buildRecentTab(context, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Library',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New Folder',
            onPressed: widget.onNewFolder,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersTab(BuildContext context, ThemeData theme) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AppDurations.fast,
            child: SlideAnimation(
              verticalOffset: 20,
              child: FadeInAnimation(
                child: _buildFolderItem(
                  context,
                  theme,
                  _folders[index],
                  _getFolderIcon(index),
                  _getFolderColor(index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderItem(
    BuildContext context,
    ThemeData theme,
    String name,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        name,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Text(
        '${widget.recentFiles.length}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      onTap: () {
        // Handle folder selection
      },
      hoverColor: theme.colorScheme.primary.withOpacity(0.05),
    );
  }

  Widget _buildRecentTab(BuildContext context, ThemeData theme) {
    if (widget.recentFiles.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: widget.recentFiles.length,
        itemBuilder: (context, index) {
          final filePath = widget.recentFiles[index];
          final fileName = filePath.split('/').last;
          final isSelected = filePath == widget.currentFile;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: AppDurations.fast,
            child: SlideAnimation(
              verticalOffset: 20,
              child: FadeInAnimation(
                child: _buildFileItem(
                  context,
                  theme,
                  fileName,
                  filePath,
                  isSelected,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    ThemeData theme,
    String fileName,
    String filePath,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf,
          color: isSelected ? AppColors.primary : AppColors.error,
          size: 20,
        ),
        title: Text(
          fileName,
          style: theme.textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getRelativeTime(filePath),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: AppTypography.xs,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        onTap: () => widget.onFileSelected?.call(filePath),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: theme.iconTheme.color?.withOpacity(0.6),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: Row(
                children: [
                  Icon(Icons.star_outline, size: 16),
                  SizedBox(width: AppSpacing.sm),
                  Text('Add to Favorites'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16),
                  SizedBox(width: AppSpacing.sm),
                  Text('Remove from Recent'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // Handle menu action
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No recent files',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Open a PDF to get started',
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

  IconData _getFolderIcon(int index) {
    switch (index) {
      case 0:
        return Icons.folder;
      case 1:
        return Icons.access_time;
      case 2:
        return Icons.star;
      case 3:
        return Icons.people;
      default:
        return Icons.folder;
    }
  }

  Color _getFolderColor(int index) {
    switch (index) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.secondary;
      default:
        return AppColors.grey500;
    }
  }

  String _getRelativeTime(String filePath) {
    // In a real implementation, you would get the actual file modification time
    // This is a placeholder
    return 'Just now';
  }
}
