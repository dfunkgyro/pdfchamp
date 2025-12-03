import '../exceptions/app_exceptions.dart';
import '../logging/app_logger.dart';
import 'error_codes.dart';

/// Centralized error handler for the application
class ErrorHandler {
  static final AppLogger _logger = AppLogger('ErrorHandler');

  /// Handles any error and returns a user-friendly message
  static String handleError(dynamic error, {StackTrace? stackTrace}) {
    if (error is AppException) {
      return _handleAppException(error);
    } else {
      return _handleGenericError(error, stackTrace);
    }
  }

  /// Handles application-specific exceptions
  static String _handleAppException(AppException error) {
    _logger.error(
      error.message,
      error: error.originalError,
      stackTrace: error.stackTrace,
      data: {
        'code': error.code,
        'type': error.runtimeType.toString(),
      },
    );

    // Return user-friendly message based on error type
    return getUserFriendlyMessage(error);
  }

  /// Handles generic errors
  static String _handleGenericError(dynamic error, StackTrace? stackTrace) {
    _logger.error(
      'Unexpected error occurred',
      error: error,
      stackTrace: stackTrace,
    );

    return 'An unexpected error occurred. Please try again.';
  }

  /// Converts an AppException to a user-friendly message
  static String getUserFriendlyMessage(AppException exception) {
    if (exception is PDFProcessingException) {
      return _getPDFErrorMessage(exception);
    } else if (exception is EncodingException) {
      return _getEncodingErrorMessage(exception);
    } else if (exception is FileOperationException) {
      return _getFileErrorMessage(exception);
    } else if (exception is FontException) {
      return _getFontErrorMessage(exception);
    } else if (exception is NetworkException) {
      return _getNetworkErrorMessage(exception);
    } else if (exception is ValidationException) {
      return _getValidationErrorMessage(exception);
    }

    return exception.message;
  }

  /// Returns user-friendly message for PDF errors
  static String _getPDFErrorMessage(PDFProcessingException exception) {
    switch (exception.code) {
      case 'INVALID_PDF_FORMAT':
        return 'The selected file is not a valid PDF document.';
      case 'CORRUPTED_PDF':
        return 'The PDF file appears to be corrupted or damaged.';
      case 'PDF_LOAD_ERROR':
        return 'Unable to open the PDF file. Please try another file.';
      case 'PDF_SAVE_ERROR':
        return 'Failed to save the PDF file. Please check storage permissions.';
      case 'PDF_PASSWORD_PROTECTED':
        return 'This PDF is password-protected and cannot be opened.';
      case 'PDF_TEXT_EXTRACTION_ERROR':
        return 'Unable to extract text from this PDF. It may contain only images.';
      default:
        return 'An error occurred while processing the PDF: ${exception.message}';
    }
  }

  /// Returns user-friendly message for encoding errors
  static String _getEncodingErrorMessage(EncodingException exception) {
    if (exception.dataLoss) {
      return 'Text encoding issues detected. Some characters may not display correctly.';
    }
    return 'Text encoding error: ${exception.message}';
  }

  /// Returns user-friendly message for file operation errors
  static String _getFileErrorMessage(FileOperationException exception) {
    switch (exception.code) {
      case 'FILE_NOT_FOUND':
        return 'The file could not be found.';
      case 'FILE_ACCESS_DENIED':
        return 'Permission denied. Unable to access the file.';
      case 'FILE_READ_ERROR':
        return 'Failed to read the file. Please try again.';
      case 'FILE_WRITE_ERROR':
        return 'Failed to save the file. Please check storage permissions.';
      default:
        return 'File operation failed: ${exception.message}';
    }
  }

  /// Returns user-friendly message for font errors
  static String _getFontErrorMessage(FontException exception) {
    switch (exception.code) {
      case 'FONT_NOT_FOUND':
        return 'Font not found: ${exception.fontName ?? 'Unknown'}. Using default font.';
      case 'FONT_LOAD_ERROR':
        return 'Failed to load font. Using default font instead.';
      default:
        return 'Font error: ${exception.message}';
    }
  }

  /// Returns user-friendly message for network errors
  static String _getNetworkErrorMessage(NetworkException exception) {
    switch (exception.code) {
      case 'NETWORK_TIMEOUT':
        return 'Network request timed out. Please check your connection.';
      case 'NETWORK_CONNECTION_ERROR':
        return 'Unable to connect to the network. Please check your internet connection.';
      default:
        return 'Network error: ${exception.message}';
    }
  }

  /// Returns user-friendly message for validation errors
  static String _getValidationErrorMessage(ValidationException exception) {
    if (exception.fieldName != null) {
      return '${exception.fieldName}: ${exception.message}';
    }
    return exception.message;
  }

  /// Logs an error without returning a message
  static void logError(dynamic error, {StackTrace? stackTrace}) {
    if (error is AppException) {
      _logger.error(
        error.message,
        error: error.originalError,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else {
      _logger.error(
        'Error occurred',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs a warning
  static void logWarning(String message, {Map<String, dynamic>? data}) {
    _logger.warning(message, data: data);
  }

  /// Logs info
  static void logInfo(String message, {Map<String, dynamic>? data}) {
    _logger.info(message, data: data);
  }

  /// Creates a PDFProcessingException from a generic error
  static PDFProcessingException createPDFException({
    required String message,
    required ErrorCode errorCode,
    String? filePath,
    String? operation,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PDFProcessingException(
      message: message,
      code: errorCode.code,
      filePath: filePath,
      operation: operation,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Creates an EncodingException from a generic error
  static EncodingException createEncodingException({
    required String message,
    required ErrorCode errorCode,
    String? encoding,
    String? operation,
    bool dataLoss = false,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return EncodingException(
      message: message,
      code: errorCode.code,
      encoding: encoding,
      operation: operation,
      dataLoss: dataLoss,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Creates a FileOperationException from a generic error
  static FileOperationException createFileException({
    required String message,
    required ErrorCode errorCode,
    required String operation,
    String? filePath,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return FileOperationException(
      message: message,
      code: errorCode.code,
      operation: operation,
      filePath: filePath,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Creates a FontException from a generic error
  static FontException createFontException({
    required String message,
    required ErrorCode errorCode,
    String? fontName,
    String? fontPath,
    String? operation,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return FontException(
      message: message,
      code: errorCode.code,
      fontName: fontName,
      fontPath: fontPath,
      operation: operation,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}
