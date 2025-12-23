// ============================================
// FILE: lib/models/friend_request.dart (UPDATED)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, declined }

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final RequestStatus status;
  final DateTime sentAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.sentAt,
  });

  // ✅ ADD: Create from Firestore document
  factory FriendRequest.fromMap(Map<String, dynamic> map, String id) {
    return FriendRequest(
      id: id,
      fromUserId: map['fromUserId'] ?? map['senderId'] ?? '',
      toUserId: map['toUserId'] ?? map['receiverId'] ?? '',
      status: _statusFromString(map['status'] ?? 'pending'),
      sentAt: (map['sentAt'] ?? map['createdAt'] as dynamic)?.toDate() ??
          DateTime.now(),
    );
  }

  // ✅ ADD: Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': _statusToString(status),
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  // ✅ ADD: Helper methods
  static RequestStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'declined':
        return RequestStatus.declined;
      default:
        return RequestStatus.pending;
    }
  }

  static String _statusToString(RequestStatus status) {
    return status.toString().split('.').last;
  }

  // Get time ago text
  String get timeAgoText {
    final difference = DateTime.now().difference(sentAt);

    if (difference.inMinutes < 1) {
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

  // ✅ ADD: Status check helpers
  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isDeclined => status == RequestStatus.declined;

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    RequestStatus? status,
    DateTime? sentAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
