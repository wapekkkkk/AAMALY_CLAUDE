// ============================================
// FILE: lib/utils/error_handler.dart
// CENTRALIZED ERROR HANDLING
// ============================================

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  /// Convert Firebase errors to user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error is Exception) {
      return _handleGeneralException(error);
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle Firebase-specific errors
  static String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      // Auth Errors
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      // Firestore Errors
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested item was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'data-loss':
        return 'Data loss detected. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection.';
      case 'failed-precondition':
        return 'Operation cannot be performed in current state.';
      case 'invalid-argument':
        return 'Invalid data provided. Please check your input.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';

      // Storage Errors
      case 'storage/unauthorized':
        return 'You don\'t have permission to access this file.';
      case 'storage/canceled':
        return 'File upload was cancelled.';
      case 'storage/unknown':
        return 'An unknown error occurred during file transfer.';
      case 'storage/object-not-found':
        return 'File not found.';
      case 'storage/quota-exceeded':
        return 'Storage quota exceeded.';
      case 'storage/invalid-checksum':
        return 'File upload failed. Please try again.';
      case 'storage/retry-limit-exceeded':
        return 'Maximum retry attempts reached. Please try again later.';

      // Network Errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return error.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Handle general exceptions
  static String _handleGeneralException(Exception error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (message.contains('FormatException')) {
      return 'Invalid data format.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'network-request-failed' ||
          error.code == 'unavailable' ||
          error.code == 'deadline-exceeded';
    }

    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout');
  }

  /// Check if user should retry
  static bool shouldRetry(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'network-request-failed';
    }
    return isNetworkError(error);
  }

  /// Get error category for logging/analytics
  static String getErrorCategory(dynamic error) {
    if (error is FirebaseException) {
      if (error.code.startsWith('storage/')) {
        return 'STORAGE';
      } else if (_isAuthError(error.code)) {
        return 'AUTH';
      } else {
        return 'FIRESTORE';
      }
    } else if (isNetworkError(error)) {
      return 'NETWORK';
    } else {
      return 'GENERAL';
    }
  }

  static bool _isAuthError(String code) {
    return code == 'user-not-found' ||
        code == 'wrong-password' ||
        code == 'email-already-in-use' ||
        code == 'weak-password' ||
        code == 'invalid-email' ||
        code == 'user-disabled';
  }
}
