// ============================================
// FILE: lib/screens/task_detail_page.dart
// UPDATED: Clean theme like other pages + Project color (fallback purple)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/permissions_service.dart';
import '../../models/task.dart';
import '../../utils/task_helper.dart';
import '../../widgets/edit_task_bottom_sheet.dart';
import '../../models/file_attachment.dart';
import '../../services/task_service.dart';
import '../../services/file_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/logger.dart';
import '../../utils/error_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Task _currentTask;

  final _fileService = FileService();
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  static const Color _defaultTaskColor = Color(0xFF7B68EE);

  // Loaded from Firestore (best effort)
  String? _projectId;
  String? _projectName;
  String? _projectCode;
  String? _projectOwnerId;
  Color _projectColor = _defaultTaskColor;
  List<String> _projectCollaboratorIds = []; // ✅ ADD THIS
  String? _taskCreatorId;

  // cache for user names (for assignee/uploader)
  final Map<String, String> _userNameCache = {};

  bool _loadingProject = true;

  Color get _themeColor => _projectColor;
  String get _currentUserId => _authService.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _loadProjectTheme(); // ✅ Firestore project color
  }

  // ✅ Load project by task.projectName (tries match by name first, then code)
  Future<void> _loadProjectTheme() async {
    setState(() => _loadingProject = true);

    final key = _currentTask.projectName.trim();
    if (key.isEmpty || key.toLowerCase() == 'no project') {
      setState(() {
        _projectId = null;
        _projectName = null;
        _projectCode = null;
        _projectOwnerId = null;
        _projectColor = _defaultTaskColor;
        _projectCollaboratorIds = []; // ✅ ADD
        _taskCreatorId = null;
        _loadingProject = false;
      });
      return;
    }

    try {
      // Get project
      QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collection('projects')
          .where('name', isEqualTo: key)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await _firestore
            .collection('projects')
            .where('code', isEqualTo: key)
            .limit(1)
            .get();
      }
// ✅ Get task creator
      final taskDoc =
          await _firestore.collection('tasks').doc(_currentTask.id).get();
      final taskData = taskDoc.data();
      final creatorId = taskData?['createdBy'] as String?;
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();

        final dynamic colorRaw = data['color'];
        final Color resolvedColor = _parseColor(colorRaw) ?? _defaultTaskColor;

        setState(() {
          _projectId = doc.id;
          _projectName = (data['name'] ?? key).toString();
          _projectCode = (data['code'] ?? '').toString();
          _projectOwnerId = (data['ownerId'] ?? '').toString();
          _projectColor = resolvedColor;
          _projectCollaboratorIds =
              List<String>.from(data['collaboratorIds'] ?? []); // ✅ ADD
          _taskCreatorId = creatorId; // ✅ ADD
          _loadingProject = false;
        });
      } else {
        setState(() {
          _projectId = null;
          _projectName = null;
          _projectCode = null;
          _projectOwnerId = null;
          _projectColor = _defaultTaskColor;
          _projectCollaboratorIds = []; // ✅ ADD
          _taskCreatorId = creatorId;
          _loadingProject = false;
        });
      }
    } catch (_) {
      setState(() {
        _projectId = null;
        _projectName = null;
        _projectCode = null;
        _projectOwnerId = null;
        _projectColor = _defaultTaskColor;
        _projectCollaboratorIds = []; // ✅ ADD
        _taskCreatorId = null; // ✅ ADD
        _loadingProject = false;
      });
    }
  }

  Color? _parseColor(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return Color(raw);

    if (raw is String) {
      // Accept "0xFF2196F3" or "4281558867"
      final s = raw.trim();
      if (s.startsWith('0x') || s.startsWith('0X')) {
        final v = int.tryParse(s.substring(2), radix: 16);
        if (v != null) return Color(v);
      }
      final v = int.tryParse(s);
      if (v != null) return Color(v);
    }
    return null;
  }

  bool get _canEdit {
    if (_projectId == null) return true;

    return PermissionsService.canEditTask(
      task: _currentTask,
      userId: _currentUserId,
      projectOwnerId: _projectOwnerId ?? '',
      projectCollaboratorIds: _projectCollaboratorIds,
      taskCreatorId: _taskCreatorId,
    );
  }

  bool get _canDelete {
    if (_projectId == null) return true;

    return PermissionsService.canDeleteTask(
      task: _currentTask,
      userId: _currentUserId,
      projectOwnerId: _projectOwnerId ?? '',
      projectCollaboratorIds: _projectCollaboratorIds,
      taskCreatorId: _taskCreatorId,
    );
  }

  bool get _canUploadFiles {
    if (_projectId == null) return true;

    // Same permissions as edit
    return PermissionsService.canEditTask(
      task: _currentTask,
      userId: _currentUserId,
      projectOwnerId: _projectOwnerId ?? '',
      projectCollaboratorIds: _projectCollaboratorIds,
      taskCreatorId: _taskCreatorId,
    );
  }

  bool get _canMarkDone {
    if (_projectId == null) return true;

    return PermissionsService.canMarkAsDone(
      task: _currentTask,
      userId: _currentUserId,
      projectOwnerId: _projectOwnerId ?? '',
      projectCollaboratorIds: _projectCollaboratorIds,
    );
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
      setState(() => _currentTask = updatedTask);
      await _loadProjectTheme();
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
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await TaskService().deleteTask(_currentTask.id);

        if (mounted) Navigator.pop(context); // close loader
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
    final isOverdue = _currentTask.isOverdue;
    final deadlineText =
        DateFormat('EEEE, MMMM dd, yyyy').format(_currentTask.deadline);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A), // your dark theme bg
      // ✅ consistent light page like others
      appBar: AppBar(
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Task Details'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') _showEditBottomSheet();
              if (value == 'delete') _showDeleteConfirmation();
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
      body: Column(
        children: [
          // ✅ HERO HEADER (like your other pages)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            decoration: BoxDecoration(
              color: _themeColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  _currentTask.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // Project line
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadingProject
                            ? 'Loading project...'
                            : (_projectId == null
                                ? 'No project (Default theme)'
                                : '${_projectName ?? ''}${(_projectCode ?? '').isNotEmpty ? ' • ${_projectCode!}' : ''}'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
          if (_projectId != null && !_loadingProject)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _canEdit
                    ? Colors.blue.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _canEdit
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _canEdit ? Icons.edit : Icons.visibility,
                    size: 16,
                    color: _canEdit ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _canEdit
                          ? 'You can edit this task'
                          : 'View only - You can\'t edit this task',
                      style: TextStyle(
                        fontSize: 12,
                        color: _canEdit ? Colors.blue : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ✅ WHITE SHEET BODY (this is what your screenshot is missing)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF101827), // dark surface
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ✅ Info card
                    _SectionCard(
                      title: 'Overview',
                      icon: Icons.info_outline,
                      iconColor: _themeColor,
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.flag,
                            iconColor: _themeColor,
                            label: 'Priority',
                            trailing:
                                _PriorityChip(priority: _currentTask.priority),
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            icon: Icons.folder_outlined,
                            iconColor: _themeColor,
                            label: 'Project',
                            value: _currentTask.projectName.isEmpty
                                ? 'No project'
                                : _currentTask.projectName,
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            icon: Icons.calendar_today,
                            iconColor: _themeColor,
                            label: 'Deadline',
                            value: deadlineText,
                            valueColor: isOverdue ? Colors.red : null,
                          ),
                          if (isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.25)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Overdue by ${_currentTask.daysUntilDeadline.abs()} day(s)',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Optional: Assignee
                          if (_currentTask.assignedToUserId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: FutureBuilder<String>(
                                future: _getUserName(
                                    _currentTask.assignedToUserId!),
                                builder: (context, snap) {
                                  final name = snap.data ?? 'Loading...';
                                  final isMe = _currentTask.assignedToUserId ==
                                      _currentUserId;
                                  return _InfoTile(
                                    icon: Icons.person_outline,
                                    iconColor: _themeColor,
                                    label: 'Assigned To',
                                    value: isMe ? 'You' : name,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Description card
                    _SectionCard(
                      title: 'Description',
                      icon: Icons.description_outlined,
                      iconColor: _themeColor,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          _currentTask.description.isEmpty
                              ? '-'
                              : _currentTask.description,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Colors.grey[850],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Attachments card
                    _SectionCard(
                      title: 'Attachments',
                      icon: Icons.attach_file,
                      iconColor: _themeColor,
                      trailing: _canUploadFiles
                          ? TextButton.icon(
                              onPressed: _showUploadDialog,
                              icon: Icon(Icons.upload_file,
                                  size: 18, color: _themeColor),
                              label: Text('Upload',
                                  style: TextStyle(
                                      color: _themeColor,
                                      fontWeight: FontWeight.w700)),
                            )
                          : null,
                      child: _buildAttachmentsList(),
                    ),

                    const SizedBox(height: 14),

                    // Small footer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _themeColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: _themeColor.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: _themeColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Task ID: ${_currentTask.id}',
                              style: TextStyle(
                                  color: _themeColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          ),
        ],
      ),
    );
  }

  // ✅ Attachments List (clean)
  Widget _buildAttachmentsList() {
    return StreamBuilder<List<FileAttachment>>(
      stream: _fileService.getTaskFiles(_currentTask.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(18.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: Text(
              'Error loading files: ${snapshot.error}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          );
        }

        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 42, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No files attached',
                    style: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return Column(
          children: files.map((f) => _buildFileCard(f)).toList(),
        );
      },
    );
  }

  // ✅ Upload dialog
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

  // ✅ Upload with progress (dialog updates correctly)
  Future<void> _uploadFile(FileType type, [List<String>? extensions]) async {
    StateSetter? dialogSetState;
    double uploadProgress = 0.0;

    try {
      final pickedFile = await _fileService.pickFile(
        type: type,
        allowedExtensions: extensions,
      );

      if (pickedFile == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: const Text('Uploading File'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pickedFile.name),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: uploadProgress,
                    color: _themeColor,
                  ),
                  const SizedBox(height: 8),
                  Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        ),
      );

      final uid = _authService.currentUserId;
      if (uid == null) throw Exception('User not authenticated');

      await _fileService.uploadFile(
        taskId: _currentTask.id,
        file: pickedFile,
        uploadedBy: uid,
        onProgress: (p) {
          dialogSetState?.call(() {
            uploadProgress = p;
          });
        },
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to upload file', e);
      if (mounted) Navigator.pop(context);

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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await _fileService.deleteFile(file.id);

                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
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
      Logger.info('File URL: $url', 'TaskDetailPage');

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(file.fileName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File Type: ${file.fileType}'),
              Text('Size: ${file.formattedSize}'),
              const SizedBox(height: 10),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFileCard(FileAttachment file) {
    final canDelete = _canUploadFiles &&
        (file.uploadedBy == _currentUserId ||
            _projectOwnerId == _currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getFileColor(file.fileType).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(file.fileType),
              color: _getFileColor(file.fileType),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: _getUserName(file.uploadedBy),
                  builder: (context, snap) {
                    final name = (file.uploadedBy == _currentUserId)
                        ? 'You'
                        : (snap.data ?? 'User');
                    return Text(
                      '$name • ${file.formattedSize} • ${_formatDate(file.uploadedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            onPressed: () => _viewFile(file),
            color: _themeColor,
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteFile(file),
              color: Colors.red,
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
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('MMM dd').format(date);
  }

  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      final name = (data?['name'] ?? data?['fullName'] ?? 'User').toString();
      _userNameCache[userId] = name;
      return name;
    } catch (_) {
      return 'User';
    }
  }
}

// ==========================
// UI SMALL WIDGETS
// ==========================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // dark card
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(
                      0xFFF8FAFC), // bright (fixes "Overview"/"Description")
                  letterSpacing: 0.2,
                ),
              )),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Widget? trailing;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.white,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color c;
    String text;

    switch (priority) {
      case TaskPriority.high:
        c = Colors.red;
        text = 'High';
        break;
      case TaskPriority.medium:
        c = Colors.orange;
        text = 'Medium';
        break;
      case TaskPriority.low:
        c = Colors.green;
        text = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
