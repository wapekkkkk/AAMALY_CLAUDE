// ============================================
// FILE: lib/main.dart
// ============================================

import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const LoginPage(),
    );
  }
}
