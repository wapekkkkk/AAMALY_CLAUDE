// ============================================
// FILE: lib/services/auth_service.dart
// ============================================

import 'dart:async';
import '../models/user.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current user stream
  final _userController = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Mock user database (replace with actual API calls later)
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'email': 'student@iium.edu.my',
      'password': 'password123',
      'name': 'Ahmad Student',
      'id': '1',
    },
  ];

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate input
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email and password are required',
      };
    }

    // Check email format
    if (!_isValidEmail(email)) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    // Find user in mock database
    final userMap = _mockUsers.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (userMap.isEmpty) {
      return {
        'success': false,
        'message': 'Invalid email or password',
      };
    }

    // Create user object
    _currentUser = User(
      id: userMap['id'],
      name: userMap['name'],
      email: userMap['email'],
    );

    _userController.add(_currentUser);

    return {
      'success': true,
      'message': 'Login successful',
      'user': _currentUser,
    };
  }

  // Register method
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Validate input
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'All fields are required',
      };
    }

    // Check email format
    if (!_isValidEmail(email)) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    // Check IIUM email domain
    if (!email.endsWith('@iium.edu.my') &&
        !email.endsWith('@live.iium.edu.my')) {
      return {
        'success': false,
        'message': 'Please use your IIUM email address',
      };
    }

    // Check password length
    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Check password match
    if (password != confirmPassword) {
      return {
        'success': false,
        'message': 'Passwords do not match',
      };
    }

    // Check if user already exists
    final existingUser = _mockUsers.firstWhere(
      (user) => user['email'] == email,
      orElse: () => {},
    );

    if (existingUser.isNotEmpty) {
      return {
        'success': false,
        'message': 'Email already registered',
      };
    }

    // Create new user
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email,
      'password': password,
    };

    _mockUsers.add(newUser);

    // Auto login after registration
    _currentUser = User(
      id: newUser['id']!,
      name: newUser['name']!,
      email: newUser['email']!,
    );

    _userController.add(_currentUser);

    return {
      'success': true,
      'message': 'Registration successful',
      'user': _currentUser,
    };
  }

  // Logout method
  Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Dispose
  void dispose() {
    _userController.close();
  }
}
