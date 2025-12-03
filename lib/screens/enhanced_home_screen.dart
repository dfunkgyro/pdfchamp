import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/error/error_handler.dart';
import '../core/logging/app_logger.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme_constants.dart';
import '../widgets/panels/top_panel.dart';
import '../widgets/panels/left_sidebar.dart';
import '../widgets/panels/right_sidebar.dart';
import '../models/pdf_document.dart';

/// Enhanced home screen with toggleable panels and modern UI
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  static final AppLogger _logger = AppLogger('EnhancedHomeScreen');

  // PDF State
  String? _pdfPath;
  PDFDocument? _pdfDocument;
  final List<String> _recentFiles = [];
  String? _pdfContent;
  Map<String, dynamic>? _pdfMetadata;

  // UI State
  bool _isEditing = false;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 0;

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppDurations.normal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: AppCurves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _pickPDF,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _savePDF,
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            _toggleEditMode,
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            appState.toggleLeftSidebar,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            appState.toggleRightSidebar,
        const SingleActivator(LogicalKeyboardKey.keyT, control: true):
            appState.toggleTopPanel,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true):
            appState.toggleAiAssistant,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              // Top Panel
              TopPanel(
                pdfFileName: _pdfDocument?.fileName,
                pageCount: _totalPages,
                currentPage: _currentPage,
                onSearch: _showSearch,
                onSettings: _showSettings,
              ),

              // Main Content Area
              Expanded(
                child: Row(
                  children: [
                    // Left Sidebar
                    LeftSidebar(
                      recentFiles: _recentFiles,
                      currentFile: _pdfPath,
                      onFileSelected: _loadPDF,
                      onNewFolder: _showNewFolderDialog,
                    ),

                    // Center Content
                    Expanded(
                      child: _buildMainContent(context),
                    ),

                    // Right Sidebar
                    RightSidebar(
                      pdfContent: _pdfContent,
                      pdfMetadata: _pdfMetadata,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Action Buttons
          floatingActionButton: _buildFloatingActions(context),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_pdfPath == null) {
      return _buildEmptyState(context);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildPDFViewer(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading PDF...',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: AppDurations.slow,
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Welcome to PDFChamp',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Open a PDF file to start viewing or editing',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _pickPDF,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open PDF'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _showKeyboardShortcuts,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Shortcuts'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPDFViewer(BuildContext context) {
    // Placeholder for actual PDF viewer
    // In production, this would use the syncfusion_flutter_pdfviewer or similar
    return Container(
      color: AppColors.grey200,
      child: Center(
        child: Text(
          'PDF Viewer: ${_pdfDocument?.fileName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget? _buildFloatingActions(BuildContext context) {
    if (_pdfPath == null) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'edit',
          onPressed: _toggleEditMode,
          tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
          backgroundColor: _isEditing ? AppColors.accent : AppColors.primary,
          child: Icon(_isEditing ? Icons.visibility : Icons.edit),
        ),
        const SizedBox(height: AppSpacing.md),
        FloatingActionButton(
          heroTag: 'save',
          onPressed: _savePDF,
          tooltip: 'Save PDF',
          child: const Icon(Icons.save),
        ),
      ],
    );
  }

  // ======================
  // PDF Operations
  // ======================

  Future<void> _pickPDF() async {
    try {
      _logger.info('User initiated file picker');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        await _loadPDF(result.files.single.path!);
      } else {
        _logger.debug('User cancelled file picker');
      }
    } catch (e, stackTrace) {
      _logger.error('Error picking file', error: e, stackTrace: stackTrace);
      _showErrorSnackBar(ErrorHandler.handleError(e, stackTrace: stackTrace));
    }
  }

  Future<void> _loadPDF(String path) async {
    setState(() => _isLoading = true);

    try {
      _logger.info('Loading PDF', data: {'path': path});

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File not found: $path');
      }

      // Get file stats
      final stat = await file.stat();

      final pdfDoc = PDFDocument(
        path: path,
        fileName: path.split('/').last,
      );

      // Extract PDF metadata
      _pdfMetadata = {
        'fileName': pdfDoc.fileName,
        'fileSize': stat.size,
        'created': stat.modified,
        'modified': stat.modified,
        'pageCount': 0, // Would be extracted from actual PDF
        'title': null,
        'author': null,
        'subject': null,
        'keywords': null,
        'encrypted': false,
        'permissions': 'Full access',
      };

      setState(() {
        _pdfPath = path;
        _pdfDocument = pdfDoc;
        _isEditing = false;
        _isLoading = false;
        _totalPages = 0; // Would be from actual PDF

        if (!_recentFiles.contains(path)) {
          _recentFiles.insert(0, path);
          if (_recentFiles.length > 20) {
            _recentFiles.removeLast();
          }
        }
      });

      // Reset fade animation
      _fadeController.reset();
      _fadeController.forward();

      _logger.info('PDF loaded successfully');
    } catch (e, stackTrace) {
      _logger.error('Error loading PDF', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      _showErrorSnackBar(ErrorHandler.handleError(e, stackTrace: stackTrace));
    }
  }

  Future<void> _savePDF() async {
    if (_pdfPath == null) return;

    try {
      _logger.info('User initiated PDF save');

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF As',
        fileName: 'edited_${_pdfDocument!.fileName}',
        allowedExtensions: ['pdf'],
      );

      if (savedPath != null) {
        _logger.info('PDF saved successfully', data: {'path': savedPath});
        _showSuccessSnackBar('PDF saved successfully!');
      }
    } catch (e, stackTrace) {
      _logger.error('Error saving PDF', error: e, stackTrace: stackTrace);
      _showErrorSnackBar(ErrorHandler.handleError(e, stackTrace: stackTrace));
    }
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  // ======================
  // UI Actions
  // ======================

  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search PDF'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Implement search
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    _logger.info('Opening settings');
    // Implement settings dialog
  }

  void _showNewFolderDialog() {
    // Implement new folder dialog
  }

  void _showKeyboardShortcuts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutItem('Ctrl+O', 'Open PDF'),
            _buildShortcutItem('Ctrl+S', 'Save PDF'),
            _buildShortcutItem('Ctrl+E', 'Toggle Edit Mode'),
            _buildShortcutItem('Ctrl+L', 'Toggle Left Sidebar'),
            _buildShortcutItem('Ctrl+R', 'Toggle Right Sidebar'),
            _buildShortcutItem('Ctrl+T', 'Toggle Top Panel'),
            _buildShortcutItem('Ctrl+Shift+A', 'Toggle AI Assistant'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              shortcut,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: AppTypography.monoFont,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ======================
  // Notifications
  // ======================

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
