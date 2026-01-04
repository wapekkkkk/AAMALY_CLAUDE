// ============================================
// FILE: lib/screens/create_task_page.dart (DARK THEME + FIREBASE COLLABORATORS)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../models/user.dart' as app_user;
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/friend_service.dart';

class CreateTaskPage extends StatefulWidget {
  final String? lockedProjectName;
  final String? lockedProjectCode;
  final Project? project;

  const CreateTaskPage({
    super.key,
    this.lockedProjectName,
    this.lockedProjectCode,
    this.project,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _taskService = TaskService();
  final _authService = FirebaseAuthService();
  final _projectService = ProjectService();
  final _friendService = FriendService();

  DateTime? _selectedDeadline;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  String? _selectedProjectName;
  String? _assignedToUserId;

  bool _isLoading = false;
  List<Project> _availableProjects = [];
  List<app_user.User> _projectCollaborators = [];

  // 🎨 Dark theme (match Friends/Search)
  static const Color kBg = Color(0xFF0E141B);
  static const Color kAppBarBg = Color(0xFF0B0F14);
  static const Color kSurface = Color(0xFF151D27);
  static const Color kSurface2 = Color(0xFF1B2430);
  static const Color kBorder = Color(0xFF263241);

  static const Color kText = Color(0xFFF2F4F8);
  static const Color kMuted = Color(0xFF9AA7B4);

  static const Color kPrimary = Color(0xFF7C4DFF);

  // keep this so you can swap later if project color exists
  Color _themeColor = kPrimary;

  @override
  void initState() {
    super.initState();
    _loadProjects();

    if (widget.lockedProjectName != null) {
      _selectedProjectName =
          widget.lockedProjectCode ?? widget.lockedProjectName;

      if (widget.project != null) {
        _loadProjectCollaborators(widget.project!.id);
      }
    }
  }

  Future<void> _loadProjects() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        final projects =
            await _projectService.getAllUserProjects(currentUserId).first;
        if (mounted) {
          setState(() => _availableProjects = projects);
        }
      }
    } catch (e) {
      // ignore (you can add logging)
    }
  }

  Future<void> _loadProjectCollaborators(String projectId) async {
    try {
      final collaborators =
          await _projectService.getProjectCollaborators(projectId);
      if (mounted) {
        setState(() => _projectCollaborators = collaborators);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _projectCollaborators = []);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kPrimary,
              surface: kSurface,
              onSurface: kText,
            ),
            dialogBackgroundColor: kSurface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _handleCreateTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get the actual project ID
      String? actualProjectId;
      String? actualProjectOwnerId; // ✅ ADD THIS

      if (widget.project != null) {
        actualProjectId = widget.project!.id;
        actualProjectOwnerId = widget.project!.ownerId; // ✅ ADD THIS
      } else if (_selectedProjectName != null) {
        try {
          final selectedProject = _availableProjects.firstWhere(
            (p) =>
                p.code == _selectedProjectName ||
                p.name == _selectedProjectName,
          );
          actualProjectId = selectedProject.id;
          actualProjectOwnerId = selectedProject.ownerId; // ✅ ADD THIS
        } catch (_) {
          actualProjectId = null;
          actualProjectOwnerId = null; // ✅ ADD THIS
        }
      }

      // ✅ NEW: Auto-assign logic
      String? finalAssignedToUserId = _assignedToUserId;

      // If user is NOT the project owner, auto-assign to themselves
      if (actualProjectOwnerId != null &&
          currentUserId != actualProjectOwnerId) {
        finalAssignedToUserId = currentUserId;
        print('🔄 Auto-assigning task to collaborator: $currentUserId');
      }

      final taskId = await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline!,
        status: TaskService.taskStatusToString(_selectedStatus),
        priority: TaskService.taskPriorityToString(_selectedPriority),
        projectName: _selectedProjectName ?? 'No Project',
        createdBy: currentUserId,
        projectId: actualProjectId,
        assignedToUserId: finalAssignedToUserId, // ✅ USE THIS INSTEAD
      );

      final createdTask = Task(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline!,
        status: _selectedStatus,
        priority: _selectedPriority,
        projectName: _selectedProjectName ?? 'No Project',
        assignedToUserId: finalAssignedToUserId, // ✅ USE THIS INSTEAD
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pop(createdTask);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finalAssignedToUserId != null
                  ? (finalAssignedToUserId == currentUserId
                      ? 'Task created and assigned to you!'
                      : 'Task created and assigned successfully!')
                  : 'Task created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _shouldShowAssignField() {
    // ✅ NEW: Check if current user is the project owner
    final currentUserId = _authService.currentUserId;

    if (widget.project != null) {
      // Only show assignment dropdown if user is the owner
      final isOwner = widget.project!.ownerId == currentUserId;
      return widget.project!.hasCollaborators && isOwner; // ✅ CHANGED
    }

    if (_selectedProjectName != null) {
      final project = _availableProjects.firstWhere(
        (p) => p.code == _selectedProjectName || p.name == _selectedProjectName,
        orElse: () => Project(
          id: '',
          name: '',
          code: '',
          dateCreated: DateTime.now(),
          taskTypes: [],
          totalTasks: 0,
          completedTasks: 0,
          inProgressTasks: 0,
          ownerId: '',
          collaboratorIds: [],
        ),
      );

      // Only show assignment dropdown if user is the owner
      final isOwner = project.ownerId == currentUserId;
      return project.hasCollaborators && isOwner; // ✅ CHANGED
    }

    return false;
  }

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kMuted),
      prefixIcon: icon == null ? null : Icon(icon, color: kMuted),
      filled: true,
      fillColor: kSurface2,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _themeColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.lockedProjectName != null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kAppBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Task',
          style: TextStyle(
            color: kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Task details
                _sectionCard(
                  title: 'Task Details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'E.g., Complete FYP Chapter 3',
                          icon: Icons.title,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter task title';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: kText, fontSize: 14),
                        maxLines: 4,
                        decoration: _fieldDecoration(
                          hint: 'Describe the task in detail...',
                          icon: Icons.notes_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter task description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Project & Assignment
                _sectionCard(
                  title: 'Project & Assignment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project
                      const Text(
                        'Project',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),

                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kSurface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, color: kMuted, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.lockedProjectName!,
                                  style: const TextStyle(
                                    color: kText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedProjectName,
                          dropdownColor: kSurface,
                          iconEnabledColor: kMuted,
                          style: const TextStyle(color: kText),
                          decoration: _fieldDecoration(
                            hint: 'Select a project (Optional)',
                            icon: Icons.folder_outlined,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No Project',
                                  style: TextStyle(color: kText)),
                            ),
                            ..._availableProjects.map((project) {
                              return DropdownMenuItem(
                                value: project.code,
                                child: Text(
                                  '${project.name} (${project.code})',
                                  style: const TextStyle(color: kText),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) async {
                            setState(() {
                              _selectedProjectName = value;
                              _assignedToUserId = null;
                            });

                            if (value != null) {
                              try {
                                final selectedProject =
                                    _availableProjects.firstWhere(
                                  (p) => p.code == value || p.name == value,
                                );
                                await _loadProjectCollaborators(
                                    selectedProject.id);
                              } catch (_) {}
                            } else {
                              setState(() => _projectCollaborators = []);
                            }
                          },
                        ),

                      const SizedBox(height: 16),

                      // Assign To (only if collaborators exist)
                      if (_shouldShowAssignField()) ...[
                        const Text(
                          'Assign To',
                          style: TextStyle(color: kMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _assignedToUserId,
                          dropdownColor: kSurface,
                          iconEnabledColor: kMuted,
                          style: const TextStyle(color: kText),
                          decoration: _fieldDecoration(
                            hint: 'Select team member (Optional)',
                            icon: Icons.person_outline,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Unassigned',
                                  style: TextStyle(color: kText)),
                            ),
                            ..._projectCollaborators.map((user) {
                              return DropdownMenuItem(
                                value: user.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: _themeColor,
                                      child: Text(
                                        user.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(color: kText),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _assignedToUserId = value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Deadline
                _sectionCard(
                  title: 'Deadline',
                  child: InkWell(
                    onTap: _selectDeadline,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kSurface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: _themeColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDeadline == null
                                  ? 'Select deadline date'
                                  : DateFormat('EEEE, MMM dd, yyyy')
                                      .format(_selectedDeadline!),
                              style: TextStyle(
                                color:
                                    _selectedDeadline == null ? kMuted : kText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: kMuted),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Priority & Status
                _sectionCard(
                  title: 'Priority & Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Priority',
                          style: TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: TaskPriority.values.map((priority) {
                          final isSelected = _selectedPriority == priority;
                          final c = _getPriorityColor(priority);

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  _getPriorityText(priority),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : kMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: c,
                                backgroundColor: kSurface2,
                                side:
                                    BorderSide(color: isSelected ? c : kBorder),
                                onSelected: (_) => setState(
                                    () => _selectedPriority = priority),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text('Status',
                          style: TextStyle(color: kMuted, fontSize: 12)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskStatus.values.map((status) {
                          final isSelected = _selectedStatus == status;
                          final c = _getStatusColor(status);

                          return ChoiceChip(
                            label: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                color: isSelected ? Colors.white : kMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: c,
                            backgroundColor: kSurface2,
                            side: BorderSide(color: isSelected ? c : kBorder),
                            onSelected: (_) =>
                                setState(() => _selectedStatus = status),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Create Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _themeColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Task',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }
}
