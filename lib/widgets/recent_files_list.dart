import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class RecentFilesList extends StatelessWidget {
  final List<String> files;
  final Function(String) onFileSelected;
  final VoidCallback onClear;
  final String? currentFile;

  const RecentFilesList({
    super.key,
    required this.files,
    required this.onFileSelected,
    required this.onClear,
    this.currentFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Files',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (files.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 20),
                  onPressed: onClear,
                  tooltip: 'Clear All',
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = file.split('/').last;
              final isSelected = file == currentFile;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    file,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => onFileSelected(file),
                    tooltip: 'Open PDF',
                  ),
                  onTap: () => onFileSelected(file),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                allowMultiple: false,
              );

              if (result != null && result.files.single.path != null) {
                onFileSelected(result.files.single.path!);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add More PDFs'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}