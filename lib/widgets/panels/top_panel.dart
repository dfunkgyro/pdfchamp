import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme_constants.dart';
import '../../core/state/app_state.dart';

/// Top panel with PDF information and quick actions
class TopPanel extends StatelessWidget {
  final String? pdfFileName;
  final int? pageCount;
  final int? currentPage;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;

  const TopPanel({
    super.key,
    this.pdfFileName,
    this.pageCount,
    this.currentPage,
    this.onSearch,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: AppCurves.easeInOut,
      height: appState.isTopPanelVisible ? appState.topPanelHeight : 0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: appState.isTopPanelVisible
          ? _buildPanelContent(context, theme)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPanelContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // PDF Info Section
          if (pdfFileName != null) ...[
            Icon(
              Icons.picture_as_pdf,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pdfFileName!,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pageCount != null)
                    Text(
                      '${currentPage ?? 1} / $pageCount pages',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                'PDFChamp',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],

          const SizedBox(width: AppSpacing.md),

          // Quick Actions
          _buildQuickActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final appState = context.read<AppState>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: onSearch,
        ),

        // Theme Toggle
        IconButton(
          icon: Icon(
            appState.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          tooltip: 'Toggle Theme',
          onPressed: () => appState.toggleTheme(),
        ),

        const VerticalDivider(),

        // Panel Toggles
        IconButton(
          icon: const Icon(Icons.view_sidebar),
          tooltip: 'Toggle Left Sidebar',
          color: appState.isLeftSidebarVisible
              ? AppColors.primary
              : theme.iconTheme.color,
          onPressed: () => appState.toggleLeftSidebar(),
        ),

        IconButton(
          icon: const Icon(Icons.dashboard),
          tooltip: 'Toggle Right Sidebar',
          color: appState.isRightSidebarVisible
              ? AppColors.primary
              : theme.iconTheme.color,
          onPressed: () => appState.toggleRightSidebar(),
        ),

        const VerticalDivider(),

        // AI Assistant
        Tooltip(
          message: 'AI Assistant',
          child: FilledButton.icon(
            onPressed: () => appState.toggleAiAssistant(),
            icon: Icon(
              appState.isAiAssistantVisible
                  ? Icons.smart_toy
                  : Icons.smart_toy_outlined,
              size: 18,
            ),
            label: const Text('AI'),
            style: FilledButton.styleFrom(
              backgroundColor: appState.isAiAssistantVisible
                  ? AppColors.accent
                  : AppColors.grey600,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: onSettings,
        ),
      ],
    );
  }
}
