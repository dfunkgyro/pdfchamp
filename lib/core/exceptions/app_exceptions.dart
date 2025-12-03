/// Base exception class for all application-specific exceptions
abstract class AppException implements Exception {
  /// Human-readable error message
  final String message;

  /// Original error that caused this exception (if any)
  final dynamic originalError;

  /// Stack trace when the exception was created
  final StackTrace? stackTrace;

  /// Error code for categorization
  final String code;

  const AppException({
    required this.message,
    required this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message (code: $code)');
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when PDF processing fails
class PDFProcessingException extends AppException {
  final String? filePath;
  final String? operation;

  const PDFProcessingException({
    required super.message,
    required super.code,
    this.filePath,
    this.operation,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (filePath != null) buffer.write('\nFile: $filePath');
    if (operation != null) buffer.write('\nOperation: $operation');
    return buffer.toString();
  }
}

/// Exception thrown when encoding/decoding operations fail
class EncodingException extends AppException {
  final String? encoding;
  final String? operation;
  final bool dataLoss;

  const EncodingException({
    required super.message,
    required super.code,
    this.encoding,
    this.operation,
    this.dataLoss = false,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (encoding != null) buffer.write('\nEncoding: $encoding');
    if (operation != null) buffer.write('\nOperation: $operation');
    if (dataLoss) buffer.write('\nWarning: Data loss may have occurred');
    return buffer.toString();
  }
}

/// Exception thrown when file operations fail
class FileOperationException extends AppException {
  final String? filePath;
  final String operation;

  const FileOperationException({
    required super.message,
    required super.code,
    required this.operation,
    this.filePath,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (filePath != null) buffer.write('\nFile: $filePath');
    buffer.write('\nOperation: $operation');
    return buffer.toString();
  }
}

/// Exception thrown when font loading or management fails
class FontException extends AppException {
  final String? fontName;
  final String? fontPath;
  final String? operation;

  const FontException({
    required super.message,
    required super.code,
    this.fontName,
    this.fontPath,
    this.operation,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (fontName != null) buffer.write('\nFont: $fontName');
    if (fontPath != null) buffer.write('\nPath: $fontPath');
    if (operation != null) buffer.write('\nOperation: $operation');
    return buffer.toString();
  }
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  final String? url;
  final int? statusCode;

  const NetworkException({
    required super.message,
    required super.code,
    this.url,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (url != null) buffer.write('\nURL: $url');
    if (statusCode != null) buffer.write('\nStatus Code: $statusCode');
    return buffer.toString();
  }
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  final String? fieldName;
  final dynamic invalidValue;

  const ValidationException({
    required super.message,
    required super.code,
    this.fieldName,
    this.invalidValue,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(super.toString());
    if (fieldName != null) buffer.write('\nField: $fieldName');
    if (invalidValue != null) buffer.write('\nInvalid Value: $invalidValue');
    return buffer.toString();
  }
}
