// lib/widgets/text_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf_editor_macos/models/pdf_font.dart';
import 'package:pdf_editor_macos/services/font_manager.dart';

class TextEditorDialog extends StatefulWidget {
  final String initialText;
  final PDFFont? initialFont;
  final Function(String, PDFFont) onSave;

  const TextEditorDialog({
    super.key,
    required this.initialText,
    this.initialFont,
    required this.onSave,
  });

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  final TextEditingController _textController = TextEditingController();
  late PDFFont _currentFont;
  final FontManager _fontManager = FontManager();
  List<String> _availableFonts = [];
  bool _isLoadingFonts = true;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.initialText;
    _currentFont = widget.initialFont ?? PDFFont(
      name: 'Helvetica',
      family: 'Helvetica',
      size: 12,
      color: const PdfColor(0, 0, 0),
    );
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    setState(() => _isLoadingFonts = true);
    await _fontManager.initialize();
    _availableFonts = _fontManager.getAvailableFonts();
    setState(() => _isLoadingFonts = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_fields),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Text with Font Styling',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Font controls sidebar
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildFontControls(),
                  ),
                  // Text editor area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Preview
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: _buildTextPreview(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Text input
                          TextField(
                            controller: _textController,
                            maxLines: 5,
                            minLines: 3,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Enter text',
                              hintText: 'Type your text here...',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _textController.clear(),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onSave(_textController.text, _currentFont);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontControls() {
    if (_isLoadingFonts) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        // Font family
        _buildFontFamilySelector(),
        const SizedBox(height: 16),
        // Font size
        _buildFontSizeSelector(),
        const SizedBox(height: 16),
        // Font weight
        _buildFontWeightSelector(),
        const SizedBox(height: 16),
        // Font style
        _buildFontStyleSelector(),
        const SizedBox(height: 16),
        // Color picker
        _buildColorPicker(),
        const SizedBox(height: 16),
        // Text decoration
        _buildTextDecoration(),
        const SizedBox(height: 16),
        // Letter spacing
        _buildLetterSpacing(),
        const SizedBox(height: 16),
        // Line height
        _buildLineHeight(),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Family',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _currentFont.family,
          items: _availableFonts.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: _getFlutterFontFamily(font),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              final newFont = await _fontManager.getFontForEditing(
                fontName: value,
                weight: _currentFont.weight,
                style: _currentFont.style,
              );
              if (newFont != null) {
                setState(() {
                  _currentFont = newFont.copyWith(size: _currentFont.size);
                });
              }
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  String? _getFlutterFontFamily(String pdfFontName) {
    // Map PDF font names to Flutter font families
    final fontMap = {
      'Helvetica': null, // System default
      'Times-Roman': 'Times New Roman',
      'Courier': 'Courier New',
      'Arial': 'Arial',
      'Roboto': 'Roboto',
    };
    return fontMap[pdfFontName];
  }

  Widget _buildFontSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentFont.size,
                min: 6,
                max: 72,
                divisions: 66,
                label: '${_currentFont.size.round()} pt',
                onChanged: (value) {
                  setState(() {
                    _currentFont = _currentFont.copyWith(size: value);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              child: TextField(
                controller: TextEditingController(text: _currentFont.size.toStringAsFixed(1)),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'pt',
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                onChanged: (value) {
                  final size = double.tryParse(value);
                  if (size != null && size >= 6 && size <= 72) {
                    setState(() {
                      _currentFont = _currentFont.copyWith(size: size);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontWeightSelector() {
    final weights = _fontManager.getFontWeights(_currentFont.family);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Weight',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weights.entries.map((entry) {
            final isSelected = _currentFont.weight == entry.key;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFont = _currentFont.copyWith(weight: entry.key);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Style',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Normal'),
              selected: _currentFont.style == FontStyle.normal,
              onSelected: (selected) {
                setState(() {
                  _currentFont = _currentFont.copyWith(style: FontStyle.normal);
                });
              },
            ),
            FilterChip(
              label: const Text('Italic'),
              selected: _currentFont.style == FontStyle.italic,
              onSelected: (selected) {
                setState(() {
                  _currentFont = _currentFont.copyWith(style: FontStyle.italic);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Color',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = _currentFont.color.flutterColor.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentFont = _currentFont.copyWith(
                    color: PdfColor(
                      color.red,
                      color.green,
                      color.blue,
                      color.opacity,
                    ),
                  );
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _currentFont.color.a,
                min: 0,
                max: 1,
                divisions: 10,
                label: 'Opacity: ${(_currentFont.color.a * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    _currentFont = _currentFont.copyWith(
                      color: PdfColor(
                        _currentFont.color.r,
                        _currentFont.color.g,
                        _currentFont.color.b,
                        value,
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextDecoration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Decoration',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Underline'),
              selected: _currentFont.decoration.contains(TextDecoration.underline),
              onSelected: (selected) {
                setState(() {
                  final decoration = selected
                      ? _currentFont.decoration.union(TextDecoration.underline)
                      : _currentFont.decoration.difference(TextDecoration.underline);
                  _currentFont = _currentFont.copyWith(decoration: decoration);
                });
              },
            ),
            FilterChip(
              label: const Text('Strikethrough'),
              selected: _currentFont.decoration.contains(TextDecoration.lineThrough),
              onSelected: (selected) {
                setState(() {
                  final decoration = selected
                      ? _currentFont.decoration.union(TextDecoration.lineThrough)
                      : _currentFont.decoration.difference(TextDecoration.lineThrough);
                  _currentFont = _currentFont.copyWith(decoration: decoration);
                });
              },
            ),
            FilterChip(
              label: const Text('Overline'),
              selected: _currentFont.decoration.contains(TextDecoration.overline),
              onSelected: (selected) {
                setState(() {
                  final decoration = selected
                      ? _currentFont.decoration.union(TextDecoration.overline)
                      : _currentFont.decoration.difference(TextDecoration.overline);
                  _currentFont = _currentFont.copyWith(decoration: decoration);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLetterSpacing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letter Spacing',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _currentFont.letterSpacing,
          min: -1,
          max: 3,
          divisions: 40,
          label: _currentFont.letterSpacing.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _currentFont = _currentFont.copyWith(letterSpacing: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildLineHeight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Height',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _currentFont.lineHeight,
          min: 0.5,
          max: 3,
          divisions: 25,
          label: _currentFont.lineHeight.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _currentFont = _currentFont.copyWith(lineHeight: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _textController.text.isNotEmpty 
                ? _textController.text 
                : 'Preview text will appear here',
            style: TextStyle(
              fontFamily: _getFlutterFontFamily(_currentFont.family),
              fontSize: _currentFont.size,
              fontWeight: _currentFont.weight,
              fontStyle: _currentFont.style,
              color: _currentFont.color.flutterColor,
              letterSpacing: _currentFont.letterSpacing,
              height: _currentFont.lineHeight,
              decoration: _currentFont.decoration,
              decorationColor: _currentFont.color.flutterColor,
              decorationThickness: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Font Details:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Family: ${_currentFont.family}\n'
          'Size: ${_currentFont.size}pt\n'
          'Weight: ${_currentFont.weight.toString().split('.').last}\n'
          'Style: ${_currentFont.style == FontStyle.italic ? 'Italic' : 'Normal'}\n'
          'Color: RGB(${_currentFont.color.r}, ${_currentFont.color.g}, ${_currentFont.color.b}, ${_currentFont.color.a})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}