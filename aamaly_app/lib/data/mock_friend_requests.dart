// ============================================
// FILE: lib/data/mock_friend_requests.dart
// ============================================

import '../models/friend_request.dart';

class MockFriendRequests {
  // Pending requests (sent by current user)
  static List<FriendRequest> getPendingRequests() {
    return [
      FriendRequest(
        id: 'req_1',
        fromUserId: '1', // Current user
        toUserId: '7',
        status: RequestStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FriendRequest(
        id: 'req_2',
        fromUserId: '1', // Current user
        toUserId: '8',
        status: RequestStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  // Received requests (sent to current user)
  static List<FriendRequest> getReceivedRequests() {
    return [
      FriendRequest(
        id: 'req_3',
        fromUserId: '9',
        toUserId: '1', // Current user
        status: RequestStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      FriendRequest(
        id: 'req_4',
        fromUserId: '10',
        toUserId: '1', // Current user
        status: RequestStatus.pending,
        sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  // Mock user data for pending/received requests
  static Map<String, Map<String, String>> mockRequestUsers = {
    '7': {
      'name': 'Omar Yusof',
      'email': 'omar@iium.edu.my',
    },
    '8': {
      'name': 'Nurul Ain',
      'email': 'nurul@live.iium.edu.my',
    },
    '9': {
      'name': 'Hasan Mahmood',
      'email': 'hasan@iium.edu.my',
    },
    '10': {
      'name': 'Maryam Ali',
      'email': 'maryam@live.iium.edu.my',
    },
  };

  // Get user name for request
  static String getUserName(String userId) {
    return mockRequestUsers[userId]?['name'] ?? 'Unknown User';
  }

  // Get user email for request
  static String getUserEmail(String userId) {
    return mockRequestUsers[userId]?['email'] ?? 'unknown@iium.edu.my';
  }
}
