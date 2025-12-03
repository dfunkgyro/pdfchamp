// lib/services/text_encoding_handler.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_charset_detector/universal_charset_detector.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/foundation.dart';

/// Handles text encoding conversion for PDF files
/// Supports various PDF-specific encodings and character sets
class TextEncodingHandler {
  // PDF-specific encoding mappings
  static final Map<String, String> _pdfEncodingMap = {
    // Standard PDF encodings
    'WinAnsiEncoding': 'windows-1252',
    'MacRomanEncoding': 'macintosh',
    'StandardEncoding': 'us-ascii',
    'PDFDocEncoding': 'pdfdoc',
    'Identity-H': 'utf-8',
    'Identity-V': 'utf-8',
    
    // Additional common encodings
    'ISO-8859-1': 'latin1',
    'ISO-8859-2': 'latin2',
    'ISO-8859-5': 'latin5',
    'ISO-8859-7': 'latin7',
    'ISO-8859-9': 'latin9',
    'ISO-8859-15': 'latin9',
    
    // Unicode variants
    'UTF-8': 'utf-8',
    'UTF-16': 'utf-16',
    'UTF-16BE': 'utf-16be',
    'UTF-16LE': 'utf-16le',
    'UTF-32': 'utf-32',
    
    // Windows code pages
    'CP1250': 'windows-1250',  // Central European
    'CP1251': 'windows-1251',  // Cyrillic
    'CP1252': 'windows-1252',  // Western European
    'CP1253': 'windows-1253',  // Greek
    'CP1254': 'windows-1254',  // Turkish
    'CP1255': 'windows-1255',  // Hebrew
    'CP1256': 'windows-1256',  // Arabic
    'CP1257': 'windows-1257',  // Baltic
    'CP1258': 'windows-1258',  // Vietnamese
    
    // Asian encodings
    'Shift_JIS': 'shift_jis',
    'EUC-JP': 'euc-jp',
    'ISO-2022-JP': 'iso-2022-jp',
    'GB2312': 'gb2312',
    'GBK': 'gbk',
    'GB18030': 'gb18030',
    'Big5': 'big5',
    'EUC-KR': 'euc-kr',
    'ISO-2022-KR': 'iso-2022-kr',
    
    // Others
    'KOI8-R': 'koi8-r',
    'KOI8-U': 'koi8-u',
    'IBM866': 'ibm866',
  };

  /// Detect encoding from byte data
  static Future<DetectedEncoding> detectEncoding(Uint8List bytes) async {
    try {
      final detector = UniversalCharsetDetector();
      final detected = await detector.detect(bytes);
      
      return DetectedEncoding(
        name: detected.name,
        confidence: detected.confidence,
      );
    } catch (e) {
      // Fallback: try to guess encoding from BOM
      return _guessEncodingFromBOM(bytes);
    }
  }

  /// Convert bytes to UTF-8 string with automatic encoding detection
  static Future<String> bytesToUtf8(Uint8List bytes) async {
    try {
      // Try to detect encoding
      final detected = await detectEncoding(bytes);
      final encodingName = detected.name.toLowerCase();
      
      // Handle UTF encodings
      if (encodingName.contains('utf-8') || 
          encodingName.contains('utf8') ||
          encodingName == 'ascii') {
        return utf8.decode(bytes, allowMalformed: true);
      }
      
      if (encodingName.contains('utf-16')) {
        return _decodeUtf16(bytes, encodingName);
      }
      
      if (encodingName.contains('utf-32')) {
        return _decodeUtf32(bytes);
      }
      
      // Convert using charset_converter
      final result = await CharsetConverter.decode(bytes, detected.name);
      if (result != null) {
        return result;
      }
      
      // Fallback to latin1
      return latin1.decode(bytes, allowInvalid: true);
    } catch (e) {
      // Final fallback
      return _safeDecode(bytes);
    }
  }

