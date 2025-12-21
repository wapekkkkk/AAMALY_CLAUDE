// ============================================
// FILE: lib/screens/create_task_page.dart (UPDATED WITH FIREBASE)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../data/mock_projects.dart';
import '../models/user.dart';
import '../data/mock_users.dart';
import '../services/project_service.dart'; // ✅ ADD THIS
import '../services/task_service.dart'; // NEW: Import TaskService
import '../services/firebase_auth_service.dart'; // NEW: Import Firebase Auth

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

  // NEW: Firebase services
  final _taskService = TaskService();
  final _authService = FirebaseAuthService();
  final _projectService = ProjectService(); // ✅ ADD THIS

  DateTime? _selectedDeadline;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  String? _selectedProjectName;
  String? _assignedToUserId;

  bool _isLoading = false;
  List<Project> _availableProjects = [];

  Color _themeColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadProjects(); // ✅ LOAD FROM FIREBASE

    if (widget.lockedProjectName != null) {
      _selectedProjectName =
          widget.lockedProjectCode ?? widget.lockedProjectName;
    }
  }

  // ✅ NEW METHOD - Load projects from Firebase
  Future<void> _loadProjects() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        // Get user's projects as a one-time fetch
        final projects =
            await _projectService.getAllUserProjects(currentUserId).first;

        if (mounted) {
          setState(() {
            _availableProjects = projects;
          });
        }
      }
    } catch (e) {
      print('Error loading projects: $e');
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
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  // NEW: Handle task creation with Firebase
  Future<void> _handleCreateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ FIX 1: Get current user ID directly from auth
      final currentUserId = _authService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // ✅ NEW CODE - ADD THIS BLOCK HERE (between FIX 1 and FIX 2)
      // Get the actual project ID
      String? actualProjectId;
      if (widget.project != null) {
        // If project was passed directly, use its ID
        actualProjectId = widget.project!.id;
      } else if (_selectedProjectName != null) {
        // Otherwise, find the project by name/code
        try {
          final selectedProject = _availableProjects.firstWhere(
            (p) =>
                p.code == _selectedProjectName ||
                p.name == _selectedProjectName,
          );
          actualProjectId = selectedProject.id;
        } catch (e) {
          actualProjectId = null; // No project found
        }
      }
      // ✅ END OF NEW CODE

      // ✅ FIX 2: Call createTask with your service's parameters
      final taskId = await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline!,
        status: TaskService.taskStatusToString(_selectedStatus),
        priority: TaskService.taskPriorityToString(_selectedPriority),
        projectName: _selectedProjectName ?? 'No Project',
        createdBy: currentUserId,
        projectId:
            actualProjectId, // ✅ CHANGE THIS FROM null to actualProjectId
        assignedToUserId: _assignedToUserId,
      );

      // Create task object for returning to previous screen
      final createdTask = Task(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline!,
        status: _selectedStatus,
        priority: _selectedPriority,
        projectName: _selectedProjectName ?? 'No Project',
        assignedToUserId: _assignedToUserId,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Return the created task
        Navigator.of(context).pop(createdTask);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _assignedToUserId != null
                  ? 'Task created and assigned successfully!'
                  : 'Task created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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
    if (widget.project != null) {
      return widget.project!.hasCollaborators;
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
          ownerId: '1',
          collaboratorIds: [],
        ),
      );
      return project.hasCollaborators;
    }

    return false;
  }

  List<User> _getProjectCollaborators() {
    Project? currentProject;

    if (widget.project != null) {
      currentProject = widget.project;
    } else if (_selectedProjectName != null) {
      try {
        currentProject = _availableProjects.firstWhere(
          (p) =>
              p.code == _selectedProjectName || p.name == _selectedProjectName,
        );
      } catch (e) {
        currentProject = null;
      }
    }

    if (currentProject == null || currentProject.collaboratorIds.isEmpty) {
      return [];
    }

    return currentProject.collaboratorIds
        .map((id) => MockUsers.getUserById(id))
        .whereType<User>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.lockedProjectName != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _themeColor,
              _themeColor.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Create New Task',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),

              // Form Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title and Description Section
                          Transform.translate(
                            offset: const Offset(0, -15),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _themeColor,
                                    _themeColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Title',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _titleController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'E.g., Complete FYP Chapter 3',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 20,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter task title';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Title must be at least 3 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _descriptionController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Describe the task in detail...',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter task description';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Project, Assign, Deadline Section
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Project',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (isLocked)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lock,
                                            color: Colors.grey, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.lockedProjectName!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedProjectName,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.folder_outlined),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      hint: const Text(
                                          'Select a project (Optional)'),
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('No Project'),
                                        ),
                                        ..._availableProjects.map((project) {
                                          return DropdownMenuItem(
                                            value: project.code,
                                            child: Text(
                                                '${project.name} (${project.code})'),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProjectName = value;
                                        });
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Assign To (if collaborative project)
                                if (_shouldShowAssignField())
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Assign To',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: _assignedToUserId,
                                          decoration: const InputDecoration(
                                            prefixIcon:
                                                Icon(Icons.person_outline),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                          hint: const Text(
                                              'Select team member (Optional)'),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text('Unassigned'),
                                            ),
                                            ..._getProjectCollaborators()
                                                .map((user) {
                                              return DropdownMenuItem(
                                                value: user.id,
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF2196F3),
                                                      child: Text(
                                                        user.initials,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(user.name),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _assignedToUserId = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Deadline
                                const Text(
                                  'Deadline',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectDeadline,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[50],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: _themeColor, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedDeadline == null
                                                ? 'Select deadline date'
                                                : DateFormat(
                                                        'EEEE, MMM dd, yyyy')
                                                    .format(_selectedDeadline!),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _selectedDeadline == null
                                                  ? Colors.grey[600]
                                                  : const Color(0xFF1A1A2E),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Priority and Status
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Priority',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: TaskPriority.values.map((priority) {
                                    final isSelected =
                                        _selectedPriority == priority;
                                    return Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: ChoiceChip(
                                          label: Text(
                                            _getPriorityText(priority),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor:
                                              _getPriorityColor(priority),
                                          backgroundColor:
                                              _getPriorityColor(priority)
                                                  .withOpacity(0.1),
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedPriority = priority;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: TaskStatus.values.map((status) {
                                    final isSelected =
                                        _selectedStatus == status;
                                    return ChoiceChip(
                                      label: Text(
                                        _getStatusText(status),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: _getStatusColor(status),
                                      backgroundColor: _getStatusColor(status)
                                          .withOpacity(0.1),
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedStatus = status;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Create Button
                          Transform.translate(
                            offset: const Offset(0, 10),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleCreateTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Create Task',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
