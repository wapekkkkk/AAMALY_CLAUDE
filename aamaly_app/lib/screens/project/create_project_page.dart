// ============================================
// FILE: lib/screens/create_project_page.dart (DARK THEME + COLOR-CODED PREVIEW)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/project_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/friend_service.dart';
import '../../models/user.dart' as app_user;

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
  final _friendService = FriendService();

  Color _selectedColor = const Color(0xFF2196F3);
  bool _isLoading = false;

  // Collaborators
  List<app_user.User> _allFriends = [];
  List<String> _selectedCollaboratorIds = [];
  bool _isLoadingFriends = true;

  // Optional: collaborator search in bottom sheet
  String _friendSearchQuery = '';

  // Predefined color palette
  final List<Color> _colorPalette = [
    Color(0xFF2196F3), // Blue
    Color(0xFFFF69B4), // Pink
    Color(0xFF00CED1), // Cyan
    Color(0xFFFFD700), // Gold
    Color(0xFF98FB98), // Light Green
    Color(0xFFDC143C), // Crimson
    Color(0xFF9370DB), // Medium Purple
    Color(0xFFDAA520), // Goldenrod
    Color(0xFF4169E1), // Royal Blue
    Color(0xFFFF8C00), // Dark Orange
  ];

  // Dark theme colors (match FriendsPage)
  static const Color _bg = Color(0xFF0E141B);
  static const Color _appBarBg = Color(0xFF0B0F14);
  static const Color _surface = Color(0xFF121A23);
  static const Color _surface2 = Color(0xFF0F1720);
  static const Color _border = Color(0xFF1F2A37);
  static const Color _text = Color(0xFFEAF0F7);
  static const Color _muted = Color(0xFF9AA6B2);

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        final friends =
            await _friendService.getFriendsWithDetails(currentUserId);
        if (!mounted) return;
        setState(() {
          _allFriends = friends;
          _isLoadingFriends = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingFriends = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFriends = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load friends: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProject() async {
    if (!_formKey.currentState!.validate()) return;

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

    setState(() => _isLoading = true);

    try {
      await _projectService.createProject(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        ownerId: currentUser.id,
        color: _selectedColor, // ✅ this is what makes it color-coded later
        collaboratorIds: _selectedCollaboratorIds,
        taskTypes: [],
      );

      if (!mounted) return;

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

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _border)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pick a color',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _text),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _colorPalette.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCollaboratorSelection() {
    final tempSelected = List<String>.from(_selectedCollaboratorIds);
    _friendSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final friendsFiltered = _allFriends.where((f) {
            if (_friendSearchQuery.trim().isEmpty) return true;
            final q = _friendSearchQuery.toLowerCase();
            return f.name.toLowerCase().contains(q) ||
                f.email.toLowerCase().contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: _text),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Add Team Members',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _text),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(
                              () => _selectedCollaboratorIds = tempSelected);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Done (${tempSelected.length})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _border),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: TextField(
                    onChanged: (v) =>
                        setModalState(() => _friendSearchQuery = v),
                    style: const TextStyle(color: _text),
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: const TextStyle(color: _muted),
                      prefixIcon: Icon(Icons.search, color: _selectedColor),
                      filled: true,
                      fillColor: _surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: _selectedColor, width: 1.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoadingFriends
                      ? const Center(child: CircularProgressIndicator())
                      : _allFriends.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.people_outline,
                                      size: 64, color: Colors.white30),
                                  SizedBox(height: 12),
                                  Text('No friends yet',
                                      style: TextStyle(
                                          fontSize: 16, color: _text)),
                                  SizedBox(height: 6),
                                  Text('Add friends from Friends page',
                                      style: TextStyle(
                                          fontSize: 13, color: _muted)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: friendsFiltered.length,
                              itemBuilder: (context, index) {
                                final friend = friendsFiltered[index];
                                final isSelected =
                                    tempSelected.contains(friend.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: _surface2,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? _selectedColor.withOpacity(0.8)
                                          : _border,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (checked) {
                                      setModalState(() {
                                        if (checked == true) {
                                          if (!tempSelected.contains(friend.id))
                                            tempSelected.add(friend.id);
                                        } else {
                                          tempSelected.remove(friend.id);
                                        }
                                      });
                                    },
                                    secondary: CircleAvatar(
                                      backgroundColor: _selectedColor,
                                      child: Text(
                                        friend.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(friend.name,
                                        style: const TextStyle(
                                            color: _text,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(friend.email,
                                        style: const TextStyle(
                                            color: _muted, fontSize: 12)),
                                    activeColor: _selectedColor,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  app_user.User? _getUserById(String id) {
    try {
      return _allFriends.firstWhere((friend) => friend.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _livePreviewCard() {
    final name = _nameController.text.trim().isEmpty
        ? 'Project Name'
        : _nameController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? 'CODE 1234'
        : _codeController.text.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 52,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: _selectedColor.withOpacity(0.35)),
                      ),
                      child: Text(code,
                          style: TextStyle(
                              color: _selectedColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text('Color-coded',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.circle, size: 10, color: _selectedColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create a Project',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color-coded header card (like your screenshot)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedColor,
                        _selectedColor.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Name',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        onChanged: (_) =>
                            setState(() {}), // update live preview
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'E.g., CREATIVE DESIGN THINKING',
                          hintStyle:
                              TextStyle(color: Colors.white70, fontSize: 18),
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter project name'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      const Text('Tag',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeController,
                        onChanged: (_) =>
                            setState(() {}), // update live preview
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'E.g., INFO 4321',
                          hintStyle:
                              TextStyle(color: Colors.white70, fontSize: 16),
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter project tag/code'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ Live preview of the color-coded project card
                const Text('Live Preview',
                    style:
                        TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _livePreviewCard(),

                const SizedBox(height: 20),

                // Date Created
                const Text('Date Created',
                    style:
                        TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                      color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 18),

                // Description
                const Text('Description',
                    style:
                        TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: _text),
                  decoration: InputDecoration(
                    hintText: 'Enter project description...',
                    hintStyle: const TextStyle(color: _muted),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _selectedColor, width: 1.4),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter project description'
                      : null,
                ),

                const SizedBox(height: 18),

                // Team Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Team Members (Optional)',
                        style: TextStyle(
                            color: _muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCollaboratorSelection,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: Text(
                        _selectedCollaboratorIds.isEmpty
                            ? 'Add'
                            : 'Edit', // ✅ Shorter text
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // ✅ OUTSIDE the Row!

                if (_selectedCollaboratorIds.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.people_outline, color: Colors.white30),
                        SizedBox(width: 10),
                        Text('No team members added',
                            style: TextStyle(color: _muted)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: _selectedColor.withOpacity(0.45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.group, color: _selectedColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedCollaboratorIds.length} team ${_selectedCollaboratorIds.length == 1 ? 'member' : 'members'} added',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedCollaboratorIds.map((id) {
                            final user = _getUserById(id);
                            if (user == null) return const SizedBox.shrink();

                            return Chip(
                              backgroundColor: _selectedColor.withOpacity(0.14),
                              side: BorderSide(
                                  color: _selectedColor.withOpacity(0.35)),
                              avatar: CircleAvatar(
                                backgroundColor: _selectedColor,
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              label: Text(user.name,
                                  style: const TextStyle(color: _text)),
                              deleteIcon: const Icon(Icons.close,
                                  size: 16, color: _text),
                              onDeleted: () {
                                setState(
                                    () => _selectedCollaboratorIds.remove(id));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
                const Text('Add team members to collaborate on this project',
                    style: TextStyle(color: _muted, fontSize: 12)),

                const SizedBox(height: 18),

                // Pick a color
                const Text('Pick a color',
                    style:
                        TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ..._colorPalette.map((color) {
                      final isSelected = color.value == _selectedColor.value;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.25),
                                blurRadius: 8,
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
                        width: 44,
                        height: 44,
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
                          border: Border.all(color: _border, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Create Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
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
                      : const Text('Create Project',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
