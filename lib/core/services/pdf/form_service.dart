import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../logging/app_logger.dart';
import '../../exceptions/app_exceptions.dart';

/// Service for handling PDF form operations
class FormService {
  static final AppLogger _logger = AppLogger('FormService');

  /// Form field data model
  static final Map<String, Map<String, dynamic>> _formDataCache = {};

  /// Get all form fields from a PDF
  static Future<List<PdfFormField>> getFormFields(String pdfPath) async {
    try {
      _logger.info('Getting form fields from PDF', data: {'path': pdfPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Load PDF document
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final formFields = <PdfFormField>[];

      // Check if document has form
      if (document.form == null) {
        _logger.debug('PDF has no form fields');
        document.dispose();
        return formFields;
      }

      // Extract all form fields
      for (int i = 0; i < document.form!.fields.count; i++) {
        final field = document.form!.fields[i];
        formFields.add(PdfFormField(
          name: field.name ?? 'field_$i',
          type: _getFieldType(field),
          value: _getFieldValue(field),
          isRequired: field is PdfField ? (field.required ?? false) : false,
          isReadOnly: field is PdfField ? (field.readOnly ?? false) : false,
          options: _getFieldOptions(field),
          bounds: field.bounds,
          pageIndex: field.page?.pageIndex ?? 0,
        ));
      }

      document.dispose();

      _logger.info('Found ${formFields.length} form fields');
      return formFields;
    } catch (e, stackTrace) {
      _logger.error('Failed to get form fields',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to retrieve form fields',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fill form field with value
  static Future<void> fillFormField(
    String pdfPath,
    String fieldName,
    dynamic value,
  ) async {
    try {
      _logger.info('Filling form field',
          data: {'path': pdfPath, 'field': fieldName, 'value': value});

      // Update cache
      if (!_formDataCache.containsKey(pdfPath)) {
        _formDataCache[pdfPath] = {};
      }
      _formDataCache[pdfPath]![fieldName] = value;

      _logger.debug('Form field value cached');
    } catch (e, stackTrace) {
      _logger.error('Failed to fill form field',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to fill form field',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save filled form to new PDF
  static Future<String> saveFilledForm(
    String pdfPath,
    String outputPath,
  ) async {
    try {
      _logger.info('Saving filled form',
          data: {'input': pdfPath, 'output': outputPath});

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw FileOperationException('PDF file not found: $pdfPath');
      }

      // Load PDF document
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      if (document.form == null) {
        throw PDFProcessingException('PDF has no form');
      }

      // Get cached form data
      final formData = _formDataCache[pdfPath] ?? {};

      // Fill all cached field values
      for (int i = 0; i < document.form!.fields.count; i++) {
        final field = document.form!.fields[i];
        final fieldName = field.name ?? 'field_$i';

        if (formData.containsKey(fieldName)) {
          _setFieldValue(field, formData[fieldName]);
        }
      }

      // Flatten form (make fields non-editable)
      document.form!.flattenAllFields();

      // Save document
      final outputBytes = await document.save();
      document.dispose();

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.info('Filled form saved successfully');
      return outputPath;
    } catch (e, stackTrace) {
      _logger.error('Failed to save filled form',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to save filled form',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Auto-fill form with AI-extracted data
  static Future<void> autoFillForm(
    String pdfPath,
    Map<String, dynamic> extractedData,
  ) async {
    try {
      _logger.info('Auto-filling form with extracted data',
          data: {'path': pdfPath, 'dataKeys': extractedData.keys.toList()});

      final formFields = await getFormFields(pdfPath);

      for (final field in formFields) {
        // Try to match field name with extracted data
        final matchedKey = _findMatchingKey(field.name, extractedData.keys);

        if (matchedKey != null) {
          await fillFormField(pdfPath, field.name, extractedData[matchedKey]);
          _logger.debug('Auto-filled field: ${field.name}');
        }
      }

      _logger.info('Auto-fill completed');
    } catch (e, stackTrace) {
      _logger.error('Failed to auto-fill form',
          error: e, stackTrace: stackTrace);
      throw PDFProcessingException(
        'Failed to auto-fill form',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Validate form data
  static Future<List<String>> validateForm(String pdfPath) async {
    try {
      final formFields = await getFormFields(pdfPath);
      final formData = _formDataCache[pdfPath] ?? {};
      final errors = <String>[];

      for (final field in formFields) {
        if (field.isRequired && !formData.containsKey(field.name)) {
          errors.add('Required field "${field.name}" is empty');
        }
      }

      return errors;
    } catch (e, stackTrace) {
      _logger.error('Failed to validate form',
          error: e, stackTrace: stackTrace);
      return ['Validation failed: ${e.toString()}'];
    }
  }

  /// Clear form data cache
  static void clearFormData(String pdfPath) {
    _formDataCache.remove(pdfPath);
    _logger.debug('Form data cache cleared');
  }

  /// Get cached form data
  static Map<String, dynamic>? getFormData(String pdfPath) {
    return _formDataCache[pdfPath];
  }

  // ======================
  // Private Methods
  // ======================

  /// Get field type
  static PdfFieldType _getFieldType(dynamic field) {
    if (field is PdfTextBoxField) {
      return PdfFieldType.text;
    } else if (field is PdfCheckBoxField) {
      return PdfFieldType.checkbox;
    } else if (field is PdfRadioButtonListField) {
      return PdfFieldType.radio;
    } else if (field is PdfComboBoxField) {
      return PdfFieldType.dropdown;
    } else if (field is PdfListBoxField) {
      return PdfFieldType.listbox;
    } else if (field is PdfSignatureField) {
      return PdfFieldType.signature;
    } else {
      return PdfFieldType.unknown;
    }
  }

  /// Get field value
  static dynamic _getFieldValue(dynamic field) {
    try {
      if (field is PdfTextBoxField) {
        return field.text;
      } else if (field is PdfCheckBoxField) {
        return field.isChecked;
      } else if (field is PdfComboBoxField) {
        return field.selectedValue;
      } else if (field is PdfListBoxField) {
        return field.selectedValues;
      } else if (field is PdfRadioButtonListField) {
        return field.selectedValue;
      }
      return null;
    } catch (e) {
      _logger.warning('Failed to get field value', data: {'error': e});
      return null;
    }
  }

  /// Set field value
  static void _setFieldValue(dynamic field, dynamic value) {
    try {
      if (field is PdfTextBoxField && value is String) {
        field.text = value;
      } else if (field is PdfCheckBoxField && value is bool) {
        field.isChecked = value;
      } else if (field is PdfComboBoxField && value is String) {
        field.selectedValue = value;
      } else if (field is PdfListBoxField && value is List<int>) {
        field.selectedValues = value;
      } else if (field is PdfRadioButtonListField && value is int) {
        field.selectedValue = value;
      }
    } catch (e) {
      _logger.warning('Failed to set field value', data: {'error': e});
    }
  }

  /// Get field options (for dropdown/listbox)
  static List<String>? _getFieldOptions(dynamic field) {
    try {
      if (field is PdfComboBoxField) {
        final options = <String>[];
        for (int i = 0; i < field.items.count; i++) {
          options.add(field.items[i].text);
        }
        return options;
      } else if (field is PdfListBoxField) {
        final options = <String>[];
        for (int i = 0; i < field.items.count; i++) {
          options.add(field.items[i].text);
        }
        return options;
      }
      return null;
    } catch (e) {
      _logger.warning('Failed to get field options', data: {'error': e});
      return null;
    }
  }

  /// Find matching key in extracted data
  static String? _findMatchingKey(
    String fieldName,
    Iterable<String> dataKeys,
  ) {
    final normalizedFieldName = fieldName.toLowerCase().replaceAll('_', ' ');

    // Exact match
    for (final key in dataKeys) {
      if (key.toLowerCase() == normalizedFieldName) {
        return key;
      }
    }

    // Partial match
    for (final key in dataKeys) {
      final normalizedKey = key.toLowerCase().replaceAll('_', ' ');
      if (normalizedFieldName.contains(normalizedKey) ||
          normalizedKey.contains(normalizedFieldName)) {
        return key;
      }
    }

    return null;
  }
}

/// PDF Form Field model
class PdfFormField {
  final String name;
  final PdfFieldType type;
  final dynamic value;
  final bool isRequired;
  final bool isReadOnly;
  final List<String>? options;
  final dynamic bounds;
  final int pageIndex;

  const PdfFormField({
    required this.name,
    required this.type,
    this.value,
    this.isRequired = false,
    this.isReadOnly = false,
    this.options,
    this.bounds,
    this.pageIndex = 0,
  });

  @override
  String toString() {
    return 'PdfFormField(name: $name, type: $type, value: $value, '
        'required: $isRequired, readOnly: $isReadOnly)';
  }
}

/// PDF Field Type
enum PdfFieldType {
  text,
  checkbox,
  radio,
  dropdown,
  listbox,
  signature,
  unknown,
}
