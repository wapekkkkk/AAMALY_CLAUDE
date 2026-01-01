// ============================================
// FILE: lib/services/deadline_notification_scheduler.dart
// DEADLINE NOTIFICATION SCHEDULER
// Schedules notifications for task deadlines
// ============================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../utils/logger.dart';

class DeadlineNotificationScheduler {
  static final DeadlineNotificationScheduler _instance =
      DeadlineNotificationScheduler._internal();
  factory DeadlineNotificationScheduler() => _instance;
  DeadlineNotificationScheduler._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================
  // SCHEDULE DEADLINE NOTIFICATIONS
  // ============================================

  /// Schedule all deadline notifications for a task
  Future<void> scheduleTaskDeadlineNotifications(Task task) async {
    try {
      // Cancel existing notifications for this task
      await cancelTaskNotifications(task.id);

      final now = DateTime.now();
      final deadline = task.deadline;

      // Skip if task is completed or overdue
      if (task.status == TaskStatus.completed || deadline.isBefore(now)) {
        return;
      }

      // Schedule notifications
      await _schedule3DayReminder(task, now, deadline);
      await _schedule1DayReminder(task, now, deadline);
      await _scheduleMorningReminder(task, now, deadline);
      await _scheduleOverdueNotification(task, now, deadline);

      Logger.service('DeadlineNotificationScheduler', 'Scheduled',
          'Task: ${task.title}, Deadline: $deadline');
    } catch (e) {
      Logger.error('Failed to schedule deadline notifications', e);
    }
  }

  /// Schedule 3-day reminder
  Future<void> _schedule3DayReminder(
      Task task, DateTime now, DateTime deadline) async {
    final reminderTime = deadline.subtract(const Duration(days: 3));

    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: _getNotificationId(task.id, 'three_days'),
        title: '⏰ Deadline Reminder',
        body: '${task.title} is due in 3 days',
        scheduledTime: reminderTime,
        payload: '{"type":"task","id":"${task.id}","action":"view"}',
        channelId: 'deadline_reminders',
      );
    }
  }

  /// Schedule 1-day reminder (tomorrow)
  Future<void> _schedule1DayReminder(
      Task task, DateTime now, DateTime deadline) async {
    final reminderTime = deadline.subtract(const Duration(days: 1));

    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: _getNotificationId(task.id, 'one_day'),
        title: '⚠️ Due Tomorrow',
        body: '${task.title} is due tomorrow!',
        scheduledTime: reminderTime,
        payload: '{"type":"task","id":"${task.id}","action":"view"}',
        channelId: 'deadline_reminders',
      );
    }
  }

  /// Schedule morning of deadline reminder (8 AM)
  Future<void> _scheduleMorningReminder(
      Task task, DateTime now, DateTime deadline) async {
    final morningOfDeadline = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
      8, // 8 AM
      0,
    );

    if (morningOfDeadline.isAfter(now) &&
        morningOfDeadline.isBefore(deadline)) {
      await _scheduleNotification(
        id: _getNotificationId(task.id, 'morning'),
        title: '🔴 Due Today',
        body: '${task.title} is due today!',
        scheduledTime: morningOfDeadline,
        payload: '{"type":"task","id":"${task.id}","action":"view"}',
        channelId: 'deadline_reminders',
      );
    }
  }

  /// Schedule overdue notification
  Future<void> _scheduleOverdueNotification(
      Task task, DateTime now, DateTime deadline) async {
    // Schedule 1 hour after deadline
    final overdueTime = deadline.add(const Duration(hours: 1));

    if (overdueTime.isAfter(now)) {
      await _scheduleNotification(
        id: _getNotificationId(task.id, 'overdue'),
        title: '❌ Task Overdue',
        body: '${task.title} is now overdue',
        scheduledTime: overdueTime,
        payload: '{"type":"task","id":"${task.id}","action":"view"}',
        channelId: 'deadline_reminders',
      );
    }
  }

  /// Schedule a notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
  }) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId,
        channelDescription: 'Deadline notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      Logger.service('DeadlineNotificationScheduler', 'Scheduled',
          'ID: $id at $scheduledTime');
    } catch (e) {
      Logger.error('Failed to schedule notification', e);
    }
  }

  // ============================================
  // CANCEL NOTIFICATIONS
  // ============================================

  /// Cancel all notifications for a task
  Future<void> cancelTaskNotifications(String taskId) async {
    try {
      await _localNotifications
          .cancel(_getNotificationId(taskId, 'three_days'));
      await _localNotifications.cancel(_getNotificationId(taskId, 'one_day'));
      await _localNotifications.cancel(_getNotificationId(taskId, 'morning'));
      await _localNotifications.cancel(_getNotificationId(taskId, 'overdue'));

      Logger.service(
          'DeadlineNotificationScheduler', 'Cancelled', 'Task: $taskId');
    } catch (e) {
      Logger.error('Failed to cancel task notifications', e);
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Generate unique notification ID
  int _getNotificationId(String taskId, String type) {
    // Combine taskId and type to create unique ID
    final combined = '$taskId-$type';
    return combined.hashCode.abs() % 100000000; // Keep it within int range
  }
}
