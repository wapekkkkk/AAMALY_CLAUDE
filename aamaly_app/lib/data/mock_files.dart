// ============================================
// FILE: lib/data/mock_files.dart
// ============================================

import '../models/file_attachment.dart';

class MockFiles {
  static List<FileAttachment> getTaskFiles(String taskId) {
    // Return different files for different tasks
    switch (taskId) {
      case '1': // Complete FYP Chapter 3
        return [
          FileAttachment(
            id: 'file_1',
            fileName: 'Chapter3_Draft_v1.pdf',
            fileType: 'pdf',
            fileSize: 2457600, // 2.4 MB
            uploadedBy: '1', // Current user
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          FileAttachment(
            id: 'file_2',
            fileName: 'Methodology_Diagram.png',
            fileType: 'png',
            fileSize: 456789,
            uploadedBy: '2', // Sarah
            uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
      case '4': // Flutter UI Implementation
        return [
          FileAttachment(
            id: 'file_3',
            fileName: 'UI_Mockups.pdf',
            fileType: 'pdf',
            fileSize: 1234567,
            uploadedBy: '1',
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
      default:
        return []; // No files for other tasks
    }
  }
}
