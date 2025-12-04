import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai/openai_service.dart';
import '../../core/services/ai/ai_prompts.dart';
import '../../core/services/pdf/ocr_service.dart';
import '../../core/services/pdf/form_service.dart';
import '../../core/services/pdf/annotation_service.dart';
import '../../core/services/pdf/pdf_editor_service.dart';
import '../../core/theme/app_theme_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../core/state/app_state.dart';

/// Enhanced AI Chat Widget with full control over all app features
class EnhancedAIChatWidget extends StatefulWidget {
  final String? pdfPath;
  final String? pdfContent;
  final int? currentPage;
  final int? totalPages;
  final Function(AICommand)? onCommandExecuted;

  const EnhancedAIChatWidget({
    super.key,
    this.pdfPath,
    this.pdfContent,
    this.currentPage,
    this.totalPages,
    this.onCommandExecuted,
  });

  @override
  State<EnhancedAIChatWidget> createState() => _EnhancedAIChatWidgetState();
}

class _EnhancedAIChatWidgetState extends State<EnhancedAIChatWidget> {
  final AppLogger _logger = AppLogger('EnhancedAIChatWidget');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];

  bool _isProcessing = false;
  bool _isStreaming = false;
  String _streamingMessage = '';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final hasP pdf = widget.pdfPath != null;
    final welcomeText = hasPdf
        ? 'Hello! I\'m your AI assistant. I can help you with:\n\n'
            '• Summarize this PDF\n'
            '• Extract information\n'
            '• OCR scanned pages\n'
            '• Fill forms automatically\n'
            '• Add annotations\n'
            '• Edit pages (rotate, delete, reorder)\n'
            '• Export to different formats\n'
            '• Answer questions about the content\n\n'
            'What would you like me to do?'
        : 'Hello! I\'m your AI assistant. Open a PDF to get started with advanced features like OCR, form filling, and intelligent analysis.';

    setState(() {
      _messages.add(ChatMessage(
        content: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isProcessing) return;

    _logger.info('User message: $message');

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': message});

    try {
      // Detect if this is a command or question
      final command = await _detectCommand(message);

      if (command != null) {
        // Execute command
        await _executeCommand(command);
      } else {
        // Regular chat
        await _handleRegularChat(message);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to process message', error: e, stackTrace: stackTrace);
      _addAIMessage('Sorry, I encountered an error: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<AICommand?> _detectCommand(String message) async {
    final lowerMessage = message.toLowerCase();

    // OCR commands
    if (lowerMessage.contains('ocr') ||
        lowerMessage.contains('extract text') ||
        lowerMessage.contains('scan')) {
      return AICommand(
        type: AICommandType.ocr,
        parameters: {'message': message},
      );
    }

    // Summarize commands
    if (lowerMessage.contains('summarize') ||
        lowerMessage.contains('summary') ||
        lowerMessage.contains('tldr')) {
      return AICommand(
        type: AICommandType.summarize,
        parameters: {'message': message},
      );
    }

    // Extract commands
    if (lowerMessage.contains('extract') && !lowerMessage.contains('text')) {
      return AICommand(
        type: AICommandType.extract,
        parameters: {'message': message},
      );
    }

    // Translate commands
    if (lowerMessage.contains('translate')) {
      return AICommand(
        type: AICommandType.translate,
        parameters: {'message': message},
      );
    }

    // Form filling commands
    if (lowerMessage.contains('fill form') ||
        lowerMessage.contains('fill out') ||
        lowerMessage.contains('complete form')) {
      return AICommand(
        type: AICommandType.fillForm,
        parameters: {'message': message},
      );
    }

    // Annotation commands
    if (lowerMessage.contains('annotate') ||
        lowerMessage.contains('highlight') ||
        lowerMessage.contains('add comment')) {
      return AICommand(
        type: AICommandType.annotate,
        parameters: {'message': message},
      );
    }

    // Page manipulation commands
    if (lowerMessage.contains('rotate') ||
        lowerMessage.contains('delete page') ||
        lowerMessage.contains('reorder') ||
        lowerMessage.contains('extract page')) {
      return AICommand(
        type: AICommandType.editPages,
        parameters: {'message': message},
      );
    }

    // Export commands
    if (lowerMessage.contains('export') ||
        lowerMessage.contains('save as') ||
        lowerMessage.contains('convert to')) {
      return AICommand(
        type: AICommandType.export,
        parameters: {'message': message},
      );
    }

    // Analysis commands
    if (lowerMessage.contains('analyze') ||
        lowerMessage.contains('analysis')) {
      return AICommand(
        type: AICommandType.analyze,
        parameters: {'message': message},
      );
    }

    return null;
  }

  Future<void> _executeCommand(AICommand command) async {
    _logger.info('Executing command: ${command.type}');

    widget.onCommandExecuted?.call(command);

    switch (command.type) {
      case AICommandType.ocr:
        await _handleOCR(command);
        break;
      case AICommandType.summarize:
        await _handleSummarize(command);
        break;
      case AICommandType.extract:
        await _handleExtract(command);
        break;
      case AICommandType.translate:
        await _handleTranslate(command);
        break;
      case AICommandType.fillForm:
        await _handleFillForm(command);
        break;
      case AICommandType.annotate:
        await _handleAnnotate(command);
        break;
      case AICommandType.editPages:
        await _handleEditPages(command);
        break;
      case AICommandType.export:
        await _handleExport(command);
        break;
      case AICommandType.analyze:
        await _handleAnalyze(command);
        break;
    }
  }

  Future<void> _handleOCR(AICommand command) async {
    if (widget.pdfPath == null) {
      _addAIMessage('Please open a PDF file first.');
      return;
    }

    _addAIMessage('🔍 Starting OCR process... This may take a moment.');

    try {
      final pageIndex = widget.currentPage ?? 0;
      final text = await OCRService.extractTextFromPage(widget.pdfPath!, pageIndex);

      _addAIMessage('✅ OCR completed! Extracted ${text.length} characters from page ${pageIndex + 1}.\n\nExtracted text:\n\n$text');

      _conversationHistory.add({
        'role': 'assistant',
        'content': 'OCR completed. Extracted text available.',
      });
    } catch (e) {
      _addAIMessage('❌ OCR failed: ${e.toString()}');
    }
  }

  Future<void> _handleSummarize(AICommand command) async {
    if (widget.pdfContent == null || widget.pdfContent!.isEmpty) {
      _addAIMessage('No PDF content available to summarize. Please open a PDF first.');
      return;
    }

    _addAIMessage('📝 Generating summary...');

    try {
      final summary = await OpenAIService.summarizePdfContent(
        content: widget.pdfContent!,
        maxLength: 300,
      );

      _addAIMessage(summary);
      _conversationHistory.add({
        'role': 'assistant',
        'content': summary,
      });
    } catch (e) {
      _addAIMessage('❌ Summarization failed: ${e.toString()}');
    }
  }

  Future<void> _handleExtract(AICommand command) async {
    if (widget.pdfContent == null || widget.pdfContent!.isEmpty) {
      _addAIMessage('No PDF content available. Please open a PDF first.');
      return;
    }

    _addAIMessage('🔎 Extracting key information...');

    try {
      final result = await OpenAIService.extractKeyInfo(
        content: widget.pdfContent!,
      );

      _addAIMessage(result['extracted_data'] ?? 'No information extracted.');
      _conversationHistory.add({
        'role': 'assistant',
        'content': result['extracted_data'] ?? '',
      });
    } catch (e) {
      _addAIMessage('❌ Extraction failed: ${e.toString()}');
    }
  }

  Future<void> _handleTranslate(AICommand command) async {
    if (widget.pdfContent == null || widget.pdfContent!.isEmpty) {
      _addAIMessage('No PDF content available. Please open a PDF first.');
      return;
    }

    // Extract target language from message
    final message = command.parameters['message'] as String;
    String targetLang = 'Spanish'; // Default

    if (message.contains('spanish')) targetLang = 'Spanish';
    else if (message.contains('french')) targetLang = 'French';
    else if (message.contains('german')) targetLang = 'German';
    else if (message.contains('chinese')) targetLang = 'Chinese';
    else if (message.contains('japanese')) targetLang = 'Japanese';

    _addAIMessage('🌐 Translating to $targetLang...');

    try {
      final translation = await OpenAIService.translateContent(
        content: widget.pdfContent!,
        targetLanguage: targetLang,
      );

      _addAIMessage(translation);
      _conversationHistory.add({
        'role': 'assistant',
        'content': translation,
      });
    } catch (e) {
      _addAIMessage('❌ Translation failed: ${e.toString()}');
    }
  }

  Future<void> _handleFillForm(AICommand command) async {
    if (widget.pdfPath == null) {
      _addAIMessage('Please open a PDF file first.');
      return;
    }

    _addAIMessage('📋 Analyzing form fields...');

    try {
      final formFields = await FormService.getFormFields(widget.pdfPath!);

      if (formFields.isEmpty) {
        _addAIMessage('This PDF does not contain any fillable forms.');
        return;
      }

      _addAIMessage('Found ${formFields.length} form fields:\n\n' +
          formFields.map((f) => '• ${f.name} (${f.type.name})').join('\n') +
          '\n\nWhat information would you like to fill in?');

      _conversationHistory.add({
        'role': 'assistant',
        'content': 'Found ${formFields.length} form fields',
      });
    } catch (e) {
      _addAIMessage('❌ Form analysis failed: ${e.toString()}');
    }
  }

  Future<void> _handleAnnotate(AICommand command) async {
    if (widget.pdfPath == null) {
      _addAIMessage('Please open a PDF file first.');
      return;
    }

    _addAIMessage('📝 Annotation feature enabled. You can now:\n\n'
        '• Highlight text\n'
        '• Add comments\n'
        '• Draw shapes\n'
        '• Add text annotations\n\n'
        'Use the tools panel on the left to start annotating.');

    _conversationHistory.add({
      'role': 'assistant',
      'content': 'Annotation feature explained',
    });
  }

  Future<void> _handleEditPages(AICommand command) async {
    if (widget.pdfPath == null) {
      _addAIMessage('Please open a PDF file first.');
      return;
    }

    final message = command.parameters['message'] as String;
    _addAIMessage('🔧 Page editing capabilities:\n\n'
        '• Rotate pages\n'
        '• Delete pages\n'
        '• Reorder pages\n'
        '• Extract specific pages\n'
        '• Merge multiple PDFs\n'
        '• Split PDF into individual pages\n\n'
        'Please specify which operation you\'d like to perform.');

    _conversationHistory.add({
      'role': 'assistant',
      'content': 'Page editing options explained',
    });
  }

  Future<void> _handleExport(AICommand command) async {
    if (widget.pdfPath == null) {
      _addAIMessage('Please open a PDF file first.');
      return;
    }

    _addAIMessage('💾 Export options available:\n\n'
        '• Export as PNG images\n'
        '• Export as JPEG images\n'
        '• Export individual pages\n'
        '• Export with annotations\n\n'
        'Which format would you like?');

    _conversationHistory.add({
      'role': 'assistant',
      'content': 'Export options explained',
    });
  }

  Future<void> _handleAnalyze(AICommand command) async {
    if (widget.pdfContent == null || widget.pdfContent!.isEmpty) {
      _addAIMessage('No PDF content available. Please open a PDF first.');
      return;
    }

    _addAIMessage('🔬 Analyzing document...');

    try {
      final analysis = await OpenAIService.analyzeDocument(
        content: widget.pdfContent!,
      );

      _addAIMessage(analysis['analysis'] ?? 'Analysis complete.');
      _conversationHistory.add({
        'role': 'assistant',
        'content': analysis['analysis'] ?? '',
      });
    } catch (e) {
      _addAIMessage('❌ Analysis failed: ${e.toString()}');
    }
  }

  Future<void> _handleRegularChat(String message) async {
    try {
      final response = await OpenAIService.chat(
        message: message,
        conversationHistory: _conversationHistory,
        systemPrompt: widget.pdfContent != null
            ? '${AIPrompts.pdfAssistantBase}\n\nCurrent PDF Content:\n${widget.pdfContent}'
            : AIPrompts.pdfAssistantBase,
      );

      _addAIMessage(response);
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });
    } catch (e) {
      _addAIMessage('Sorry, I couldn\'t process that. Please try again.');
    }
  }

  void _addAIMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(context),

        // Quick Actions
        _buildQuickActions(context),

        // Messages
        Expanded(
          child: _buildMessagesList(context),
        ),

        // Input
        _buildInput(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (widget.pdfPath != null)
                  Text(
                    'Ready to help with ${widget.totalPages ?? 0} pages',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          if (_isProcessing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickAction(
        icon: Icons.summarize,
        label: 'Summarize',
        onTap: () => _sendPredefinedMessage('Summarize this PDF'),
      ),
      QuickAction(
        icon: Icons.search,
        label: 'Extract',
        onTap: () => _sendPredefinedMessage('Extract key information'),
      ),
      QuickAction(
        icon: Icons.analytics,
        label: 'Analyze',
        onTap: () => _sendPredefinedMessage('Analyze this document'),
      ),
      QuickAction(
        icon: Icons.document_scanner,
        label: 'OCR',
        onTap: () => _sendPredefinedMessage('Run OCR on current page'),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions
              .map((action) => Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: ActionChip(
                      avatar: Icon(action.icon, size: 16),
                      label: Text(action.label),
                      onPressed: action.onTap,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(context, _messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: message.isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: message.isUser
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: AppSpacing.xs),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isProcessing,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: _isProcessing ? null : _sendMessage,
            icon: Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendPredefinedMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

/// AI Command model
class AICommand {
  final AICommandType type;
  final Map<String, dynamic> parameters;

  const AICommand({
    required this.type,
    required this.parameters,
  });
}

/// AI Command types
enum AICommandType {
  ocr,
  summarize,
  extract,
  translate,
  fillForm,
  annotate,
  editPages,
  export,
  analyze,
}

/// Quick action model
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
