// ============================================
// FILE: lib/services/admin_service.dart
// ADMIN SERVICE - Check Admin Privileges
// ============================================

class AdminService {
  // List of admin emails
  static const List<String> adminEmails = [
    'admin@gmail.com',
    'admin@aamaly.com',
    // Add more admin emails here as needed
  ];

  /// Check if email is an admin
  static bool isAdmin(String email) {
    return adminEmails.contains(email.toLowerCase().trim());
  }

  /// Check if user has admin role (can be extended with Firestore role checking)
  static Future<bool> checkAdminStatus(String userId) async {
    // For now, just check email
    // In future, you can check Firestore for admin role:
    // final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // return userDoc.data()?['role'] == 'admin';

    return false; // Will be checked via email in login
  }
}
