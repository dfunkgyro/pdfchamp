import 'package:dart_openai/dart_openai.dart';
import '../../config/app_config.dart';
import '../../logging/app_logger.dart';
import '../../error/error_codes.dart';
import '../../exceptions/app_exceptions.dart';

/// OpenAI AI Assistant Service
/// Provides AI-powered features for PDF analysis and user assistance
class OpenAIService {
  static final AppLogger _logger = AppLogger('OpenAIService');
  static bool _initialized = false;

  /// Initialize OpenAI
  static Future<void> initialize() async {
    if (_initialized) {
      _logger.warning('OpenAI already initialized');
      return;
    }

    try {
      if (!AppConfig.hasOpenAiConfig) {
        _logger.warning('OpenAI configuration not found');
        return;
      }

      _logger.info('Initializing OpenAI');

      OpenAI.apiKey = AppConfig.openAiApiKey;

      if (AppConfig.openAiOrganizationId.isNotEmpty) {
        OpenAI.organization = AppConfig.openAiOrganizationId;
      }

      OpenAI.showLogs = AppConfig.enableDebugLogs;
      OpenAI.showResponsesLogs = AppConfig.verboseLogging;

      _initialized = true;
      _logger.info('OpenAI initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize OpenAI',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if OpenAI is initialized and configured
  static bool get isAvailable => _initialized && AppConfig.hasOpenAiConfig;

  /// Send chat message to AI assistant
  static Future<String> chat({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? systemPrompt,
  }) async {
    if (!isAvailable) {
      throw NetworkException(
        message: 'OpenAI service not available',
        code: ErrorCode.networkConnectionError.code,
      );
    }

    try {
      _logger.info('Sending chat message to AI');

      final messages = <OpenAIChatCompletionChoiceMessageModel>[];

      // Add system prompt
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              systemPrompt ??
                  'You are ${AppConfig.aiAssistantName}, a helpful AI assistant specialized in PDF document analysis, editing, and management. '
                      'Provide clear, concise, and accurate assistance to users.',
            ),
          ],
        ),
      );

      // Add conversation history
      if (conversationHistory != null) {
        for (final msg in conversationHistory) {
          messages.add(
            OpenAIChatCompletionChoiceMessageModel(
              role: msg['role'] == 'user'
                  ? OpenAIChatMessageRole.user
                  : OpenAIChatMessageRole.assistant,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  msg['content'] ?? '',
                ),
              ],
            ),
          );
        }
      }

      // Add current message
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
          ],
        ),
      );

      final chatCompletion = await OpenAI.instance.chat.create(
        model: AppConfig.aiModel,
        messages: messages,
        maxTokens: AppConfig.aiMaxTokens,
        temperature: AppConfig.aiTemperature,
      );

      final response = chatCompletion.choices.first.message.content?.first.text ?? '';

      _logger.info('Received AI response', data: {
        'tokens': chatCompletion.usage.totalTokens,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error('Chat request failed', error: e, stackTrace: stackTrace);
      throw NetworkException(
        message: 'Failed to get AI response',
        code: ErrorCode.networkRequestFailed.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Summarize PDF text content
  static Future<String> summarizePdfContent({
    required String content,
    int? maxLength,
  }) async {
    final prompt = '''
Please provide a concise summary of the following PDF content.
${maxLength != null ? 'Keep the summary under $maxLength words.' : ''}

Content:
$content
''';

    return chat(
      message: prompt,
      systemPrompt:
          'You are a document summarization expert. Provide clear, accurate summaries that capture the main points.',
    );
  }

  /// Extract key information from PDF
  static Future<Map<String, dynamic>> extractKeyInfo({
    required String content,
    List<String>? fieldsToExtract,
  }) async {
    final fields = fieldsToExtract?.join(', ') ?? 'all relevant information';

    final prompt = '''
Extract the following information from this PDF content: $fields

Return the information in a structured format.

Content:
$content
''';

    final response = await chat(
      message: prompt,
      systemPrompt:
          'You are a data extraction expert. Extract information accurately and return it in a clear, structured format.',
    );

    // Parse response into structured data
    return {'extracted_text': response};
  }

  /// Translate PDF content
  static Future<String> translateContent({
    required String content,
    required String targetLanguage,
  }) async {
    final prompt = '''
Translate the following PDF content to $targetLanguage.
Maintain the original formatting and structure as much as possible.

Content:
$content
''';

    return chat(
      message: prompt,
      systemPrompt:
          'You are a professional translator. Provide accurate translations while preserving formatting.',
    );
  }

  /// Analyze PDF document
  static Future<Map<String, dynamic>> analyzeDocument({
    required String content,
    List<String>? analysisTypes,
  }) async {
    final types = analysisTypes?.join(', ') ??
        'content structure, key topics, sentiment, readability';

    final prompt = '''
Perform a comprehensive analysis of this PDF document, focusing on: $types

Provide insights and recommendations.

Content:
$content
''';

    final response = await chat(
      message: prompt,
      systemPrompt:
          'You are a document analysis expert. Provide thorough, actionable insights.',
    );

    return {
      'analysis': response,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Answer questions about PDF content
  static Future<String> answerQuestion({
    required String question,
    required String pdfContent,
  }) async {
    final prompt = '''
Based on the following PDF content, please answer this question:

Question: $question

PDF Content:
$pdfContent
''';

    return chat(
      message: prompt,
      systemPrompt:
          'You are a helpful assistant answering questions about PDF documents. '
              'Provide accurate, relevant answers based only on the provided content.',
    );
  }

  /// Generate PDF editing suggestions
  static Future<List<String>> suggestEdits({
    required String content,
    String? editGoal,
  }) async {
    final goal = editGoal ?? 'improve clarity and readability';

    final prompt = '''
Review this PDF content and suggest specific edits to $goal.
Provide concrete, actionable suggestions.

Content:
$content
''';

    final response = await chat(
      message: prompt,
      systemPrompt:
          'You are an expert editor. Provide specific, helpful editing suggestions.',
    );

    // Parse response into list of suggestions
    return response.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  /// Stream chat responses (for real-time interaction)
  static Stream<String> chatStream({
    required String message,
    String? systemPrompt,
  }) async* {
    if (!isAvailable) {
      throw NetworkException(
        message: 'OpenAI service not available',
        code: ErrorCode.networkConnectionError.code,
      );
    }

    try {
      _logger.info('Starting streaming chat');

      final stream = OpenAI.instance.chat.createStream(
        model: AppConfig.aiModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                systemPrompt ??
                    'You are ${AppConfig.aiAssistantName}, a helpful AI assistant.',
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
            ],
          ),
        ],
        maxTokens: AppConfig.aiMaxTokens,
        temperature: AppConfig.aiTemperature,
      );

      await for (final event in stream) {
        final content = event.choices.first.delta.content?.first.text;
        if (content != null) {
          yield content;
        }
      }

      _logger.info('Streaming chat completed');
    } catch (e, stackTrace) {
      _logger.error('Streaming chat failed', error: e, stackTrace: stackTrace);
      throw NetworkException(
        message: 'Failed to stream AI response',
        code: ErrorCode.networkRequestFailed.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
