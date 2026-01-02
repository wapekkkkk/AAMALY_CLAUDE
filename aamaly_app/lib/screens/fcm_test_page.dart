// ============================================
// FILE: lib/screens/fcm_test_page.dart
// Quick page to test FCM
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMTestPage extends StatelessWidget {
  const FCMTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C4DFF),
        title: const Text('FCM Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: Color(0xFF7C4DFF),
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Cloud Messaging Test',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Test Button
              ElevatedButton.icon(
                onPressed: () async {
                  await _testFCM(context);
                },
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Run FCM Test',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testFCM(BuildContext context) async {
    print('🧪 ========== FCM TEST STARTED ==========');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );

    try {
      // Test 1: Get FCM token
      print('🧪 Test 1: Getting FCM token...');
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        print('❌ FAIL: Token is null');
        Navigator.pop(context);
        _showResult(context, false,
            'FCM Token is null!\n\nFCM might not be set up correctly.');
        return;
      }

      print('✅ PASS: Token received');
      print('📱 Token: $token');

      // Test 2: Check if user is logged in
      print('🧪 Test 2: Checking user authentication...');
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        print('❌ FAIL: No user logged in');
        Navigator.pop(context);
        _showResult(
            context, false, 'No user logged in!\n\nPlease log in first.');
        return;
      }

      print('✅ PASS: User logged in ($userId)');

      // Test 3: Check if token is saved to Firestore
      print('🧪 Test 3: Checking Firestore...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('❌ FAIL: User document not found');
        Navigator.pop(context);
        _showResult(context, false, 'User document not found in Firestore!');
        return;
      }

      final savedToken = userDoc.data()?['fcmToken'] as String?;
      print('💾 Saved token: $savedToken');

      Navigator.pop(context);

      if (savedToken == null) {
        print('⚠️ WARNING: Token not saved to Firestore');
        _showResult(context, false,
            'FCM token exists but is NOT saved to Firestore!\n\nToken: ${token.substring(0, 30)}...\n\nYou need to initialize PushNotificationService in your dashboard.');
      } else if (savedToken == token) {
        print('✅ SUCCESS: Everything works!');
        _showResult(context, true,
            'FCM is working perfectly! ✅\n\nToken: ${token.substring(0, 30)}...\n\nYour push notification system is set up correctly!');
      } else {
        print('⚠️ WARNING: Tokens don\'t match');
        _showResult(context, false,
            'Token mismatch!\n\nCurrent: ${token.substring(0, 30)}...\nSaved: ${savedToken.substring(0, 30)}...\n\nToken might have been refreshed.');
      }

      print('🧪 ========== FCM TEST COMPLETE ==========');
    } catch (e) {
      print('❌ ERROR: $e');
      Navigator.pop(context);
      _showResult(context, false, 'Error during test:\n\n$e');
    }
  }

  void _showResult(BuildContext context, bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121B24),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              success ? 'Test Passed!' : 'Test Failed',
              style: TextStyle(
                color: success ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF7C4DFF)),
            ),
          ),
        ],
      ),
    );
  }
}
