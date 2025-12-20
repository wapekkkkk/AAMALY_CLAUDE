// ============================================
// FILE: lib/services/firebase_auth_service.dart
// REAL FIREBASE AUTHENTICATION
// ============================================

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        return null;
      }

      // Fetch user data from Firestore
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();

      if (doc.exists) {
        _currentUser = User.fromJson({...doc.data()!, 'id': fbUser.uid});
        return _currentUser;
      }

      return null;
    });
  }

  // REGISTER NEW USER
  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // 2. Generate QR code (simple version - you can enhance later)
      final qrCode = 'AAMALY_${userId.substring(0, 8).toUpperCase()}';

      // 3. Create user document in Firestore
      final userData = {
        'name': name,
        'email': email,
        'profileImage': null,
        'qrCode': qrCode,
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData);

      // 4. Update display name in Firebase Auth
      await credential.user!.updateDisplayName(name);

      // 5. Create User object
      _currentUser = User(
        id: userId,
        name: name,
        email: email,
        profileImage: null,
        isOnline: true,
        qrCode: qrCode,
      );

      return _currentUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // LOGIN USER
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // 2. Fetch user data from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      // 3. Update online status
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });

      // 4. Create User object
      final data = doc.data()!;
      _currentUser = User(
        id: userId,
        name: data['name'],
        email: data['email'],
        profileImage: data['profileImage'],
        isOnline: true,
        qrCode: data['qrCode'],
        lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      );

      return _currentUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // LOGOUT USER
  Future<void> logout() async {
    try {
      if (_auth.currentUser != null) {
        // Update online status before logout
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'isOnline': false,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // UPDATE USER PROFILE
  Future<void> updateProfile({
    String? name,
    String? profileImage,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImage != null) updates['profileImage'] = profileImage;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);

        // Update display name in Firebase Auth
        if (name != null) {
          await _auth.currentUser!.updateDisplayName(name);
        }

        // Update current user object
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            name: name ?? _currentUser!.name,
            profileImage: profileImage ?? _currentUser!.profileImage,
          );
        }
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // AUTO-LOGIN (Check if user is already logged in)
  Future<User?> autoLogin() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return null;

      // Fetch user data
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      _currentUser = User(
        id: fbUser.uid,
        name: data['name'],
        email: data['email'],
        profileImage: data['profileImage'],
        isOnline: true,
        qrCode: data['qrCode'],
        lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      );

      // Update online status
      await _firestore.collection('users').doc(fbUser.uid).update({
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });

      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
