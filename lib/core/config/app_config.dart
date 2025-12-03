import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../logging/app_logger.dart';

/// Application configuration management
/// Loads and provides access to environment variables
class AppConfig {
  static final AppLogger _logger = AppLogger('AppConfig');
  static bool _initialized = false;

  /// Initialize configuration by loading .env file
  static Future<void> initialize() async {
    if (_initialized) {
      _logger.warning('AppConfig already initialized');
      return;
    }

    try {
      _logger.info('Loading environment configuration');
      await dotenv.load(fileName: 'assets/.env');
      _initialized = true;
      _logger.info('Environment configuration loaded successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load environment configuration',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - allow app to continue with default values
    }
  }

  /// Check if config is initialized
  static bool get isInitialized => _initialized;

  // ======================
  // SUPABASE CONFIGURATION
  // ======================

  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get supabaseServiceRoleKey =>
      dotenv.get('SUPABASE_SERVICE_ROLE_KEY', fallback: '');

  static String get supabasePdfBucket =>
      dotenv.get('SUPABASE_PDF_BUCKET', fallback: 'pdfs');

  static String get supabaseThumbnailBucket =>
      dotenv.get('SUPABASE_THUMBNAIL_BUCKET', fallback: 'thumbnails');

  static String get supabaseFontsBucket =>
      dotenv.get('SUPABASE_FONTS_BUCKET', fallback: 'fonts');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ======================
  // OPENAI CONFIGURATION
  // ======================

  static String get openAiApiKey =>
      dotenv.get('OPENAI_API_KEY', fallback: '');

  static String get openAiOrganizationId =>
      dotenv.get('OPENAI_ORGANIZATION_ID', fallback: '');

  static String get aiModel =>
      dotenv.get('AI_MODEL', fallback: 'gpt-4-turbo-preview');

  static int get aiMaxTokens =>
      int.tryParse(dotenv.get('AI_MAX_TOKENS', fallback: '4096')) ?? 4096;

  static double get aiTemperature =>
      double.tryParse(dotenv.get('AI_TEMPERATURE', fallback: '0.7')) ?? 0.7;

  static String get aiAssistantName =>
      dotenv.get('AI_ASSISTANT_NAME', fallback: 'PDFChamp AI');

  static bool get hasOpenAiConfig => openAiApiKey.isNotEmpty;

  // ======================
  // APPLICATION SETTINGS
  // ======================

  static String get appName =>
      dotenv.get('APP_NAME', fallback: 'PDFChamp');

  static String get appVersion =>
      dotenv.get('APP_VERSION', fallback: '1.0.0');

  static String get appEnv =>
      dotenv.get('APP_ENV', fallback: 'development');

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';

  // ======================
  // FEATURE FLAGS
  // ======================

  static bool get enableAiAssistant =>
      _parseBool('ENABLE_AI_ASSISTANT', true);

  static bool get enableCloudSync =>
      _parseBool('ENABLE_CLOUD_SYNC', true);

  static bool get enableAnalytics =>
      _parseBool('ENABLE_ANALYTICS', false);

  static bool get enableDebugLogs =>
      _parseBool('ENABLE_DEBUG_LOGS', true);

  // ======================
  // UI SETTINGS
  // ======================

  static String get defaultTheme =>
      dotenv.get('DEFAULT_THEME', fallback: 'dark');

  static bool get enableAnimations =>
      _parseBool('ENABLE_ANIMATIONS', true);

  static int get animationSpeed =>
      int.tryParse(dotenv.get('ANIMATION_SPEED', fallback: '300')) ?? 300;

  // ======================
  // PERFORMANCE SETTINGS
  // ======================

  static int get pdfCacheSizeMb =>
      int.tryParse(dotenv.get('PDF_CACHE_SIZE_MB', fallback: '100')) ?? 100;

  static int get imageCacheSizeMb =>
      int.tryParse(dotenv.get('IMAGE_CACHE_SIZE_MB', fallback: '50')) ?? 50;

  static int get maxRecentFiles =>
      int.tryParse(dotenv.get('MAX_RECENT_FILES', fallback: '20')) ?? 20;

  static int get autoSaveIntervalSeconds =>
      int.tryParse(dotenv.get('AUTO_SAVE_INTERVAL_SECONDS', fallback: '30')) ?? 30;

  // ======================
  // DATABASE CONFIGURATION
  // ======================

  static String get localDbName =>
      dotenv.get('LOCAL_DB_NAME', fallback: 'pdfchamp_local');

  static int get localDbVersion =>
      int.tryParse(dotenv.get('LOCAL_DB_VERSION', fallback: '1')) ?? 1;

  static int get syncIntervalMinutes =>
      int.tryParse(dotenv.get('SYNC_INTERVAL_MINUTES', fallback: '5')) ?? 5;

  static bool get offlineModeEnabled =>
      _parseBool('OFFLINE_MODE_ENABLED', true);

  // ======================
  // SECURITY
  // ======================

  static bool get encryptionEnabled =>
      _parseBool('ENCRYPTION_ENABLED', true);

  static int get sessionTimeoutMinutes =>
      int.tryParse(dotenv.get('SESSION_TIMEOUT_MINUTES', fallback: '60')) ?? 60;

  static int get maxLoginAttempts =>
      int.tryParse(dotenv.get('MAX_LOGIN_ATTEMPTS', fallback: '5')) ?? 5;

  // ======================
  // DEVELOPMENT SETTINGS
  // ======================

  static bool get mockSupabase =>
      _parseBool('MOCK_SUPABASE', false);

  static bool get mockOpenAi =>
      _parseBool('MOCK_OPENAI', false);

  static bool get verboseLogging =>
      _parseBool('VERBOSE_LOGGING', true);

  // ======================
  // HELPER METHODS
  // ======================

  /// Parse boolean from environment variable
  static bool _parseBool(String key, bool defaultValue) {
    final value = dotenv.get(key, fallback: defaultValue.toString());
    return value.toLowerCase() == 'true';
  }

  /// Get all configuration as a map (for debugging)
  static Map<String, dynamic> toMap() {
    return {
      'app': {
        'name': appName,
        'version': appVersion,
        'environment': appEnv,
      },
      'features': {
        'aiAssistant': enableAiAssistant,
        'cloudSync': enableCloudSync,
        'analytics': enableAnalytics,
        'debugLogs': enableDebugLogs,
      },
      'ui': {
        'theme': defaultTheme,
        'animations': enableAnimations,
        'animationSpeed': animationSpeed,
      },
      'performance': {
        'pdfCacheSizeMb': pdfCacheSizeMb,
        'imageCacheSizeMb': imageCacheSizeMb,
        'maxRecentFiles': maxRecentFiles,
        'autoSaveInterval': autoSaveIntervalSeconds,
      },
      'database': {
        'localDbName': localDbName,
        'localDbVersion': localDbVersion,
        'syncInterval': syncIntervalMinutes,
        'offlineMode': offlineModeEnabled,
      },
      'security': {
        'encryption': encryptionEnabled,
        'sessionTimeout': sessionTimeoutMinutes,
        'maxLoginAttempts': maxLoginAttempts,
      },
      'services': {
        'supabase': hasSupabaseConfig,
        'openai': hasOpenAiConfig,
      },
    };
  }

  /// Print configuration summary (safe - no secrets)
  static void printSummary() {
    final config = toMap();
    _logger.info('Configuration Summary', data: config);
  }
}
