// ============================================
// FILE: lib/models/file_attachment.dart
// ============================================

import 'package:flutter/material.dart';

class FileAttachment {
  final String id;
  final String fileName;
  final String fileType; // pdf, docx, png, etc.
  final int fileSize; // in bytes
  final String uploadedBy; // User ID
  final DateTime uploadedAt;
  final String? filePath; // URL or local path (for future)

  FileAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
    this.filePath,
  });

  // Get file extension
  String get extension => fileName.split('.').last.toLowerCase();

  // Get file size in readable format
  String get fileSizeText {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get icon based on file type
  IconData get icon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Get color based on file type
  Color get iconColor {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