  /// Convert PDF-specific encoded text to UTF-8
  static Future<String> convertPdfTextToUtf8(
    String text, 
    String pdfEncoding,
  ) async {
    if (pdfEncoding.isEmpty) {
      return text;
    }
    
    final normalizedEncoding = _normalizeEncodingName(pdfEncoding);
    
    // If already UTF-8, return as is
    if (normalizedEncoding.contains('utf-8')) {
      return text;
    }
    
    try {
      // Convert to bytes using the source encoding
      final bytes = await CharsetConverter.encode(normalizedEncoding, text);
      if (bytes == null) {
        return text;
      }
      
      // Decode as UTF-8
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      // Try fallback conversion
      return _convertWithFallback(text, normalizedEncoding);
    }
  }

  /// Convert PDF bytes with known encoding to string
  static Future<String> decodePdfBytes(
    Uint8List bytes, 
    String pdfEncoding,
  ) async {
    final encodingName = _normalizeEncodingName(pdfEncoding);
    
    try {
      if (encodingName.contains('utf-8')) {
        return utf8.decode(bytes, allowMalformed: true);
      }
      
      if (encodingName.contains('utf-16')) {
        return _decodeUtf16(bytes, encodingName);
      }
      
      // Use charset_converter for other encodings
      final result = await CharsetConverter.decode(bytes, encodingName);
      if (result != null) {
        return result;
      }
      
      // Fallback: try to auto-detect
      return await bytesToUtf8(bytes);
    } catch (e) {
      return _safeDecode(bytes);
    }
  }

  /// Normalize text (NFKC normalization)
  static String normalizeText(String text) {
    try {
      return text.normalize();
    } catch (e) {
      return text;
    }
  }

