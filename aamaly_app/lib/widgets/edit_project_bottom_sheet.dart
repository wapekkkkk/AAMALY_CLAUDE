// ============================================
// FILE: lib/widgets/edit_project_bottom_sheet.dart
// (UPDATED: theme + responsive only)
// ============================================

import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class EditProjectBottomSheet extends StatefulWidget {
  final Project project;

  const EditProjectBottomSheet({super.key, required this.project});

  @override
  State<EditProjectBottomSheet> createState() => _EditProjectBottomSheetState();
}

class _EditProjectBottomSheetState extends State<EditProjectBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;

  late Color _selectedColor;
  bool _isLoading = false;

  final _projectService = ProjectService();

  // Theme (match statistics page)
  static const _bg = Color(0xFF0E141B);
  static const _surface = Color(0xFF121B24);
  static const _surface2 = Color(0xFF0F1720);
  static const _stroke = Color(0xFF223041);
  static const _text = Colors.white;
  static const _muted = Color(0xFF9FB0C0);

  // Predefined color palette (unchanged)
  final List<Color> _colorPalette = [
    const Color(0xFF2196F3),
    const Color(0xFFFF69B4),
    const Color(0xFF00CED1),
    const Color(0xFFFFD700),
    const Color(0xFF98FB98),
    const Color(0xFFDC143C),
    const Color(0xFF9370DB),
    const Color(0xFFDAA520),
    const Color(0xFF4169E1),
    const Color(0xFFFF8C00),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _codeController = TextEditingController(text: widget.project.code);
    _descriptionController =
        TextEditingController(text: widget.project.description);
    _selectedColor = widget.project.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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
        borderSide: BorderSide(color: _selectedColor, width: 2),
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

  Future<void> _handleUpdateProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _projectService.updateProject(
        widget.project.id,
        {
          'name': _nameController.text.trim(),
          'code': _codeController.text.trim(),
          'description': _descriptionController.text.trim(),
          'color': _selectedColor.value,
        },
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      final updatedProject = widget.project.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      );

      Navigator.of(context).pop(updatedProject);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update project: $e'),
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
                        'Edit Project',
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

              // Form content - ✅ Uses the scrollController
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController, // ✅ CRITICAL!
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Project Name
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: _text),
                          decoration: _inputDecoration(
                            label: 'Project Name *',
                            icon: Icons.folder,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter project name';
                            }
                            if (value.trim().length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Project Code
                        TextFormField(
                          controller: _codeController,
                          style: const TextStyle(color: _text),
                          decoration: _inputDecoration(
                            label: 'Project Code *',
                            icon: Icons.tag,
                            helper: 'E.g., INFO4303, FYP, etc.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter project code';
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
                            label: 'Description (Optional)',
                            icon: Icons.description,
                          ).copyWith(alignLabelWithHint: true),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Project Color',
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Color picker
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colorPalette.map((color) {
                            final isSelected =
                                color.value == _selectedColor.value;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: color.withOpacity(0.35),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 26)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 26),

                        // Update Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleUpdateProject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
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
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Update Project',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),

                        // ✅ Extra padding at bottom for keyboard
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
}
