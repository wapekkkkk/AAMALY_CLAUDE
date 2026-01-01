// ============================================
// FILE: lib/services/reminder_notification_scheduler.dart
// REMINDER NOTIFICATION SCHEDULER
// Schedules notifications for calendar reminders
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

  /// Schedule reminder notification
  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      // Cancel existing notification for this reminder
      await cancelReminder(reminder.id);

      // Don't schedule if inactive
      if (!reminder.isActive) return;

      final now = DateTime.now();
      final reminderTime = reminder.reminderTime;

      // Skip if reminder time is in the past
      if (reminderTime.isBefore(now)) {
        // For recurring reminders, schedule next occurrence
        if (reminder.frequency != ReminderFrequency.once) {
          final nextTime =
              _getNextReminderTime(reminderTime, reminder.frequency, now);
          await _scheduleReminderNotification(reminder, nextTime);
        }
        return;
      }

      // Schedule the notification
      await _scheduleReminderNotification(reminder, reminderTime);

      Logger.service('ReminderNotificationScheduler', 'Scheduled',
          'Reminder: ${reminder.name}, Time: $reminderTime');
    } catch (e) {
      Logger.error('Failed to schedule reminder', e);
    }
  }

  /// Schedule reminder notification at specific time
  Future<void> _scheduleReminderNotification(
      Reminder reminder, DateTime scheduledTime) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Your custom reminders',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.mp3',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule based on frequency
      switch (reminder.frequency) {
        case ReminderFrequency.once:
          await _localNotifications.zonedSchedule(
            _getReminderId(reminder.id),
            '🔔 Reminder',
            reminder.name,
            tzScheduledTime,
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: '{"type":"reminder","id":"${reminder.id}"}',
          );
          break;

        case ReminderFrequency.daily:
          await _localNotifications.zonedSchedule(
            _getReminderId(reminder.id),
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
          break;

        case ReminderFrequency.weekly:
          await _localNotifications.zonedSchedule(
            _getReminderId(reminder.id),
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
          break;

        case ReminderFrequency.monthly:
          // Monthly requires manual rescheduling after each occurrence
          await _localNotifications.zonedSchedule(
            _getReminderId(reminder.id),
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
          break;
      }

      Logger.service('ReminderNotificationScheduler', 'Notification Scheduled',
          'Time: $tzScheduledTime, Frequency: ${reminder.frequency}');
    } catch (e) {
      Logger.error('Failed to schedule reminder notification', e);
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
      Logger.service('ReminderNotificationScheduler', 'Cancelled',
          'Reminder: $reminderId');
    } catch (e) {
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
