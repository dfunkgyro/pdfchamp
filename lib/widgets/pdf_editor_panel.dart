import 'package:flutter/material.dart';
import 'package:pdf_editor_macos/models/pdf_document.dart';

class PDFEditorPanel extends StatefulWidget {
  final PDFDocument document;
  final Function(String) onTextEdit;

  const PDFEditorPanel({
    super.key,
    required this.document,
    required this.onTextEdit,
  });

  @override
  State<PDFEditorPanel> createState() => _PDFEditorPanelState();
}

class _PDFEditorPanelState extends State<PDFEditorPanel> {
  int _selectedPage = 1;
  List<PDFElement> _elements = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Edit PDF',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildPageSelector(),
              const SizedBox(height: 20),
              _buildTextTools(),
              const SizedBox(height: 20),
              _buildFormatTools(),
              const SizedBox(height: 20),
              _buildAnnotationTools(),
              const SizedBox(height: 20),
              _buildElementsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page Navigation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _selectedPage.toDouble(),
                    min: 1,
                    max: widget.document.pageCount.toDouble(),
                    divisions: widget.document.pageCount - 1,
                    label: _selectedPage.toString(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPage = value.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Page $_selectedPage/${widget.document.pageCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToolButton(
                  icon: Icons.text_fields,
                  label: 'Add Text',
                  onTap: () => widget.onTextEdit(''),
                ),
                _buildToolButton(
                  icon: Icons.format_size,
                  label: 'Font Size',
                  onTap: () => _showFontSizeDialog(),
                ),
                _buildToolButton(
                  icon: Icons.format_color_text,
                  label: 'Color',
                  onTap: () => _showColorPicker(),
                ),
                _buildToolButton(
                  icon: Icons.format_bold,
                  label: 'Bold',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.format_italic,
                  label: 'Italic',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.format_underlined,
                  label: 'Underline',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format Tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToolButton(
                  icon: Icons.crop,
                  label: 'Crop',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.rotate_left,
                  label: 'Rotate',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.image,
                  label: 'Add Image',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.signature,
                  label: 'Signature',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.shape_line,
                  label: 'Shapes',
                  onTap: () {},
                ),
                _buildToolButton(
                  icon: Icons.link,
                  label: 'Hyperlink',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annotations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAnnotationButton(
                  color: Colors.yellow,
                  label: 'Highlight',
                  onTap: () {},
                ),
                _buildAnnotationButton(
                  color: Colors.blue,
                  label: 'Underline',
                  onTap: () {},
                ),
                _buildAnnotationButton(
                  color: Colors.red,
                  label: 'Strike',
                  onTap: () {},
                ),
                _buildAnnotationButton(
                  color: Colors.green,
                  label: 'Comment',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementsList() {
    if (_elements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'No elements added yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Elements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 20),
                  onPressed: () {
                    setState(() {
                      _elements.clear();
                    });
                  },
                  tooltip: 'Clear All',
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _elements.length,
              itemBuilder: (context, index) {
                final element = _elements[index];
                return ListTile(
                  leading: Icon(element.icon),
                  title: Text(element.title),
                  subtitle: Text(element.subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      setState(() {
                        _elements.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(100, 40),
      ),
    );
  }

  Widget _buildAnnotationButton({
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        minimumSize: const Size(100, 40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: SizedBox(
          width: 200,
          child: ListView(
            shrinkWrap: true,
            children: [8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48]
                .map((size) => ListTile(
                      title: Text('$size pt'),
                      onTap: () {
                        // Set font size
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Color'),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            children: [
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
              Colors.pink,
              Colors.teal,
            ].map((color) {
              return GestureDetector(
                onTap: () {
                  // Set text color
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class PDFElement {
  final IconData icon;
  final String title;
  final String subtitle;

  PDFElement({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}