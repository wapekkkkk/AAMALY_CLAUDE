// ============================================
// FILE: lib/services/file_service.dart
// FILE UPLOAD/DOWNLOAD SERVICE
// ============================================

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_attachment.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

class FileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // PICK FILES FROM DEVICE
  // ============================================

  /// Pick a single file from device
  Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      Logger.info('Opening file picker...', 'FileService');

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Logger.success('File picked: ${file.name} (${_formatBytes(file.size)})',
            'FileService');
        return file;
      } else {
        Logger.info('File picker cancelled', 'FileService');
        return null;
      }
    } catch (e) {
      Logger.error('Failed to pick file', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Pick multiple files from device
  Future<List<PlatformFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      Logger.info('Opening multi-file picker...', 'FileService');

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        Logger.success('${result.files.length} files picked', 'FileService');
        return result.files;
      } else {
        Logger.info('File picker cancelled', 'FileService');
        return [];
      }
    } catch (e) {
      Logger.error('Failed to pick files', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // UPLOAD FILES TO FIREBASE STORAGE
  // ============================================

  /// Upload a file to Firebase Storage
  Future<String> uploadFile({
    required String taskId,
    required PlatformFile file,
    required String uploadedBy,
    Function(double)? onProgress,
  }) async {
    try {
      Logger.service(
          'FileService', 'uploadFile', 'taskId: $taskId, file: ${file.name}');

      // Validate file
      if (file.path == null) {
        throw Exception('File path is null');
      }

      final fileToUpload = File(file.path!);
      if (!await fileToUpload.exists()) {
        throw Exception('File does not exist');
      }

      // Check file size (max 10MB)
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSize) {
        throw Exception('File size exceeds 10MB limit');
      }

      // Create storage reference
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = _storage.ref().child('tasks/$taskId/$fileName');

      Logger.file('UPLOAD_START', fileName, file.size);

      // Upload file
      final uploadTask = storageRef.putFile(fileToUpload);

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
        Logger.info('Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            'FileService');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.file('UPLOAD_COMPLETE', fileName, file.size);

      // Save file metadata to Firestore
      final fileId = await _saveFileMetadata(
        taskId: taskId,
        fileName: file.name,
        fileUrl: downloadUrl,
        fileSize: file.size,
        fileType: _getFileType(file.extension ?? ''),
        uploadedBy: uploadedBy,
      );

      Logger.success('File uploaded successfully: $fileId', 'FileService');
      return fileId;
    } catch (e) {
      Logger.error('Failed to upload file', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Save file metadata to Firestore
  Future<String> _saveFileMetadata({
    required String taskId,
    required String fileName,
    required String fileUrl,
    required int fileSize,
    required String fileType,
    required String uploadedBy,
  }) async {
    try {
      final docRef = await _firestore.collection('files').add({
        'taskId': taskId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'fileType': fileType,
        'uploadedBy': uploadedBy,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      Logger.database('CREATE', 'files', docRef.id);
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to save file metadata', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // GET FILES FOR A TASK
  // ============================================

  /// Get all files for a task (real-time)
  Stream<List<FileAttachment>> getTaskFiles(String taskId) {
    Logger.service('FileService', 'getTaskFiles', 'taskId: $taskId');

    return _firestore
        .collection('files')
        .where('taskId', isEqualTo: taskId)
        // .orderBy('uploadedAt', descending: true) // ⏸️ COMMENTED until index builds
        .snapshots()
        .map((snapshot) {
      final files = snapshot.docs.map((doc) {
        final data = doc.data();
        return FileAttachment(
          id: doc.id,
          taskId: data['taskId'] ?? '',
          fileName: data['fileName'] ?? '',
          fileUrl: data['fileUrl'] ?? '',
          fileSize: data['fileSize'] ?? 0,
          fileType: data['fileType'] ?? 'unknown',
          uploadedBy: data['uploadedBy'] ?? '',
          uploadedAt:
              (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // ✅ Sort in memory instead
      files.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return files;
    });
  }

  /// Get single file by ID
  Future<FileAttachment?> getFileById(String fileId) async {
    try {
      Logger.service('FileService', 'getFileById', 'fileId: $fileId');

      final doc = await _firestore.collection('files').doc(fileId).get();

      if (!doc.exists) {
        Logger.warning('File not found: $fileId', 'FileService');
        return null;
      }

      final data = doc.data()!;
      return FileAttachment(
        id: doc.id,
        taskId: data['taskId'] ?? '',
        fileName: data['fileName'] ?? '',
        fileUrl: data['fileUrl'] ?? '',
        fileSize: data['fileSize'] ?? 0,
        fileType: data['fileType'] ?? 'unknown',
        uploadedBy: data['uploadedBy'] ?? '',
        uploadedAt:
            (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      Logger.error('Failed to get file', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // DELETE FILES
  // ============================================

  /// Delete a file from Storage and Firestore
  Future<void> deleteFile(String fileId) async {
    try {
      Logger.service('FileService', 'deleteFile', 'fileId: $fileId');

      // Get file metadata
      final file = await getFileById(fileId);
      if (file == null) {
        throw Exception('File not found');
      }

      // Delete from Storage
      try {
        final storageRef = _storage.refFromURL(file.fileUrl);
        await storageRef.delete();
        Logger.file('DELETE', file.fileName);
      } catch (e) {
        Logger.warning('Failed to delete file from storage: $e', 'FileService');
        // Continue anyway to delete metadata
      }

      // Delete metadata from Firestore
      await _firestore.collection('files').doc(fileId).delete();
      Logger.database('DELETE', 'files', fileId);

      Logger.success('File deleted successfully', 'FileService');
    } catch (e) {
      Logger.error('Failed to delete file', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Delete all files for a task
  Future<void> deleteTaskFiles(String taskId) async {
    try {
      Logger.service('FileService', 'deleteTaskFiles', 'taskId: $taskId');

      final files = await _firestore
          .collection('files')
          .where('taskId', isEqualTo: taskId)
          .get();

      for (var doc in files.docs) {
        await deleteFile(doc.id);
      }

      Logger.success('All task files deleted', 'FileService');
    } catch (e) {
      Logger.error('Failed to delete task files', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // DOWNLOAD FILES
  // ============================================

  /// Get download URL for a file
  Future<String> getDownloadUrl(String fileId) async {
    try {
      Logger.service('FileService', 'getDownloadUrl', 'fileId: $fileId');

      final file = await getFileById(fileId);
      if (file == null) {
        throw Exception('File not found');
      }

      return file.fileUrl;
    } catch (e) {
      Logger.error('Failed to get download URL', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get file type from extension
  String _getFileType(String extension) {
    final ext = extension.toLowerCase();

    if (ext == 'pdf') return 'pdf';
    if (ext == 'doc' || ext == 'docx') return 'document';
    if (ext == 'xls' || ext == 'xlsx') return 'spreadsheet';
    if (ext == 'ppt' || ext == 'pptx') return 'presentation';
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif')
      return 'image';
    if (ext == 'zip' || ext == 'rar' || ext == '7z') return 'archive';
    if (ext == 'txt') return 'text';

    return 'other';
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Get file icon based on type
  static String getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return '📄';
      case 'document':
        return '📝';
      case 'spreadsheet':
        return '📊';
      case 'presentation':
        return '📽️';
      case 'image':
        return '🖼️';
      case 'archive':
        return '🗜️';
      case 'text':
        return '📃';
      default:
        return '📎';
    }
  }
}
