// ============================================
// FILE: lib/services/notification_service.dart
// NOTIFICATION SERVICE - Create & Manage Notifications
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // CREATE NOTIFICATIONS
  // ============================================

  /// Send friend request notification
  Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.friendRequest,
        title: 'New Friend Request',
        message: '$fromUserName sent you a friend request',
        data: {'fromUserName': fromUserName},
      );
    } catch (e) {
      Logger.error('Failed to send friend request notification', e);
    }
  }

  /// Send friend accepted notification
  Future<void> sendFriendAcceptedNotification({
    required String toUserId,
    required String acceptedByName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.friendAccepted,
        title: 'Friend Request Accepted',
        message: '$acceptedByName accepted your friend request',
        data: {'acceptedByName': acceptedByName},
      );
    } catch (e) {
      Logger.error('Failed to send friend accepted notification', e);
    }
  }

  /// Send project invite notification
  Future<void> sendProjectInviteNotification({
    required String toUserId,
    required String projectName,
    required String projectId,
    required String invitedByName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.projectInvite,
        title: 'Project Invitation',
        message: '$invitedByName added you to "$projectName"',
        data: {
          'projectId': projectId,
          'projectName': projectName,
          'invitedByName': invitedByName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send project invite notification', e);
    }
  }

  /// Send task assigned notification
  Future<void> sendTaskAssignedNotification({
    required String toUserId,
    required String taskTitle,
    required String taskId,
    required String projectName,
    required String assignedByName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.taskAssigned,
        title: 'New Task Assigned',
        message: '$assignedByName assigned you "$taskTitle" in $projectName',
        data: {
          'taskId': taskId,
          'taskTitle': taskTitle,
          'projectName': projectName,
          'assignedByName': assignedByName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send task assigned notification', e);
    }
  }

  /// Send task completed notification
  Future<void> sendTaskCompletedNotification({
    required String toUserId,
    required String taskTitle,
    required String taskId,
    required String completedByName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.taskCompleted,
        title: 'Task Completed',
        message: '$completedByName completed "$taskTitle"',
        data: {
          'taskId': taskId,
          'taskTitle': taskTitle,
          'completedByName': completedByName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send task completed notification', e);
    }
  }

  /// Send task overdue notification
  Future<void> sendTaskOverdueNotification({
    required String toUserId,
    required String taskTitle,
    required String taskId,
    required String projectName,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.taskOverdue,
        title: 'Task Overdue',
        message: '"$taskTitle" in $projectName is overdue',
        data: {
          'taskId': taskId,
          'taskTitle': taskTitle,
          'projectName': projectName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send task overdue notification', e);
    }
  }

  /// Send reminder notification
  Future<void> sendReminderNotification({
    required String toUserId,
    required String reminderName,
    required String reminderId,
  }) async {
    try {
      await _createNotification(
        userId: toUserId,
        type: NotificationType.reminder,
        title: 'Reminder',
        message: reminderName,
        data: {
          'reminderId': reminderId,
          'reminderName': reminderName,
        },
      );
    } catch (e) {
      Logger.error('Failed to send reminder notification', e);
    }
  }

  // ============================================
  // CORE METHODS
  // ============================================

  /// Create a notification
  Future<String> _createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      Logger.service('NotificationService', 'createNotification',
          'userId: $userId, type: ${type.name}');

      final notification = AppNotification(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());

      Logger.database('CREATE', 'notifications', docRef.id);
      Logger.success('Notification created', 'NotificationService');

      return docRef.id;
    } catch (e) {
      Logger.error('Failed to create notification', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Get user's notifications (real-time)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    Logger.service(
        'NotificationService', 'getUserNotifications', 'userId: $userId');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to 50 most recent
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.data(), doc.id);
      }).toList();

      return notifications;
    });
  }

  /// Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      Logger.service(
          'NotificationService', 'markAsRead', 'id: $notificationId');

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      Logger.database('UPDATE', 'notifications', notificationId);
      Logger.success('Notification marked as read', 'NotificationService');
    } catch (e) {
      Logger.error('Failed to mark notification as read', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      Logger.service('NotificationService', 'markAllAsRead', 'userId: $userId');

      final unreadDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      Logger.success('All notifications marked as read', 'NotificationService');
    } catch (e) {
      Logger.error('Failed to mark all notifications as read', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      Logger.service(
          'NotificationService', 'deleteNotification', 'id: $notificationId');

      await _firestore.collection('notifications').doc(notificationId).delete();

      Logger.database('DELETE', 'notifications', notificationId);
      Logger.success('Notification deleted', 'NotificationService');
    } catch (e) {
      Logger.error('Failed to delete notification', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      Logger.service(
          'NotificationService', 'deleteAllNotifications', 'userId: $userId');

      final allDocs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in allDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      Logger.success('All notifications deleted', 'NotificationService');
    } catch (e) {
      Logger.error('Failed to delete all notifications', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
