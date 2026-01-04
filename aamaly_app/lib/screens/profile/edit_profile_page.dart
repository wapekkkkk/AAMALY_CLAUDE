// ============================================
// FILE: lib/screens/edit_profile_page.dart
// UPDATED THEME: Dark + Neon (matches Profile)
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ===== Theme (Dark) =====
  static const Color _bg = Color(0xFF0E141B);
  static const Color _card = Color(0xFF121A23);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF9AA4B2);
  static const Color _accent = Color(0xFF7C4DFF);
  static const Color _accent2 = Color(0xFF00E5FF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  void _loadCurrentName() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'name': _nameController.text.trim(),
          'searchName': _nameController.text.trim().toLowerCase(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userInitials = user?.initials ?? 'U';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update your profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your avatar shows initials',
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DarkTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person,
                      accent: _accent,
                      enabled: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _DarkTextField(
                      initialValue: user?.email ?? '',
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      accent: _accent,
                      enabled: false,
                      helperText: 'Email cannot be changed',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: _accent.withOpacity(0.4),
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
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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

class _DarkTextField extends StatelessWidget {
  static const Color _fieldBg = Color(0xFF0F1720);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF9AA4B2);

  final TextEditingController? controller;
  final String? initialValue;
  final String labelText;
  final IconData prefixIcon;
  final Color accent;
  final bool enabled;
  final String? helperText;
  final String? Function(String?)? validator;

  const _DarkTextField({
    this.controller,
    this.initialValue,
    required this.labelText,
    required this.prefixIcon,
    required this.accent,
    required this.enabled,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: _muted),
        helperText: helperText,
        helperStyle: const TextStyle(color: _muted),
        prefixIcon: Icon(prefixIcon, color: enabled ? accent : _muted),
        filled: true,
        fillColor: _fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }
}
