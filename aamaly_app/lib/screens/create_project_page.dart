// ============================================
// FILE: lib/screens/create_project_page.dart (UPDATED WITH FIRESTORE)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/project_service.dart';
import '../services/firebase_auth_service.dart';
import '../data/mock_users.dart';
import '../models/user.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({Key? key}) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _projectService = ProjectService();
  final _authService = FirebaseAuthService();

  Color _selectedColor = const Color(0xFF2196F3);
  bool _isLoading = false;

  // Collaborators
  List<User> _allFriends = [];
  List<String> _selectedCollaboratorIds = [];

  // Predefined color palette
  final List<Color> _colorPalette = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFF69B4), // Pink
    const Color(0xFF00CED1), // Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF98FB98), // Light Green
    const Color(0xFFDC143C), // Crimson
    const Color(0xFF9370DB), // Medium Purple
    const Color(0xFFDAA520), // Goldenrod
    const Color(0xFF4169E1), // Royal Blue
    const Color(0xFFFF8C00), // Dark Orange
  ];

  @override
  void initState() {
    super.initState();
    _allFriends = MockUsers.getFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No user logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create project in Firestore
      await _projectService.createProject(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        ownerId: currentUser.id,
        color: _selectedColor,
        collaboratorIds: _selectedCollaboratorIds,
        taskTypes: [], // Empty for now, can be added later
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedCollaboratorIds.isEmpty
                  ? 'Project created successfully!'
                  : 'Project created with ${_selectedCollaboratorIds.length} team members!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to dashboard
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pick a color',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _colorPalette.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCollaboratorSelection() {
    final tempSelected = List<String>.from(_selectedCollaboratorIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Add Team Members',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCollaboratorIds = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done (${tempSelected.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _allFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No friends yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add friends from Collaborators page',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _allFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _allFriends[index];
                          final isSelected = tempSelected.contains(friend.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  tempSelected.add(friend.id);
                                } else {
                                  tempSelected.remove(friend.id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundColor: const Color(0xFF2196F3),
                              child: Text(
                                friend.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            activeColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _selectedColor,
              _selectedColor.withOpacity(0.7),
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
                        'Create a Project',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
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
                          // Name Section
                          Transform.translate(
                            offset: const Offset(0, -15),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _selectedColor,
                                    _selectedColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Name',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText:
                                          'E.g., CREATIVE DESIGN THINKING',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 20,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter project name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Tag/Code
                                  const Text(
                                    'Tag',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _codeController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'E.g., INFO 4321',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter project tag/code';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Date Created + Description
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date Created',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMMM dd, yyyy')
                                      .format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Description
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Enter project description...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter project description';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Collaborators Section
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Team Members (Optional)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _showCollaboratorSelection,
                                      icon: const Icon(Icons.person_add,
                                          size: 18),
                                      label: Text(
                                        _selectedCollaboratorIds.isEmpty
                                            ? 'Add Members'
                                            : 'Edit Members',
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF2196F3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_selectedCollaboratorIds.isEmpty)
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
                                        Icon(Icons.people_outline,
                                            color: Colors.grey[400]),
                                        const SizedBox(width: 12),
                                        Text(
                                          'No team members added',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.group,
                                                color: Color(0xFF2196F3),
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_selectedCollaboratorIds.length} team ${_selectedCollaboratorIds.length == 1 ? 'member' : 'members'} added',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2196F3),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _selectedCollaboratorIds
                                              .map((id) {
                                            final user =
                                                MockUsers.getUserById(id);
                                            if (user == null)
                                              return const SizedBox();

                                            return Chip(
                                              avatar: CircleAvatar(
                                                backgroundColor:
                                                    const Color(0xFF2196F3),
                                                child: Text(
                                                  user.initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              label: Text(user.name),
                                              deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 16),
                                              onDeleted: () {
                                                setState(() {
                                                  _selectedCollaboratorIds
                                                      .remove(id);
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add team members to collaborate on this project',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Pick a color
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pick a color',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ..._colorPalette.take(10).map((color) {
                                      final isSelected =
                                          color.value == _selectedColor.value;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedColor = color;
                                          });
                                        },
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check,
                                                  color: Colors.white, size: 20)
                                              : null,
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: _showColorPicker,
                                      child: Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          gradient: const SweepGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.yellow,
                                              Colors.green,
                                              Colors.cyan,
                                              Colors.blue,
                                              Colors.purple,
                                              Colors.red,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Create Button
                          Transform.translate(
                            offset: const Offset(0, 10),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleCreateProject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedColor,
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
                                      'Create Project',
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
}
