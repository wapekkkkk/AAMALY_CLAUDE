// ============================================
// FILE: lib/models/file_attachment.dart
// FILE ATTACHMENT MODEL
// ============================================

class FileAttachment {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String fileType; // 'pdf', 'image', 'document', etc.
  final String uploadedBy; // userId
  final DateTime uploadedAt;

  FileAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  // Create from Firestore document
  factory FileAttachment.fromMap(Map<String, dynamic> map, String id) {
    return FileAttachment(
      id: id,
      taskId: map['taskId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? 'unknown',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: map['uploadedAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt,
    };
  }

  // Get formatted file size
  String get formattedSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // Get file extension
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Check if file is an image
  bool get isImage {
    return fileType == 'image' ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  // Check if file is a PDF
  bool get isPdf {
    return fileType == 'pdf' || extension == 'pdf';
  }

  // Check if file is a document
  bool get isDocument {
    return fileType == 'document' || ['doc', 'docx', 'txt'].contains(extension);
  }

  // Get icon for file type
  String get icon {
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

  // Copy with
  FileAttachment copyWith({
    String? id,
    String? taskId,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? fileType,
    String? uploadedBy,
    DateTime? uploadedAt,
  }) {
    return FileAttachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
