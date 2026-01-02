// ============================================
// FILE: lib/widgets/edit_task_bottom_sheet.dart
// (UPDATED: theme + responsive only)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../data/mock_projects.dart';
import '../services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskBottomSheet extends StatefulWidget {
  final Task task;

  const EditTaskBottomSheet({super.key, required this.task});

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late DateTime _selectedDeadline;
  late TaskPriority _selectedPriority;
  late TaskStatus _selectedStatus;
  late String _selectedProjectName;

  bool _isLoading = false;
  List<Project> _availableProjects = [];
  final _taskService = TaskService();

  // Theme (match statistics page)
  static const _bg = Color(0xFF0E141B);
  static const _surface = Color(0xFF121B24);
  static const _surface2 = Color(0xFF0F1720);
  static const _stroke = Color(0xFF223041);
  static const _text = Colors.white;
  static const _muted = Color(0xFF9FB0C0);
  static const _accent = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _availableProjects = MockProjects.getProjects();

    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedDeadline = widget.task.deadline;
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;
    _selectedProjectName = widget.task.projectName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      labelStyle: const TextStyle(color: _muted),
      helperStyle: const TextStyle(color: _muted),
      prefixIcon: Icon(icon, color: _muted),
      filled: true,
      fillColor: _surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: _surface,
              onSurface: _text,
            ),
            dialogBackgroundColor: _surface2,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _handleSaveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _taskService.updateTask(
        widget.task.id,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'deadline': Timestamp.fromDate(_selectedDeadline),
          'status': TaskService.taskStatusToString(_selectedStatus),
          'priority': TaskService.taskPriorityToString(_selectedPriority),
          'projectName': _selectedProjectName,
        },
      );

      final updatedTask = Task(
        id: widget.task.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline,
        status: _selectedStatus,
        priority: _selectedPriority,
        projectName: _selectedProjectName,
        assignedToUserId: widget.task.assignedToUserId,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.of(context).pop(updatedTask);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: _text),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Task',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const Divider(height: 1, color: _stroke),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController, // ✅ CRITICAL!
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Task Title
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: _text),
                          decoration: _inputDecoration(
                            label: 'Task Title *',
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

                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: _text),
                          maxLines: 3,
                          decoration: _inputDecoration(
                            label: 'Description *',
                            icon: Icons.description,
                          ).copyWith(alignLabelWithHint: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter task description';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Project dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedProjectName,
                          dropdownColor: _surface2,
                          style: const TextStyle(color: _text),
                          decoration: _inputDecoration(
                            label: 'Project',
                            icon: Icons.folder_outlined,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: _selectedProjectName,
                              child: Text(
                                _selectedProjectName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _text),
                              ),
                            ),
                            ..._availableProjects
                                .where((p) =>
                                    p.code != _selectedProjectName &&
                                    p.name != _selectedProjectName)
                                .map((project) {
                              return DropdownMenuItem(
                                value: project.code,
                                child: Text(
                                  '${project.name} (${project.code})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _text),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _selectedProjectName = value);
                          },
                          iconEnabledColor: _muted,
                        ),

                        const SizedBox(height: 14),

                        // Deadline
                        InkWell(
                          onTap: _selectDeadline,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _stroke),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: _accent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Deadline *',
                                        style: TextStyle(
                                            fontSize: 12, color: _muted),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, MMM dd, yyyy')
                                            .format(_selectedDeadline),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: _text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit, size: 16, color: _muted),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Priority
                        const Text(
                          'Priority *',
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: TaskPriority.values.map((priority) {
                            final isSelected = _selectedPriority == priority;
                            final c = _getPriorityColor(priority);

                            return ChoiceChip(
                              label: Text(_getPriorityText(priority)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedPriority = priority),
                              labelStyle: TextStyle(
                                color: isSelected ? c : _text.withOpacity(0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              backgroundColor: _surface,
                              selectedColor: c.withOpacity(0.18),
                              side: BorderSide(
                                color: isSelected ? c : _stroke,
                                width: 1.2,
                              ),
                              checkmarkColor: c,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 18),

                        // Status
                        const Text(
                          'Status *',
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: TaskStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            final c = _getStatusColor(status);

                            return ChoiceChip(
                              label: Text(_getStatusText(status)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedStatus = status),
                              labelStyle: TextStyle(
                                color: isSelected ? c : _text.withOpacity(0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              backgroundColor: _surface,
                              selectedColor: c.withOpacity(0.18),
                              side: BorderSide(
                                color: isSelected ? c : _stroke,
                                width: 1.2,
                              ),
                              checkmarkColor: c,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 22),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSaveTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800),
                                ),
                        ),

                        const SizedBox(height: 12),

                        // Cancel Button
                        OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _text,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: _stroke),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),

                        // ✅ Extra padding for keyboard
                        SizedBox(
                            height:
                                MediaQuery.of(context).viewInsets.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
