// ============================================
// FILE: lib/models/reminder.dart
// ============================================

enum ReminderFrequency { once, daily, weekly, monthly }

class Reminder {
  final String id;
  final String name;
  final ReminderFrequency frequency;
  final DateTime reminderTime;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.name,
    required this.frequency,
    required this.reminderTime,
    required this.description,
    this.isActive = true,
    required this.createdAt,
  });

  Reminder copyWith({
    String? id,
    String? name,
    ReminderFrequency? frequency,
    DateTime? reminderTime,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
