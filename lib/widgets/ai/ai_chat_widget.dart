import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme_constants.dart';
import '../../core/services/ai/openai_service.dart';
import '../../core/logging/app_logger.dart';

/// AI Chat Widget for interacting with the AI assistant
class AIChatWidget extends StatefulWidget {
  final String? pdfContent;

  const AIChatWidget({
    super.key,
    this.pdfContent,
  });

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  static final AppLogger _logger = AppLogger('AIChatWidget');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Quick Actions
        if (widget.pdfContent != null) _buildQuickActions(context, theme),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildMessagesList(context, theme),
        ),

        // Input
        _buildInput(context, theme),
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
            Icons.smart_toy,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              if (OpenAIService.isAvailable)
                Text(
                  'Online',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontSize: AppTypography.xs,
                  ),
                )
              else
                Text(
                  'Offline',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontSize: AppTypography.xs,
                  ),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Clear Chat',
            onPressed: _messages.isEmpty ? null : _clearChat,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _buildQuickActionChip(
            context,
            theme,
            'Summarize',
            Icons.summarize,
            () => _handleQuickAction('summarize'),
          ),
          _buildQuickActionChip(
            context,
            theme,
            'Extract Info',
            Icons.text_snippet,
            () => _handleQuickAction('extract'),
          ),
          _buildQuickActionChip(
            context,
            theme,
            'Analyze',
            Icons.analytics,
            () => _handleQuickAction('analyze'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.circular),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.circular),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontSize: AppTypography.xs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(context, theme, _messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ThemeData theme,
    ChatMessage message,
  ) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md).copyWith(
                  bottomRight: isUser ? Radius.zero : null,
                  bottomLeft: isUser ? null : Radius.zero,
                ),
              ),
              child: message.isStreaming
                  ? _buildStreamingText(theme, message.content)
                  : Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : null,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingText(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium,
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
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start a conversation',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask me anything about your PDF',
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

  Widget _buildInput(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading && OpenAIService.isAvailable,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 20),
            onPressed: _isLoading || !OpenAIService.isAvailable
                ? null
                : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Prepare conversation history
      final history = _messages
          .where((m) => !m.isStreaming)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final response = await OpenAIService.chat(
        message: message,
        conversationHistory: history.length > 1
            ? history.sublist(0, history.length - 1)
            : null,
        systemPrompt: widget.pdfContent != null
            ? 'You are a helpful AI assistant analyzing a PDF document. '
                'Provide accurate, concise answers based on the context.'
            : null,
      );

      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e, stackTrace) {
      _logger.error('Failed to send message', error: e, stackTrace: stackTrace);

      setState(() {
        _messages.add(ChatMessage(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  Future<void> _handleQuickAction(String action) async {
    if (widget.pdfContent == null) return;

    String prompt;
    switch (action) {
      case 'summarize':
        prompt = 'Please provide a concise summary of this PDF';
        break;
      case 'extract':
        prompt = 'Extract the key information from this PDF';
        break;
      case 'analyze':
        prompt = 'Analyze the structure and content of this PDF';
        break;
      default:
        return;
    }

    _messageController.text = prompt;
    await _sendMessage();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: AppCurves.easeOut,
        );
      }
    });
  }
}

/// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final bool isStreaming;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  }) : timestamp = DateTime.now();
}
