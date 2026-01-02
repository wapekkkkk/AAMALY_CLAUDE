// ============================================
// FILE: lib/services/reminder_service.dart
// REMINDER CRUD OPERATIONS
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import 'reminder_notification_scheduler.dart'; // ✅ keep ONLY ONE import

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // CREATE
  // ============================================

  /// Create a new reminder
  Future<String> createReminder({
    required String userId,
    required String name,
    required ReminderFrequency frequency,
    required DateTime reminderTime,
    String? description,
  }) async {
    try {
      Logger.service('ReminderService', 'createReminder', 'name: $name');

      final docRef = await _firestore.collection('reminders').add({
        'userId': userId,
        'name': name,
        'frequency': _frequencyToString(frequency),
        'reminderTime': Timestamp.fromDate(reminderTime),
        'description': description ?? '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Logger.database('CREATE', 'reminders', docRef.id);

      // ✅ Schedule notification (use the SAME scheduler signature everywhere)
      final reminder = Reminder(
        id: docRef.id,
        name: name,
        frequency: frequency,
        reminderTime: reminderTime,
        description: description ?? '',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await ReminderNotificationScheduler().scheduleReminder(reminder);

      Logger.success('Reminder created: ${docRef.id}', 'ReminderService');
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create reminder', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // READ
  // ============================================

  /// Get all reminders for a user (real-time)
  Stream<List<Reminder>> getUserReminders(String userId) {
    Logger.service('ReminderService', 'getUserReminders', 'userId: $userId');

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Commented until index builds
        .snapshots()
        .map((snapshot) {
      final reminders = snapshot.docs.map((doc) {
        return _reminderFromFirestore(doc);
      }).toList();

      // Sort in memory
      reminders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reminders;
    });
  }

  /// Get active reminders only
  Stream<List<Reminder>> getActiveReminders(String userId) {
    Logger.service('ReminderService', 'getActiveReminders', 'userId: $userId');

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final reminders = snapshot.docs.map((doc) {
        return _reminderFromFirestore(doc);
      }).toList();

      reminders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reminders;
    });
  }

  /// Get single reminder by ID
  Future<Reminder?> getReminderById(String reminderId) async {
    try {
      Logger.service('ReminderService', 'getReminderById', 'id: $reminderId');

      final doc =
          await _firestore.collection('reminders').doc(reminderId).get();

      if (!doc.exists) {
        Logger.warning('Reminder not found: $reminderId', 'ReminderService');
        return null;
      }

      return _reminderFromFirestore(doc);
    } catch (e) {
      Logger.error('Failed to get reminder', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // UPDATE
  // ============================================

  /// Update reminder details
  Future<void> updateReminder(
    String reminderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      Logger.service('ReminderService', 'updateReminder', 'id: $reminderId');

      // Convert frequency enum to string if present
      if (updates.containsKey('frequency') &&
          updates['frequency'] is ReminderFrequency) {
        updates['frequency'] = _frequencyToString(updates['frequency']);
      }

      // Convert DateTime to Timestamp if present
      if (updates.containsKey('reminderTime') &&
          updates['reminderTime'] is DateTime) {
        updates['reminderTime'] =
            Timestamp.fromDate(updates['reminderTime'] as DateTime);
      }

      await _firestore.collection('reminders').doc(reminderId).update(updates);

      Logger.database('UPDATE', 'reminders', reminderId);

      // ✅ Reschedule notification
      final reminder = await getReminderById(reminderId);
      if (reminder != null) {
        await ReminderNotificationScheduler().scheduleReminder(reminder);
      }

      Logger.success('Reminder updated', 'ReminderService');
    } catch (e) {
      Logger.error('Failed to update reminder', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Toggle reminder active status
  Future<void> toggleReminder(String reminderId, bool isActive) async {
    try {
      Logger.service(
        'ReminderService',
        'toggleReminder',
        'id: $reminderId, active: $isActive',
      );

      await _firestore.collection('reminders').doc(reminderId).update({
        'isActive': isActive,
      });

      Logger.database('UPDATE', 'reminders', reminderId);

      // ✅ Handle notification based on active status
      if (isActive) {
        final reminder = await getReminderById(reminderId);
        if (reminder != null) {
          await ReminderNotificationScheduler().scheduleReminder(reminder);
        }
      } else {
        await ReminderNotificationScheduler().cancelReminder(reminderId);
      }

      Logger.success(
        'Reminder ${isActive ? "activated" : "deactivated"}',
        'ReminderService',
      );
    } catch (e) {
      Logger.error('Failed to toggle reminder', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // DELETE
  // ============================================

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      Logger.service('ReminderService', 'deleteReminder', 'id: $reminderId');

      // ✅ Cancel notification first
      await ReminderNotificationScheduler().cancelReminder(reminderId);

      await _firestore.collection('reminders').doc(reminderId).delete();

      Logger.database('DELETE', 'reminders', reminderId);
      Logger.success('Reminder deleted', 'ReminderService');
    } catch (e) {
      Logger.error('Failed to delete reminder', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Delete all reminders for a user
  Future<void> deleteUserReminders(String userId) async {
    try {
      Logger.service(
          'ReminderService', 'deleteUserReminders', 'userId: $userId');

      final reminders = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .get();

      // ✅ Cancel all notifications
      for (var doc in reminders.docs) {
        await ReminderNotificationScheduler().cancelReminder(doc.id);
      }

      final batch = _firestore.batch();
      for (var doc in reminders.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Logger.success('All user reminders deleted', 'ReminderService');
    } catch (e) {
      Logger.error('Failed to delete user reminders', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Convert Firestore document to Reminder model
  Reminder _reminderFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Reminder(
      id: doc.id,
      name: data['name'] ?? '',
      frequency: _stringToFrequency(data['frequency'] ?? 'daily'),
      reminderTime:
          (data['reminderTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert frequency enum to string
  String _frequencyToString(ReminderFrequency frequency) {
    return frequency.toString().split('.').last;
  }

  /// Convert string to frequency enum
  ReminderFrequency _stringToFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'once':
        return ReminderFrequency.once;
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.monthly;
      default:
        return ReminderFrequency.daily;
    }
  }

  /// Helper: Get frequency text
  static String getFrequencyText(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }

  /// Helper: Get frequency color
  static Color getFrequencyColor(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.once:
        return const Color(0xFF2196F3); // Blue
      case ReminderFrequency.daily:
        return const Color(0xFF4CAF50); // Green
      case ReminderFrequency.weekly:
        return const Color(0xFFFF9800); // Orange
      case ReminderFrequency.monthly:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}
