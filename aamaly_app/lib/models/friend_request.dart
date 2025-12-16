// ============================================
// FILE: lib/models/friend_request.dart
// ============================================

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
