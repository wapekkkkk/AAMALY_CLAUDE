// ============================================
// FILE: lib/screens/task_detail_page.dart (UPDATED)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/task_helper.dart';
import '../widgets/edit_task_bottom_sheet.dart';
import '../models/file_attachment.dart';
import '../data/mock_files.dart';
import '../data/mock_users.dart';
import '../models/project.dart';
import '../data/mock_projects.dart';
import '../services/task_service.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Task _currentTask;
  late List<FileAttachment> _attachments; // ADD THIS
  Project? _project;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _attachments = MockFiles.getTaskFiles(_currentTask.id); // ADD THIS
    _loadProject();
  }

  // ADD THIS METHOD
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

  // ADD THESE PERMISSION METHODS
  bool get _canEdit {
    if (_project == null) return true; // Solo task
    return _project!.isOwner(MockUsers.currentUser.id) ||
        _currentTask.assignedToUserId == MockUsers.currentUser.id;
  }

  bool get _canDelete {
    if (_project == null) return true; // Solo task
    return _project!.isOwner(MockUsers.currentUser.id);
  }

  bool get _canUploadFiles {
    if (_project == null) return true; // Solo task
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
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // ✅ ACTUALLY DELETE FROM FIREBASE
        await TaskService().deleteTask(_currentTask.id);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Close task detail page
        if (mounted) Navigator.pop(context, 'delete');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show error message
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
              if (_canEdit) // ADD THIS CHECK
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
                  // Status Badge
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

                  // Task Title
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
                  // Priority
                  _buildInfoRow(
                    icon: Icons.flag,
                    label: 'Priority',
                    value: TaskHelper.getPriorityText(_currentTask.priority),
                    valueColor:
                        TaskHelper.getPriorityColor(_currentTask.priority),
                    showBadge: true,
                  ),

                  const Divider(height: 32),

                  // Project Name
                  _buildInfoRow(
                    icon: Icons.folder_outlined,
                    label: 'Project',
                    value: _currentTask.projectName,
                  ),

                  const Divider(height: 32),

                  // Deadline
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

                  // Description
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
// Attachments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Attachments (${_attachments.length})',
                            style: const TextStyle(
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

                  // Files List
                  if (_attachments.isEmpty)
                    Container(
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
                    )
                  else
                    ..._attachments
                        .map((file) => _buildFileCard(file))
                        .toList(),

                  const SizedBox(height: 24),
                  // Task ID (for reference)
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
                _mockUploadFile('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(context);
                _mockUploadFile('docx');
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _mockUploadFile('png');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mockUploadFile(String fileType) {
    // Simulate file upload
    setState(() {
      _attachments.add(
        FileAttachment(
          id: 'file_${DateTime.now().millisecondsSinceEpoch}',
          fileName: 'New_File_${DateTime.now().day}.${fileType}',
          fileType: fileType,
          fileSize: 1024000 + (DateTime.now().millisecondsSinceEpoch % 1000000),
          uploadedBy: MockUsers.currentUser.id,
          uploadedAt: DateTime.now(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File uploaded successfully! (Mock)'),
        backgroundColor: Colors.green,
      ),
    );
  }

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
            onPressed: () {
              setState(() {
                _attachments.removeWhere((f) => f.id == file.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewFile(FileAttachment file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${file.fileName}... (Mock)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildFileCard(FileAttachment file) {
    final uploader = MockUsers.getUserById(file.uploadedBy);
    final canDelete = _canUploadFiles &&
        (file.uploadedBy == MockUsers.currentUser.id ||
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
          // File Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: file.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(file.icon, color: file.iconColor, size: 28),
          ),

          const SizedBox(width: 12),

          // File Info
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
                  '${uploader?.name ?? 'Unknown'} • ${file.fileSizeText} • ${_formatDate(file.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewFile(file),
                tooltip: 'View',
                color: Colors.blue,
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Downloading ${file.fileName}... (Mock)')),
                  );
                },
                tooltip: 'Download',
                color: Colors.green,
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
