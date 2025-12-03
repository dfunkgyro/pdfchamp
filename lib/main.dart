import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/services/supabase/supabase_service.dart';
import 'core/services/ai/openai_service.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'screens/enhanced_home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  final logger = AppLogger('Main');

  try {
    logger.info('Initializing PDFChamp');

    // Load environment configuration
    await AppConfig.initialize();
    logger.info('Configuration loaded');

    // Print config summary (safe - no secrets)
    if (AppConfig.enableDebugLogs) {
      AppConfig.printSummary();
    }

    // Initialize Supabase if configured
    if (AppConfig.hasSupabaseConfig && !AppConfig.mockSupabase) {
      try {
        await SupabaseService.initialize();
        logger.info('Supabase initialized');
      } catch (e) {
        logger.warning('Supabase initialization failed', data: {'error': e.toString()});
      }
    } else {
      logger.info('Supabase not configured or in mock mode');
    }

    // Initialize OpenAI if configured
    if (AppConfig.hasOpenAiConfig && !AppConfig.mockOpenAi) {
      try {
        await OpenAIService.initialize();
        logger.info('OpenAI initialized');
      } catch (e) {
        logger.warning('OpenAI initialization failed', data: {'error': e.toString()});
      }
    } else {
      logger.info('OpenAI not configured or in mock mode');
    }

    logger.info('PDFChamp initialization complete');
  } catch (e, stackTrace) {
    logger.error('Failed to initialize application', error: e, stackTrace: stackTrace);
    // Continue anyway - app can work in offline mode
  }

  // Run the app
  runApp(const PDFChampApp());
}

class PDFChampApp extends StatelessWidget {
  const PDFChampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // App State Provider
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: !AppConfig.isProduction,

            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,

            // Home Screen
            home: const EnhancedHomeScreen(),

            // Performance Optimizations
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Adjust text scale factor for consistency
                  textScaleFactor: 1.0,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
