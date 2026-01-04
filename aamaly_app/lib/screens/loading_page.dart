// ============================================
// FILE: lib/screens/loading_screen.dart
// LOADING SCREEN - Dark Theme with Purple Accent
// ============================================

import 'package:flutter/material.dart';
import 'auth/login_page.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E141B), // Dark background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/logoaamaly.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              // App Name (optional - remove if not needed)
              // Image.asset(
              //   'assets/images/logonamaaamaly.png',
              //   height: 50,
              //   fit: BoxFit.contain,
              // ),
              // const SizedBox(height: 20),

              // Subtitle text
              const Text(
                'Your Academic Task Manager',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Get Started Button (Purple Outline)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor:
                        const Color.fromARGB(255, 255, 255, 255), // Purple text
                    side: const BorderSide(
                      color: Color(0xFF7C4DFF), // Purple outline
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Get Started Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
