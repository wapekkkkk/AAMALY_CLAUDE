// ============================================
// FILE: lib/screens/create_reminder_page.dart (THEME UPDATED - DARK + PINK)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reminder.dart';
import '../../services/reminder_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/logger.dart';
import '../../utils/error_handler.dart';

class CreateReminderPage extends StatefulWidget {
  const CreateReminderPage({Key? key}) : super(key: key);

  @override
  State<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends State<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _reminderService = ReminderService();
  final _authService = FirebaseAuthService();

  ReminderFrequency _selectedFrequency = ReminderFrequency.daily;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  // ✅ Theme tokens (keep consistent)
  static const _bg = Color(0xFF0E141B);
  static const _card = Color(0xFF121B24);
  static const _card2 = Color(0xFF0F1720);
  static const _stroke = Color(0xFF253241);

  static const _accent = Color(0xFFFF69B4); // ✅ keep pink
  static const _text = Color(0xFFEAF0F7);
  static const _muted = Color(0xFF9AA7B4);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        // ✅ keep time picker pink
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: Color(0xFF0F1720),
              onSurface: _text,
            ),
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: _accent,
              hourMinuteColor: Color(0xFF121B24),
              hourMinuteTextColor: _text,
              dayPeriodColor: Color(0xFF121B24),
              dayPeriodTextColor: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleCreateReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a reminder'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Logger.info('Creating reminder...', 'CreateReminderPage');

      final now = DateTime.now();
      final reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _reminderService.createReminder(
        userId: currentUserId,
        name: _nameController.text.trim(),
        frequency: _selectedFrequency,
        reminderTime: reminderDateTime,
        description: _descriptionController.text.trim(),
      );

      setState(() => _isLoading = false);

      Logger.success('Reminder created successfully', 'CreateReminderPage');

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      Logger.error('Failed to create reminder', e);
      if (mounted) setState(() => _isLoading = false);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Reminder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header card (pink gradient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accent.withOpacity(0.95),
                        const Color(0xFF7C4DFF).withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay on track',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create a reminder and Aamaly will notify you at the right time.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _sectionTitle('Reminder Name'),
                const SizedBox(height: 10),
                _darkField(
                  controller: _nameController,
                  hint: 'E.g., Morning Study Session',
                  icon: Icons.notifications_active,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reminder name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _sectionTitle('Description (Optional)'),
                const SizedBox(height: 10),
                _darkField(
                  controller: _descriptionController,
                  hint: 'Add any notes…',
                  icon: Icons.notes,
                  maxLines: 3,
                ),

                const SizedBox(height: 18),

                _sectionTitle('Frequency'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ReminderFrequency.values.map((frequency) {
                    final isSelected = _selectedFrequency == frequency;
                    final freqColor =
                        ReminderService.getFrequencyColor(frequency);

                    return ChoiceChip(
                      label: Text(ReminderService.getFrequencyText(frequency)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFrequency = frequency);
                        }
                      },
                      // ✅ dark theme chip
                      backgroundColor: _card,
                      selectedColor: _accent.withOpacity(0.18),
                      side: BorderSide(
                        color: isSelected ? _accent : _stroke,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? _accent : _text,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      checkmarkColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                _sectionTitle('Reminder Time'),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _selectTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _stroke),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: _accent),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: _muted.withOpacity(0.9)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _accent.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'You can edit or delete reminders anytime.',
                    style: TextStyle(
                        color: _muted.withOpacity(0.95), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // UI helpers
  // =========================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _text,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stroke),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
        cursorColor: _accent,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _accent),
          hintText: hint,
          hintStyle: TextStyle(color: _muted.withOpacity(0.9)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
