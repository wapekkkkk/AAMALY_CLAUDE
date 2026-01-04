// ============================================
// FILE: lib/main.dart (UPDATED WITH FIREBASE)
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/loading_page.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';
import 'screens/dashboard/dashboard_page.dart'; // ✅ ADD THIS

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();
  runApp(const AamalyApp());
}

class AamalyApp extends StatelessWidget {
  const AamalyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aamaly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF0E141B),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android:
                CupertinoPageTransitionsBuilder(), // iOS-like
          },
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
