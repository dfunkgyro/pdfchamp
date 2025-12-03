import 'dart:developer' as developer;

/// Log levels for the application
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR');

  final int level;
  final String label;

  const LogLevel(this.level, this.label);
}

/// Structured logging utility for the application
class AppLogger {
  final String name;

  /// Minimum log level to display (can be configured based on build mode)
  static LogLevel minLevel = LogLevel.debug;

  AppLogger(this.name);

  /// Logs a debug message
  void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Logs an info message
  void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Logs a warning message
  void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Logs an error message
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Check if log level is enabled
    if (level.level < minLevel.level) {
      return;
    }

    // Format timestamp
    final timestamp = DateTime.now().toIso8601String();

    // Build log message
    final buffer = StringBuffer();
    buffer.write('[$timestamp] [${level.label}] [$name] $message');

    // Add data if present
    if (data != null && data.isNotEmpty) {
      buffer.write('\n  Data: ${_formatData(data)}');
    }

    // Add error if present
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    // Add stack trace if present
    if (stackTrace != null) {
      buffer.write('\n  Stack Trace:\n${_formatStackTrace(stackTrace)}');
    }

    final logMessage = buffer.toString();

    // Output to appropriate stream based on level
    if (level == LogLevel.error) {
      // Use developer.log for better integration with Flutter DevTools
      developer.log(
        logMessage,
        name: name,
        level: 1000, // Error level
        error: error,
        stackTrace: stackTrace,
      );
    } else if (level == LogLevel.warning) {
      developer.log(
        logMessage,
        name: name,
        level: 900, // Warning level
      );
    } else {
      developer.log(
        logMessage,
        name: name,
        level: level == LogLevel.info ? 800 : 700,
      );
    }
  }

  /// Formats data map for logging
  String _formatData(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  /// Formats stack trace for better readability
  String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    // Take only the first 10 lines to avoid overwhelming logs
    final relevantLines = lines.take(10).toList();
    return relevantLines.map((line) => '    $line').join('\n');
  }

  /// Configure minimum log level based on build mode
  static void configure({required bool isRelease}) {
    minLevel = isRelease ? LogLevel.warning : LogLevel.debug;
  }

  /// Create a child logger with additional context
  AppLogger child(String childName) {
    return AppLogger('$name.$childName');
  }
}

/// Global logger for quick access
final globalLogger = AppLogger('App');
