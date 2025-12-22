// ============================================
// FILE: lib/screens/task_detail_page.dart (UPDATED WITH REAL FILESERVICE)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/task_helper.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../models/file_attachment.dart';
import '../data/mock_users.dart';
import '../models/project.dart';
import '../data/mock_projects.dart';
import '../services/task_service.dart';
import '../services/file_service.dart'; // ✅ NEW
import '../services/firebase_auth_service.dart'; // ✅ NEW
import '../utils/logger.dart'; // ✅ NEW
import '../utils/error_handler.dart'; // ✅ NEW
import 'package:file_picker/file_picker.dart'; // ✅ NEW

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Task _currentTask;
  Project? _project;

  final _fileService = FileService(); // ✅ NEW
  final _authService = FirebaseAuthService(); // ✅ NEW

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadProject();
  }

  void _loadProject() {
    try {
      _project = MockProjects.getProjects().firstWhere(
        (p) =>
            p.name == _currentTask.projectName ||
            p.code == _currentTask.projectName,
      );
    } catch (e) {
      _project = null;
    }
  }

  bool get _canEdit {
    if (_project == null) return true;
    return _project!.isOwner(MockUsers.currentUser.id) ||
        _currentTask.assignedToUserId == MockUsers.currentUser.id;
  }

  bool get _canDelete {
    if (_project == null) return true;
    return _project!.isOwner(MockUsers.currentUser.id);
  }

  bool get _canUploadFiles {
    if (_project == null) return true;
    return _project!.isOwner(MockUsers.currentUser.id) ||
        _currentTask.assignedToUserId == MockUsers.currentUser.id;
  }

  void _showEditBottomSheet() async {
    final updatedTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => EditTaskBottomSheet(task: _currentTask),
        ),
      ),
    );

    if (updatedTask != null) {
      setState(() {
        _currentTask = updatedTask;
      });
    }
  }

  void _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await TaskService().deleteTask(_currentTask.id);

        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pop(context, 'delete');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final isOverdue = _currentTask.isOverdue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditBottomSheet();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [
              if (_canEdit)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
              if (_canDelete)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Status
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TaskHelper.getStatusColor(_currentTask.status)
                    .withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: TaskHelper.getStatusColor(_currentTask.status)
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TaskHelper.getStatusColor(_currentTask.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentTask.status == TaskStatus.completed
                              ? Icons.check_circle
                              : _currentTask.status == TaskStatus.inProgress
                                  ? Icons.pending
                                  : Icons.circle_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TaskHelper.getStatusText(_currentTask.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentTask.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.flag,
                    label: 'Priority',
                    value: TaskHelper.getPriorityText(_currentTask.priority),
                    valueColor:
                        TaskHelper.getPriorityColor(_currentTask.priority),
                    showBadge: true,
                  ),

                  const Divider(height: 32),

                  _buildInfoRow(
                    icon: Icons.folder_outlined,
                    label: 'Project',
                    value: _currentTask.projectName,
                  ),

                  const Divider(height: 32),

                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Deadline',
                    value: dateFormat.format(_currentTask.deadline),
                    valueColor: isOverdue ? Colors.red : null,
                  ),

                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              'Overdue by ${_currentTask.daysUntilDeadline.abs()} day(s)',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (!isOverdue && _currentTask.status != TaskStatus.completed)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 8),
                      child: Text(
                        '${_currentTask.daysUntilDeadline} day(s) remaining',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const Divider(height: 32),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _currentTask.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ REAL-TIME ATTACHMENTS SECTION
                  _buildAttachmentsSection(),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Task ID: ${_currentTask.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showBadge = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF2196F3)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              showBadge
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: valueColor?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: valueColor ?? Colors.grey),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? Colors.black87,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ NEW - Real-time Attachments Section with StreamBuilder
  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_canUploadFiles)
              TextButton.icon(
                onPressed: _showUploadDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ StreamBuilder for real-time file updates
        StreamBuilder<List<FileAttachment>>(
          stream: _fileService.getTaskFiles(_currentTask.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Center(
                  child: Text(
                    'Error loading files: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              );
            }

            final files = snapshot.data ?? [];

            if (files.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.folder_open,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No files attached',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: files.map((file) => _buildFileCard(file)).toList(),
            );
          },
        ),
      ],
    );
  }

  // ✅ NEW - Real File Upload Dialog
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(FileType.custom, ['pdf']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(FileType.custom, ['doc', 'docx']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(FileType.image);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('Upload Any File'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(FileType.any);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW - Real File Upload with Progress
  Future<void> _uploadFile(FileType type, [List<String>? extensions]) async {
    try {
      Logger.info('Starting file upload', 'TaskDetailPage');

      // Pick file
      final pickedFile = await _fileService.pickFile(
        type: type,
        allowedExtensions: extensions,
      );

      if (pickedFile == null) {
        Logger.info('File picker cancelled', 'TaskDetailPage');
        return;
      }

      // Show progress dialog
      double uploadProgress = 0.0;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Uploading File'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pickedFile.name),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 8),
                  Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        ),
      );

      // Upload file
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _fileService.uploadFile(
        taskId: _currentTask.id,
        file: pickedFile,
        uploadedBy: currentUserId,
        onProgress: (progress) {
          if (mounted) {
            // Update progress
            uploadProgress = progress;
          }
        },
      );

      // Close progress dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Logger.success('File uploaded successfully', 'TaskDetailPage');
    } catch (e) {
      Logger.error('Failed to upload file', e);

      // Close progress dialog if open
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW - Real File Delete
  void _deleteFile(FileAttachment file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Delete file
                await _fileService.deleteFile(file.id);

                // Close loading
                if (mounted) Navigator.pop(context);

                // Show success
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                Logger.success('File deleted', 'TaskDetailPage');
              } catch (e) {
                Logger.error('Failed to delete file', e);

                // Close loading
                if (mounted) Navigator.pop(context);

                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorHandler.getErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewFile(FileAttachment file) async {
    try {
      final url = await _fileService.getDownloadUrl(file.id);

      // Show dialog with download URL
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(file.fileName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('File Type: ${file.fileType}'),
                Text('Size: ${file.formattedSize}'),
                const SizedBox(height: 16),
                const Text('Opening file in browser...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      Logger.info('File URL: $url', 'TaskDetailPage');
    } catch (e) {
      Logger.error('Failed to get file URL', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFileCard(FileAttachment file) {
    final uploader = MockUsers.getUserById(file.uploadedBy);
    final canDelete = _canUploadFiles &&
        (file.uploadedBy == _authService.currentUserId ||
            (_project?.isOwner(MockUsers.currentUser.id) ?? false));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getFileColor(file.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(file.fileType),
              color: _getFileColor(file.fileType),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${uploader?.name ?? 'Unknown'} • ${file.formattedSize} • ${_formatDate(file.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewFile(file),
                tooltip: 'View',
                color: Colors.blue,
              ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteFile(file),
                  tooltip: 'Delete',
                  color: Colors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'image':
        return Icons.image;
      case 'spreadsheet':
        return Icons.table_chart;
      case 'presentation':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Colors.red;
      case 'document':
        return Colors.blue;
      case 'image':
        return Colors.green;
      case 'spreadsheet':
        return Colors.teal;
      case 'presentation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
