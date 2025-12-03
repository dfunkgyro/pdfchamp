// lib/utils/encoding_utils.dart
import 'dart:convert';

/// Utility functions for character encoding operations
class EncodingUtils {
  /// Check if bytes are valid UTF-8
  static bool isValidUtf8(List<int> bytes) {
    try {
      utf8.decode(bytes, allowMalformed: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get the most likely encoding based on byte patterns
  static String guessEncodingFromBytes(List<int> bytes) {
    if (bytes.isEmpty) return 'utf-8';
    
    // Check for BOM
    if (bytes.length >= 3) {
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return 'utf-8';
      }
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return 'utf-16be';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return 'utf-16le';
      }
    }
    
    // Analyze byte patterns
    final asciiCount = bytes.where((b) => b < 128).length;
    final asciiRatio = asciiCount / bytes.length;
    
    if (asciiRatio > 0.95) {
      return 'ascii';
    }
    
    // Check for common Windows-1252 patterns
    final windows1252Patterns = [0x80, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87];
    final hasWindows1252 = bytes.any((b) => windows1252Patterns.contains(b));
    
    if (hasWindows1252 && asciiRatio > 0.7) {
      return 'windows-1252';
    }
    
    // Default to UTF-8
    return 'utf-8';
  }

  /// Convert encoding name to standard format
  static String normalizeEncodingName(String encoding) {
    final normalized = encoding.toLowerCase().trim();
    
    final mapping = {
      'utf8': 'utf-8',
      'utf16': 'utf-16',
      'utf32': 'utf-32',
      'ascii': 'us-ascii',
      'latin1': 'iso-8859-1',
      'latin2': 'iso-8859-2',
      'latin5': 'iso-8859-5',
      'latin9': 'iso-8859-15',
      'cp1250': 'windows-1250',
      'cp1251': 'windows-1251',
      'cp1252': 'windows-1252',
      'win1252': 'windows-1252',
      'mac': 'macintosh',
      'macroman': 'macintosh',
    };
    
    return mapping[normalized] ?? normalized;
  }

  /// Remove BOM from string
  static String removeBom(String text) {
    if (text.startsWith('\uFEFF')) {
      return text.substring(1);
    }
    return text;
  }

  /// Sanitize text for PDF output
  static String sanitizeForPdf(String text) {
    // Replace problematic characters
    return text.replaceAllMapped(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      (match) => '',
    );
  }
}