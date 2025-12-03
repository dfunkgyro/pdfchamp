class PDFDocument {
  final String path;
  final String fileName;
  final int pageCount;
  final DateTime lastModified;
  final FileSize fileSize;

  PDFDocument({
    required this.path,
    required this.fileName,
    required this.pageCount,
    required this.lastModified,
    required this.fileSize,
  });
}

class FileSize {
  final int bytes;

  FileSize(this.bytes);

  String get formatted {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}