  /// Check if text contains RTL (right-to-left) characters
  static bool isRTL(String text) {
    if (text.isEmpty) return false;
    
    final rtlRanges = [
      (0x0590, 0x05FF), // Hebrew
      (0x0600, 0x06FF), // Arabic
      (0x0700, 0x074F), // Syriac
      (0x0750, 0x077F), // Arabic Supplement
      (0x08A0, 0x08FF), // Arabic Extended-A
      (0xFB50, 0xFDFF), // Arabic Presentation Forms-A
      (0xFE70, 0xFEFF), // Arabic Presentation Forms-B
      (0x10A00, 0x10A5F), // Kharoshthi
      (0x10A60, 0x10A7F), // Old South Arabian
      (0x10B00, 0x10B3F), // Avestan
      (0x10B40, 0x10B5F), // Inscriptional Parthian
      (0x10B60, 0x10B7F), // Inscriptional Pahlavi
    ];
    
    // Check first few characters for RTL
    final sample = text.length > 100 ? text.substring(0, 100) : text;
    
    for (final char in sample.runes) {
      for (final range in rtlRanges) {
        if (char >= range.$1 && char <= range.$2) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Check if text contains complex scripts
  static bool hasComplexScript(String text) {
    final complexScriptRanges = [
      (0x0300, 0x036F), // Combining Diacritical Marks
      (0x1AB0, 0x1AFF), // Combining Diacritical Marks Extended
      (0x1DC0, 0x1DFF), // Combining Diacritical Marks Supplement
      (0x20D0, 0x20FF), // Combining Diacritical Marks for Symbols
      (0xFE20, 0xFE2F), // Combining Half Marks
    ];
    
    for (final char in text.runes) {
      for (final range in complexScriptRanges) {
        if (char >= range.$1 && char <= range.$2) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Get all supported encodings
  static List<String> getSupportedEncodings() {
    return _pdfEncodingMap.keys.toList()..sort();
  }

  /// Get encoding by PDF name
  static String? getEncodingForPdfName(String pdfName) {
    return _pdfEncodingMap[pdfName];
  }

  // Private helper methods

  static String _normalizeEncodingName(String encoding) {
    final normalized = encoding.trim();
    
    // Check direct mapping
    if (_pdfEncodingMap.containsKey(normalized)) {
      return _pdfEncodingMap[normalized]!;
    }
    
    // Check case-insensitive
    final lower = normalized.toLowerCase();
    for (final entry in _pdfEncodingMap.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }
    
    // Default to UTF-8
    return 'utf-8';
  }

  static DetectedEncoding _guessEncodingFromBOM(Uint8List bytes) {
    if (bytes.length >= 3) {
      // Check for UTF-8 BOM
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return DetectedEncoding(name: 'UTF-8', confidence: 0.95);
      }
      
      // Check for UTF-16 BE BOM
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return DetectedEncoding(name: 'UTF-16BE', confidence: 0.95);
      }
      
      // Check for UTF-16 LE BOM
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return DetectedEncoding(name: 'UTF-16LE', confidence: 0.95);
      }
    }
    
    if (bytes.length >= 4) {
      // Check for UTF-32 BE BOM
      if (bytes[0] == 0x00 && 
          bytes[1] == 0x00 && 
          bytes[2] == 0xFE && 
          bytes[3] == 0xFF) {
        return DetectedEncoding(name: 'UTF-32BE', confidence: 0.95);
      }
      
      // Check for UTF-32 LE BOM
      if (bytes[0] == 0xFF && 
          bytes[1] == 0xFE && 
          bytes[2] == 0x00 && 
          bytes[3] == 0x00) {
        return DetectedEncoding(name: 'UTF-32LE', confidence: 0.95);
      }
    }
    
    // Default to UTF-8 with low confidence
    return DetectedEncoding(name: 'UTF-8', confidence: 0.3);
  }

  static String _decodeUtf16(Uint8List bytes, String encodingName) {
    try {
      if (encodingName.contains('be') || encodingName.contains('BE')) {
        return utf16be.decode(bytes, allowMalformed: true);
      } else if (encodingName.contains('le') || encodingName.contains('LE')) {
        return utf16le.decode(bytes, allowMalformed: true);
      } else {
        // Try both endianness
        try {
          return utf16.decode(bytes, allowMalformed: true);
        } catch (e) {
          return utf16be.decode(bytes, allowMalformed: true);
        }
      }
    } catch (e) {
      return _safeDecode(bytes);
    }
  }

  static String _decodeUtf32(Uint8List bytes) {
    try {
      // Dart doesn't have built-in UTF-32 decoder
      // Convert to UTF-16 first
      final utf16Bytes = _convertUtf32ToUtf16(bytes);
      return utf16.decode(utf16Bytes, allowMalformed: true);
    } catch (e) {
      return _safeDecode(bytes);
    }
  }

  static Uint8List _convertUtf32ToUtf16(Uint8List utf32Bytes) {
    final result = <int>[];
    final length = utf32Bytes.length;
    
    for (int i = 0; i < length; i += 4) {
      if (i + 3 >= length) break;
      
      final byte1 = utf32Bytes[i];
      final byte2 = utf32Bytes[i + 1];
      final byte3 = utf32Bytes[i + 2];
      final byte4 = utf32Bytes[i + 3];
      
      // Assuming little-endian
      final codePoint = (byte4 << 24) | (byte3 << 16) | (byte2 << 8) | byte1;
      
      if (codePoint <= 0xFFFF) {
        result.add(codePoint & 0xFF);
        result.add((codePoint >> 8) & 0xFF);
      } else {
        // Surrogate pair for code points > 0xFFFF
        final high = ((codePoint - 0x10000) >> 10) + 0xD800;
        final low = ((codePoint - 0x10000) & 0x3FF) + 0xDC00;
        
        result.add(high & 0xFF);
        result.add((high >> 8) & 0xFF);
        result.add(low & 0xFF);
        result.add((low >> 8) & 0xFF);
      }
    }
    
    return Uint8List.fromList(result);
  }

  static String _convertWithFallback(String text, String encoding) {
    // Try common fallback encodings
    final fallbackEncodings = [
      'windows-1252',
      'latin1',
      'utf-8',
    ];
    
    for (final fallback in fallbackEncodings) {
      try {
        final bytes = latin1.encode(text);
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        continue;
      }
    }
    
    return text;
  }

  static String _safeDecode(Uint8List bytes) {
    try {
      // Try UTF-8 first
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      try {
        // Try latin1
        return latin1.decode(bytes, allowInvalid: true);
      } catch (_) {
        // Last resort: use replacement characters
        return String.fromCharCodes(
          bytes.map((b) => b < 32 || b > 126 ? 0xFFFD : b),
        );
      }
    }
  }

  /// Fix common encoding issues in PDF text
  static String fixCommonEncodingIssues(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // Fix common mojibake patterns
    final fixes = {
      'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú',
      'Ã±': 'ñ', 'Ã': 'Á', 'Ã‰': 'É', 'Ã': 'Í', 'Ã“': 'Ó',
      'Ãš': 'Ú', 'Ã‘': 'Ñ', 'Ã£': 'ã', 'Ãµ': 'õ', 'Ã§': 'ç',
      'Ã€': 'À', 'Ãˆ': 'È', 'ÃŒ': 'Ì', 'Ã’': 'Ò', 'Ã™': 'Ù',
      'Ã¤': 'ä', 'Ã«': 'ë', 'Ã¯': 'ï', 'Ã¶': 'ö', 'Ã¼': 'ü',
      'Ã„': 'Ä', 'Ã‹': 'Ë', 'Ã': 'Ï', 'Ã–': 'Ö', 'Ãœ': 'Ü',
      'Â€': '€', 'Â£': '£', 'Â¥': '¥', 'Â©': '©', 'Â®': '®',
      'Â°': '°', 'Â±': '±', 'Â²': '²', 'Â³': '³', 'Âµ': 'µ',
      'Â·': '·', 'Â¼': '¼', 'Â½': '½', 'Â¾': '¾',
    };
    
    for (final entry in fixes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    // Remove null characters
    result = result.replaceAll('\x00', '');
    
    // Normalize line endings
    result = result.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Remove BOM if present
    if (result.startsWith('\uFEFF')) {
      result = result.substring(1);
    }
    
    return result;
  }
}

/// Represents detected encoding with confidence
class DetectedEncoding {
  final String name;
  final double confidence;
  
  DetectedEncoding({
    required this.name,
    this.confidence = 1.0,
  });
  
  @override
  String toString() {
    return '$name (${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Extension method for String normalization
extension StringNormalization on String {
  String normalize([String form = 'NFC']) {
    // Simplified normalization - in production, use a proper Unicode library
    return this;
  }
}

/// Utility class for PDF font encoding
class PDFFontEncoding {
  static bool isSymbolFont(String fontName) {
    return fontName.contains('Symbol') || fontName.contains('ZapfDingbats');
  }
  
  static String getSymbolFontReplacement(String symbolChar) {
    // Map common symbol characters to their Unicode equivalents
    final symbolMap = {
      '✐': '✐', '✑': '✑', '✒': '✒', '✓': '✓', '✔': '✔',
      '✕': '✕', '✖': '✖', '✗': '✗', '✘': '✘', '✙': '✙',
      '✚': '✚', '✛': '✛', '✜': '✜', '✝': '✝', '✞': '✞',
      '✟': '✟', '✠': '✠', '✡': '✡', '✢': '✢', '✣': '✣',
      '✤': '✤', '✥': '✥', '✦': '✦', '✧': '✧', '✨': '✨',
      '✩': '✩', '✪': '✪', '✫': '✫', '✬': '✬', '✭': '✭',
      '✮': '✮', '✯': '✯', '✰': '✰', '✱': '✱', '✲': '✲',
      '✳': '✳', '✴': '✴', '✵': '✵', '✶': '✶', '✷': '✷',
      '✸': '✸', '✹': '✹', '✺': '✺', '✻': '✻', '✼': '✼',
      '✽': '✽', '✾': '✾', '✿': '✿', '❀': '❀', '❁': '❁',
      '❂': '❂', '❃': '❃', '❄': '❄', '❅': '❅', '❆': '❆',
      '❇': '❇', '❈': '❈', '❉': '❉', '❊': '❊', '❋': '❋',
    };
    
    return symbolMap[symbolChar] ?? symbolChar;
  }
}