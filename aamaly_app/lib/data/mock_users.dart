// ============================================
// FILE: lib/data/mock_users.dart
// ============================================

import '../models/user.dart';

class MockUsers {
  // Current logged-in user
  static final currentUser = User(
    id: '1',
    name: 'Ahmad Student',
    email: 'ahmad@iium.edu.my',
    profileImage: null,
    isOnline: true,
    qrCode: 'USER_1_QR_CODE',
  );

  // Friends list (confirmed collaborators)
  static List<User> getFriends() {
    return [
      User(
        id: '2',
        name: 'Sarah Ali',
        email: 'sarah@iium.edu.my',
        profileImage: null,
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        qrCode: 'USER_2_QR_CODE',
      ),
      User(
        id: '3',
        name: 'Ali Hassan',
        email: 'ali@live.iium.edu.my',
        profileImage: null,
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        qrCode: 'USER_3_QR_CODE',
      ),
      User(
        id: '4',
        name: 'Fatimah Ahmad',
        email: 'fatimah@iium.edu.my',
        profileImage: null,
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
        qrCode: 'USER_4_QR_CODE',
      ),
      User(
        id: '5',
        name: 'Muhammad Zaki',
        email: 'zaki@live.iium.edu.my',
        profileImage: null,
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(days: 1)),
        qrCode: 'USER_5_QR_CODE',
      ),
      User(
        id: '6',
        name: 'Aisha Ibrahim',
        email: 'aisha@iium.edu.my',
        profileImage: null,
        isOnline: true,
        lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
        qrCode: 'USER_6_QR_CODE',
      ),
    ];
  }

  // Get user by ID
  static User? getUserById(String id) {
    if (id == currentUser.id) return currentUser;

    try {
      return getFriends().firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get user by email
  static User? getUserByEmail(String email) {
    if (email.toLowerCase() == currentUser.email.toLowerCase()) {
      return currentUser;
    }

    try {
      return getFriends().firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Search friends by name or email
  static List<User> searchFriends(String query) {
    if (query.isEmpty) return getFriends();

    final lowerQuery = query.toLowerCase();
    return getFriends().where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
