// ============================================
// FILE: lib/screens/firebase_test_page.dart
// ============================================
// TEMPORARY TEST PAGE - DELETE AFTER TESTING

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({super.key});

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  String _status = 'Testing Firebase connection...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test 1: Check Firebase initialization
      final app = Firebase.app();
      setState(() {
        _status = '✅ Firebase initialized!\nApp name: ${app.name}\n\n';
      });

      // Test 2: Try to access Firestore
      final firestore = FirebaseFirestore.instance;
      setState(() {
        _status += '✅ Firestore instance created!\n\n';
      });

      // Test 3: Write test document
      await firestore.collection('_test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection successful!',
      });

      setState(() {
        _status += '✅ Test document written!\n\n';
      });

      // Test 4: Read test document
      final doc = await firestore.collection('_test').doc('connection').get();

      setState(() {
        _status += '✅ Test document read!\n';
        _status += 'Data: ${doc.data()}\n\n';
        _status += '🎉 ALL TESTS PASSED!\n';
        _status += 'Firebase is fully connected and working!';
        _isConnected = true;
      });

      // Clean up test document
      await firestore.collection('_test').doc('connection').delete();
    } catch (e) {
      setState(() {
        _status = '❌ ERROR: $e\n\n';
        _status += 'Please check:\n';
        _status += '1. google-services.json is in android/app/\n';
        _status += '2. Firebase packages are installed\n';
        _status += '3. Internet connection is active\n';
        _status += '4. Firebase project is created';
        _isConnected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: _isConnected ? Colors.green : Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.pending,
                size: 80,
                color: _isConnected ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _status,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_isConnected)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _status = 'Retesting connection...';
                    });
                    _testFirebaseConnection();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Test'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
