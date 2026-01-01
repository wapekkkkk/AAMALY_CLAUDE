// ============================================
// FILE: lib/services/friend_service.dart
// FRIEND MANAGEMENT SERVICE (PART 1)
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request.dart';
import '../models/user.dart' as app_user;
import 'notification_service.dart'; // ✅ ADD THIS
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import 'push_notification_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // SEND FRIEND REQUEST
  // ============================================

  /// Send a friend request to another user
  Future<String> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      Logger.service('FriendService', 'sendFriendRequest',
          'from: $senderId to: $receiverId');

      // Check if request already exists
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: senderId)
          .where('toUserId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      // Check if they're already friends
      final isFriend = await areFriends(senderId, receiverId);
      if (isFriend) {
        throw Exception('You are already friends');
      }

      // Create friend request
      final docRef = await _firestore.collection('friendRequests').add({
        'fromUserId': senderId,
        'toUserId': receiverId,
        'status': 'pending',
        'sentAt': FieldValue.serverTimestamp(),
      });

      Logger.database('CREATE', 'friendRequests', docRef.id);
      Logger.success('Friend request sent', 'FriendService');
// ✅ SEND NOTIFICATION
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'Someone';

      await NotificationService().sendFriendRequestNotification(
        toUserId: receiverId,
        fromUserName: senderName,
      );

      await PushNotificationService().showFriendRequest(senderName);
      return docRef.id;
    } catch (e) {
      Logger.error('Failed to send friend request', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // ACCEPT FRIEND REQUEST
  // ============================================

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      Logger.service('FriendService', 'acceptFriendRequest', 'id: $requestId');

      // Get the request
      final requestDoc =
          await _firestore.collection('friendRequests').doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Friend request not found');
      }

      final request = FriendRequest.fromMap(requestDoc.data()!, requestDoc.id);

      // Update request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      Logger.database('UPDATE', 'friendRequests', requestId);

      // Add to both users' friends lists
      await _addToFriendsList(request.fromUserId, request.toUserId);
      await _addToFriendsList(request.toUserId, request.fromUserId);

      // ✅ SEND NOTIFICATION (INSIDE TRY-CATCH)
      final accepterDoc =
          await _firestore.collection('users').doc(request.toUserId).get();
      final accepterName = accepterDoc.data()?['name'] ?? 'Someone';

      await NotificationService().sendFriendAcceptedNotification(
        toUserId: request.fromUserId,
        acceptedByName: accepterName,
      );

      Logger.success('Friend request accepted', 'FriendService');
    } catch (e) {
      Logger.error('Failed to accept friend request', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // DECLINE FRIEND REQUEST
  // ============================================

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      Logger.service('FriendService', 'declineFriendRequest', 'id: $requestId');

      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      Logger.database('UPDATE', 'friendRequests', requestId);
      Logger.success('Friend request declined', 'FriendService');
    } catch (e) {
      Logger.error('Failed to decline friend request', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // GET FRIEND REQUESTS
  // ============================================

  /// Get incoming friend requests (real-time)
  Stream<List<FriendRequest>> getIncomingRequests(String userId) {
    Logger.service('FriendService', 'getIncomingRequests', 'userId: $userId');

    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return FriendRequest.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by date (newest first)
      requests.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return requests;
    });
  }

  /// Get outgoing friend requests (sent by user)
  Stream<List<FriendRequest>> getOutgoingRequests(String userId) {
    Logger.service('FriendService', 'getOutgoingRequests', 'userId: $userId');

    return _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return FriendRequest.fromMap(doc.data(), doc.id);
      }).toList();

      requests.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return requests;
    });
  }

  // ============================================
  // GET FRIENDS LIST
  // ============================================

  /// Get user's friends list (real-time)
  Stream<List<String>> getFriendIds(String userId) {
    Logger.service('FriendService', 'getFriendIds', 'userId: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];

      final data = snapshot.data();
      final friendIds = data?['friendIds'] as List<dynamic>?;

      return friendIds?.map((id) => id.toString()).toList() ?? [];
    });
  }

  /// Get friends with user details
  Future<List<app_user.User>> getFriendsWithDetails(String userId) async {
    try {
      Logger.service(
          'FriendService', 'getFriendsWithDetails', 'userId: $userId');

      // Get friend IDs
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final friendIds =
          (userDoc.data()?['friendIds'] as List<dynamic>?)?.cast<String>() ??
              [];

      if (friendIds.isEmpty) return [];

      // Get friend details
      final friends = <app_user.User>[];
      for (final friendId in friendIds) {
        final friendDoc =
            await _firestore.collection('users').doc(friendId).get();

        if (friendDoc.exists) {
          friends.add(app_user.User.fromMap(friendDoc.data()!, friendDoc.id));
        }
      }

      Logger.success('Retrieved ${friends.length} friends', 'FriendService');
      return friends;
    } catch (e) {
      Logger.error('Failed to get friends with details', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // REMOVE FRIEND
  // ============================================

  /// Remove a friend
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      Logger.service(
          'FriendService', 'removeFriend', 'user: $userId, friend: $friendId');

      // Remove from user's friends list
      await _firestore.collection('users').doc(userId).update({
        'friendIds': FieldValue.arrayRemove([friendId]),
      });

      // Remove from friend's friends list
      await _firestore.collection('users').doc(friendId).update({
        'friendIds': FieldValue.arrayRemove([userId]),
      });

      Logger.database('UPDATE', 'users', userId);
      Logger.database('UPDATE', 'users', friendId);
      Logger.success('Friend removed', 'FriendService');
    } catch (e) {
      Logger.error('Failed to remove friend', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // SEARCH USERS
  // ============================================

  /// Search for users by name or email
  Future<List<app_user.User>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    try {
      Logger.service('FriendService', 'searchUsers', 'query: $query');

      if (query.trim().isEmpty) return [];

      final queryLower = query.toLowerCase();

      // Search by name
      final nameResults = await _firestore
          .collection('users')
          .where('searchName', isGreaterThanOrEqualTo: queryLower)
          .where('searchName', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      // Search by email
      final emailResults = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: queryLower)
          .where('email', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      // Combine and deduplicate results
      final userMap = <String, app_user.User>{};

      for (var doc in nameResults.docs) {
        if (doc.id != currentUserId) {
          userMap[doc.id] = app_user.User.fromMap(doc.data(), doc.id);
        }
      }

      for (var doc in emailResults.docs) {
        if (doc.id != currentUserId && !userMap.containsKey(doc.id)) {
          userMap[doc.id] = app_user.User.fromMap(doc.data(), doc.id);
        }
      }

      final users = userMap.values.toList();
      Logger.success('Found ${users.length} users', 'FriendService');

      return users;
    } catch (e) {
      Logger.error('Failed to search users', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Add friend to user's friends list
  Future<void> _addToFriendsList(String userId, String friendId) async {
    await _firestore.collection('users').doc(userId).set({
      'friendIds': FieldValue.arrayUnion([friendId]),
    }, SetOptions(merge: true));

    Logger.database('UPDATE', 'users', userId);
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId, String friendId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final friendIds =
          (userDoc.data()?['friendIds'] as List<dynamic>?)?.cast<String>() ??
              [];

      return friendIds.contains(friendId);
    } catch (e) {
      Logger.error('Failed to check friendship', e);
      return false;
    }
  }

  /// Check if friend request exists
  Future<bool> hasPendingRequest(String senderId, String receiverId) async {
    try {
      final request = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: senderId)
          .where('toUserId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      return request.docs.isNotEmpty;
    } catch (e) {
      Logger.error('Failed to check pending request', e);
      return false;
    }
  }

  /// Cancel friend request (sender can cancel)
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      Logger.service('FriendService', 'cancelFriendRequest', 'id: $requestId');

      await _firestore.collection('friendRequests').doc(requestId).delete();

      Logger.database('DELETE', 'friendRequests', requestId);
      Logger.success('Friend request cancelled', 'FriendService');
    } catch (e) {
      Logger.error('Failed to cancel friend request', e);
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
