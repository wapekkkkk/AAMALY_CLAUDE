// ============================================
// FILE: lib/services/reminder_notification_scheduler.dart
// REMINDER NOTIFICATION SCHEDULER (CORRECT - Accepts Reminder object)
// ============================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import '../utils/logger.dart';

class ReminderNotificationScheduler {
  static final ReminderNotificationScheduler _instance =
      ReminderNotificationScheduler._internal();
  factory ReminderNotificationScheduler() => _instance;
  ReminderNotificationScheduler._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================
  // SCHEDULE REMINDER NOTIFICATIONS
  // ============================================

  /// Schedule reminder notification (✅ CORRECT - Accepts Reminder object)
  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      print(
          '🔍 Scheduling reminder: ${reminder.name} at ${reminder.reminderTime}');

      // Cancel existing notification for this reminder
      await cancelReminder(reminder.id);

      // Don't schedule if inactive
      if (!reminder.isActive) {
        print('⏸️ Reminder is inactive, not scheduling');
        return;
      }

      final now = DateTime.now();
      final reminderTime = reminder.reminderTime;

      // Skip if reminder time is in the past
      if (reminderTime.isBefore(now)) {
        print('⚠️ Reminder time is in the past: $reminderTime');

        // For recurring reminders, schedule next occurrence
        if (reminder.frequency != ReminderFrequency.once) {
          final nextTime =
              _getNextReminderTime(reminderTime, reminder.frequency, now);
          print('📅 Scheduling next occurrence at: $nextTime');

          await _scheduleReminderNotification(reminder, nextTime);
        } else {
          print('⏭️ One-time reminder in the past, skipping');
        }
        return;
      }

      // Schedule the notification
      await _scheduleReminderNotification(reminder, reminderTime);

      print('✅ Reminder scheduled successfully!');

      Logger.service('ReminderNotificationScheduler', 'Scheduled',
          'Reminder: ${reminder.name}, Time: $reminderTime');
    } catch (e) {
      print('❌ Failed to schedule reminder: $e');
      Logger.error('Failed to schedule reminder', e);
    }
  }

  /// Schedule reminder notification at specific time
  Future<void> _scheduleReminderNotification(
    Reminder reminder,
    DateTime scheduledTime,
  ) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      print('🔔 Scheduling notification for: $tzScheduledTime');

      const androidDetails = AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Your custom reminders',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = _getReminderId(reminder.id);
      print('🆔 Notification ID: $notificationId');

      // Schedule based on frequency
      switch (reminder.frequency) {
        case ReminderFrequency.once:
          await _localNotifications.zonedSchedule(
            notificationId,
            '🔔 Reminder',
            reminder.name,
            tzScheduledTime,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: '{"type":"reminder","id":"${reminder.id}"}',
          );
          print('✅ One-time reminder scheduled');
          break;

        case ReminderFrequency.daily:
          await _localNotifications.zonedSchedule(
            notificationId,
            '🔔 Daily Reminder',
            reminder.name,
            tzScheduledTime,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
            payload: '{"type":"reminder","id":"${reminder.id}"}',
          );
          print('✅ Daily reminder scheduled');
          break;

        case ReminderFrequency.weekly:
          await _localNotifications.zonedSchedule(
            notificationId,
            '🔔 Weekly Reminder',
            reminder.name,
            tzScheduledTime,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents:
                DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
            payload: '{"type":"reminder","id":"${reminder.id}"}',
          );
          print('✅ Weekly reminder scheduled');
          break;

        case ReminderFrequency.monthly:
          // Monthly requires manual rescheduling after each occurrence
          await _localNotifications.zonedSchedule(
            notificationId,
            '🔔 Monthly Reminder',
            reminder.name,
            tzScheduledTime,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload:
                '{"type":"reminder","id":"${reminder.id}","reschedule":"monthly"}',
          );
          print('✅ Monthly reminder scheduled');
          break;
      }

      Logger.service('ReminderNotificationScheduler', 'Notification Scheduled',
          'Time: $tzScheduledTime, Frequency: ${reminder.frequency}');
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
      Logger.error('Failed to schedule reminder notification', e);
      rethrow;
    }
  }

  /// Get next reminder time based on frequency
  DateTime _getNextReminderTime(
      DateTime lastTime, ReminderFrequency frequency, DateTime now) {
    switch (frequency) {
      case ReminderFrequency.daily:
        var next = DateTime(
            now.year, now.month, now.day, lastTime.hour, lastTime.minute);
        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case ReminderFrequency.weekly:
        var next = DateTime(
            now.year, now.month, now.day, lastTime.hour, lastTime.minute);
        while (next.isBefore(now) || next.weekday != lastTime.weekday) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case ReminderFrequency.monthly:
        var next = DateTime(
            now.year, now.month, lastTime.day, lastTime.hour, lastTime.minute);
        if (next.isBefore(now)) {
          // Move to next month
          if (now.month == 12) {
            next = DateTime(
                now.year + 1, 1, lastTime.day, lastTime.hour, lastTime.minute);
          } else {
            next = DateTime(now.year, now.month + 1, lastTime.day,
                lastTime.hour, lastTime.minute);
          }
        }
        return next;

      case ReminderFrequency.once:
      default:
        return lastTime;
    }
  }

  // ============================================
  // CANCEL NOTIFICATIONS
  // ============================================

  /// Cancel reminder notification
  Future<void> cancelReminder(String reminderId) async {
    try {
      await _localNotifications.cancel(_getReminderId(reminderId));
      print('🗑️ Cancelled reminder: $reminderId');

      Logger.service('ReminderNotificationScheduler', 'Cancelled',
          'Reminder: $reminderId');
    } catch (e) {
      print('❌ Failed to cancel reminder: $e');
      Logger.error('Failed to cancel reminder', e);
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Generate unique notification ID for reminder
  int _getReminderId(String reminderId) {
    return reminderId.hashCode.abs() % 100000000;
  }
}
