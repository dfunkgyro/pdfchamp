/// Error codes for categorizing different types of errors in the application
enum ErrorCode {
  // File Operation Errors (1000-1099)
  fileNotFound('FILE_NOT_FOUND', 1001, 'File not found'),
  fileReadError('FILE_READ_ERROR', 1002, 'Failed to read file'),
  fileWriteError('FILE_WRITE_ERROR', 1003, 'Failed to write file'),
  fileAccessDenied('FILE_ACCESS_DENIED', 1004, 'Access denied to file'),
  fileAlreadyExists('FILE_ALREADY_EXISTS', 1005, 'File already exists'),
  invalidFilePath('INVALID_FILE_PATH', 1006, 'Invalid file path'),

  // PDF Processing Errors (1100-1199)
  invalidPdfFormat('INVALID_PDF_FORMAT', 1101, 'Invalid PDF format'),
  corruptedPdf('CORRUPTED_PDF', 1102, 'PDF file is corrupted'),
  pdfLoadError('PDF_LOAD_ERROR', 1103, 'Failed to load PDF'),
  pdfSaveError('PDF_SAVE_ERROR', 1104, 'Failed to save PDF'),
  pdfTextExtractionError('PDF_TEXT_EXTRACTION_ERROR', 1105, 'Failed to extract text from PDF'),
  pdfEditError('PDF_EDIT_ERROR', 1106, 'Failed to edit PDF'),
  pdfPageNotFound('PDF_PAGE_NOT_FOUND', 1107, 'PDF page not found'),
  pdfPasswordProtected('PDF_PASSWORD_PROTECTED', 1108, 'PDF is password protected'),
  pdfPermissionDenied('PDF_PERMISSION_DENIED', 1109, 'PDF permissions denied'),

  // Encoding Errors (1200-1299)
  encodingDetectionFailed('ENCODING_DETECTION_FAILED', 1201, 'Failed to detect encoding'),
  encodingConversionFailed('ENCODING_CONVERSION_FAILED', 1202, 'Failed to convert encoding'),
  unsupportedEncoding('UNSUPPORTED_ENCODING', 1203, 'Unsupported encoding'),
  malformedData('MALFORMED_DATA', 1204, 'Malformed data'),
  encodingDataLoss('ENCODING_DATA_LOSS', 1205, 'Data loss during encoding conversion'),
  invalidUtf8('INVALID_UTF8', 1206, 'Invalid UTF-8 data'),
  invalidUtf16('INVALID_UTF16', 1207, 'Invalid UTF-16 data'),

  // Font Errors (1300-1399)
  fontNotFound('FONT_NOT_FOUND', 1301, 'Font not found'),
  fontLoadError('FONT_LOAD_ERROR', 1302, 'Failed to load font'),
  fontParseError('FONT_PARSE_ERROR', 1303, 'Failed to parse font'),
  fontExtractionError('FONT_EXTRACTION_ERROR', 1304, 'Failed to extract font information'),
  googleFontsError('GOOGLE_FONTS_ERROR', 1305, 'Google Fonts loading error'),
  systemFontsError('SYSTEM_FONTS_ERROR', 1306, 'System fonts loading error'),

  // Network Errors (1400-1499)
  networkTimeout('NETWORK_TIMEOUT', 1401, 'Network timeout'),
  networkConnectionError('NETWORK_CONNECTION_ERROR', 1402, 'Network connection error'),
  networkRequestFailed('NETWORK_REQUEST_FAILED', 1403, 'Network request failed'),
  httpError('HTTP_ERROR', 1404, 'HTTP error'),

  // Validation Errors (1500-1599)
  invalidInput('INVALID_INPUT', 1501, 'Invalid input'),
  missingRequiredField('MISSING_REQUIRED_FIELD', 1502, 'Missing required field'),
  invalidFormat('INVALID_FORMAT', 1503, 'Invalid format'),
  outOfRange('OUT_OF_RANGE', 1504, 'Value out of range'),

  // System Errors (1600-1699)
  insufficientMemory('INSUFFICIENT_MEMORY', 1601, 'Insufficient memory'),
  platformError('PLATFORM_ERROR', 1602, 'Platform-specific error'),
  permissionDenied('PERMISSION_DENIED', 1603, 'Permission denied'),
  resourceUnavailable('RESOURCE_UNAVAILABLE', 1604, 'Resource unavailable'),

  // Unknown/Generic Errors (1900-1999)
  unknownError('UNKNOWN_ERROR', 1999, 'Unknown error occurred');

  /// String identifier for the error code
  final String code;

  /// Numeric error code
  final int numericCode;

  /// Default error message
  final String defaultMessage;

  const ErrorCode(this.code, this.numericCode, this.defaultMessage);

  @override
  String toString() => code;

  /// Get error severity level
  ErrorSeverity get severity {
    if (numericCode >= 1900) return ErrorSeverity.critical;
    if (numericCode >= 1600) return ErrorSeverity.high;
    if (numericCode >= 1500) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }
}

/// Severity levels for errors
enum ErrorSeverity {
  low('Low', 1),
  medium('Medium', 2),
  high('High', 3),
  critical('Critical', 4);

  final String label;
  final int level;

  const ErrorSeverity(this.label, this.level);

  @override
  String toString() => label;
}
