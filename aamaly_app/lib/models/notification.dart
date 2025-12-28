// ============================================
// FILE: lib/models/notification.dart
// NOTIFICATION MODEL
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  projectInvite,
  taskAssigned,
  taskCompleted,
  taskOverdue,
  projectUpdate,
  reminder,
  system,
}

class AppNotification {
  final String id;
  final String userId; // Who receives this notification
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data (taskId, projectId, etc)
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  // Create from Firestore
  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      type: _parseNotificationType(map['type']),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'friendRequest':
        return NotificationType.friendRequest;
      case 'friendAccepted':
        return NotificationType.friendAccepted;
      case 'projectInvite':
        return NotificationType.projectInvite;
      case 'taskAssigned':
        return NotificationType.taskAssigned;
      case 'taskCompleted':
        return NotificationType.taskCompleted;
      case 'taskOverdue':
        return NotificationType.taskOverdue;
      case 'projectUpdate':
        return NotificationType.projectUpdate;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  // Get icon for notification type
  String get iconName {
    switch (type) {
      case NotificationType.friendRequest:
        return 'person_add';
      case NotificationType.friendAccepted:
        return 'people';
      case NotificationType.projectInvite:
        return 'folder_shared';
      case NotificationType.taskAssigned:
        return 'assignment_ind';
      case NotificationType.taskCompleted:
        return 'check_circle';
      case NotificationType.taskOverdue:
        return 'warning';
      case NotificationType.projectUpdate:
        return 'update';
      case NotificationType.reminder:
        return 'notifications';
      case NotificationType.system:
        return 'info';
    }
  }

  // Get color for notification type
  String get colorHex {
    switch (type) {
      case NotificationType.friendRequest:
        return '#2196F3'; // Blue
      case NotificationType.friendAccepted:
        return '#4CAF50'; // Green
      case NotificationType.projectInvite:
        return '#FF9800'; // Orange
      case NotificationType.taskAssigned:
        return '#2196F3'; // Blue
      case NotificationType.taskCompleted:
        return '#4CAF50'; // Green
      case NotificationType.taskOverdue:
        return '#F44336'; // Red
      case NotificationType.projectUpdate:
        return '#9C27B0'; // Purple
      case NotificationType.reminder:
        return '#FF9800'; // Orange
      case NotificationType.system:
        return '#607D8B'; // Grey
    }
  }

  // Time ago text
  String get timeAgoText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
