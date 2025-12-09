// ============================================
// FILE: lib/data/mock_reminders.dart
// ============================================

import '../models/reminder.dart';

class MockReminders {
  static List<Reminder> getReminders() {
    return [
      Reminder(
        id: '1',
        name: 'Morning Exercise',
        frequency: ReminderFrequency.daily,
        reminderTime: DateTime(2025, 1, 1, 6, 30),
        description: 'Do morning workout routine',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Reminder(
        id: '2',
        name: 'Review FYP Progress',
        frequency: ReminderFrequency.weekly,
        reminderTime: DateTime(2025, 1, 1, 14, 0),
        description: 'Weekly check on project progress',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Reminder(
        id: '3',
        name: 'Pray Dhuhr',
        frequency: ReminderFrequency.daily,
        reminderTime: DateTime(2025, 1, 1, 13, 0),
        description: 'Time for Dhuhr prayer',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
