// ============================================
// FILE: lib/utils/logger.dart
// CENTRALIZED LOGGING SYSTEM
// ============================================

import 'package:flutter/foundation.dart';

/// Logger utility for debugging and tracking
/// Only logs in debug mode, silent in release builds
class Logger {
  static const String _prefix = '🔷 AAMALY';

  /// Log general information
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ℹ️ $timestamp $tagStr $message');
    }
  }

  /// Log success messages
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ✅ $timestamp $tagStr $message');
    }
  }

  /// Log warnings
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final tagStr = tag != null ? '[$tag]' : '';
      print('$_prefix ⚠️ $timestamp $tagStr $message');
    }
  }

  /// Log errors
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      print('$_prefix ❌ $timestamp ERROR: $message');
      if (error != null) {
        print('$_prefix    Details: $error');
      }
      if (stackTrace != null) {
        print('$_prefix    Stack trace:\n$stackTrace');
      }
    }
  }

  /// Log service calls
  static void service(String serviceName, String method, [String? details]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final detailsStr = details != null ? ' - $details' : '';
      print('$_prefix 🔧 $timestamp [$serviceName.$method]$detailsStr');
    }
  }

  /// Log network requests
  static void network(String method, String endpoint, [int? statusCode]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final status = statusCode != null ? ' ($statusCode)' : '';
      print('$_prefix 🌐 $timestamp $method $endpoint$status');
    }
  }

  /// Log database operations
  static void database(String operation, String collection, [String? id]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final idStr = id != null ? '/$id' : '';
      print('$_prefix 💾 $timestamp DB: $operation on $collection$idStr');
    }
  }

  /// Log authentication events
  static void auth(String event, [String? userId]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final userStr = userId != null ? ' (User: $userId)' : '';
      print('$_prefix 🔐 $timestamp AUTH: $event$userStr');
    }
  }

  /// Log file operations
  static void file(String operation, String fileName, [int? fileSize]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final sizeStr = fileSize != null ? ' (${_formatBytes(fileSize)})' : '';
      print('$_prefix 📁 $timestamp FILE: $operation - $fileName$sizeStr');
    }
  }

  /// Log navigation events
  static void navigation(String from, String to) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      print('$_prefix 🧭 $timestamp Navigation: $from → $to');
    }
  }

  /// Log performance metrics
  static void performance(String operation, int milliseconds) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final seconds = milliseconds / 1000;
      print(
          '$_prefix ⚡ $timestamp Performance: $operation took ${seconds.toStringAsFixed(2)}s');
    }
  }

  /// Log API calls
  static void api(String endpoint, String method,
      [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      final paramsStr = params != null ? '\n    Params: $params' : '';
      print('$_prefix 📡 $timestamp API: $method $endpoint$paramsStr');
    }
  }

  /// Create a separator line
  static void separator([String? label]) {
    if (kDebugMode) {
      final labelStr = label != null ? ' $label ' : '';
      print(
          '$_prefix ═══════════════════════════$labelStr═══════════════════════════');
    }
  }

  /// Log a divider
  static void divider() {
    if (kDebugMode) {
      print(
          '$_prefix ─────────────────────────────────────────────────────────────');
    }
  }

  /// Log JSON data (pretty printed)
  static void json(String label, Map<String, dynamic> data) {
    if (kDebugMode) {
      final timestamp = _getTimestamp();
      print('$_prefix 📋 $timestamp $label:');
      data.forEach((key, value) {
        print('$_prefix    $key: $value');
      });
    }
  }

  /// Helper: Get formatted timestamp
  static String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// Helper: Format bytes to human-readable
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Extension for timing operations
extension LoggerTiming on Logger {
  /// Measure execution time of a function
  static Future<T> measure<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      Logger.performance(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      Logger.error(
          '$operation failed after ${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
  }
}
