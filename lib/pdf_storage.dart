import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Information about a saved PDF file
class PDFFileInfo {
  final String path;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;

  PDFFileInfo({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  /// Get formatted file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

/// Service to manage PDF files storage
class PDFStorageService {
  /// Get the directory where PDFs are saved
  static Future<Directory> getPDFDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      // Fallback to temporary directory
      return await getTemporaryDirectory();
    }
  }

  /// Get list of all saved PDF files
  static Future<List<PDFFileInfo>> getSavedPDFs() async {
    try {
      final directory = await getPDFDirectory();
      final files = directory.listSync();

      final pdfFiles = <PDFFileInfo>[];

      for (final file in files) {
        if (file is File && file.path.toLowerCase().endsWith('.pdf')) {
          final stat = await file.stat();
          final name = file.path.split(Platform.pathSeparator).last;

          pdfFiles.add(PDFFileInfo(
            path: file.path,
            name: name.replaceAll('.pdf', '').replaceAll('_', ' '),
            createdAt: stat.modified,
            sizeBytes: stat.size,
          ));
        }
      }

      // Sort by creation date, newest first
      pdfFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return pdfFiles;
    } catch (e) {
      return [];
    }
  }

  /// Delete a PDF file
  static Future<bool> deletePDF(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
