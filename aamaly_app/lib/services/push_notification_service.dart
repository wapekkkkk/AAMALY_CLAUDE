// ============================================
// FILE: lib/services/push_notification_service.dart
// PUSH NOTIFICATION SERVICE - FCM + Local Notifications
// ============================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'dart:io' show Platform;

// ✅ IMPORTANT: This function must be top-level (outside class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize push notifications
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up FCM
      await _setupFCM(userId);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      _handleForegroundMessages();

      // Handle notification taps
      _handleNotificationTaps();

      _isInitialized = true;
      Logger.success(
          'Push notifications initialized', 'PushNotificationService');
    } catch (e) {
      Logger.error('Failed to initialize push notifications', e);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    Logger.service('PushNotificationService', 'requestPermissions',
        'Status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // Deadline reminders channel (High priority)
    const deadlineChannel = AndroidNotificationChannel(
      'deadline_reminders',
      'Deadline Reminders',
      description: 'Notifications for upcoming task deadlines',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Task assignments channel
    const taskChannel = AndroidNotificationChannel(
      'task_assignments',
      'Task Assignments',
      description: 'Notifications when you are assigned to tasks',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Project updates channel
    const projectChannel = AndroidNotificationChannel(
      'project_updates',
      'Project Updates',
      description: 'Notifications for project collaboration',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Friend requests channel
    const friendChannel = AndroidNotificationChannel(
      'friend_requests',
      'Friend Requests',
      description: 'Notifications for friend requests',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Reminders channel (Max priority)
    const reminderChannel = AndroidNotificationChannel(
      'reminders',
      'Reminders',
      description: 'Your custom reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(deadlineChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(taskChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(projectChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(friendChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Setup Firebase Cloud Messaging
  Future<void> _setupFCM(String userId) async {
    try {
      // Get FCM token
      _fcmToken = await _fcm.getToken();

      if (_fcmToken != null) {
        // Save token to Firestore
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });

        Logger.service('PushNotificationService', 'FCM Token', _fcmToken!);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      Logger.error('Failed to setup FCM', e);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.service('PushNotificationService', 'Foreground Message',
          message.notification?.title ?? 'No title');

      // Show local notification when app is in foreground
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Aamaly',
          body: message.notification!.body ?? '',
          channelId: message.data['channelId'] ?? 'default',
          payload: message.data['payload'],
        );
      }
    });
  }

  /// Handle notification taps
  void _handleNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['payload']);
    });
  }

  /// Handle when user taps notification
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    Logger.service('PushNotificationService', 'Notification Tapped', payload);

    // TODO: Navigate to relevant page based on payload
    // Example: {"type": "task", "id": "task123"}
  }

  // ============================================
  // SHOW NOTIFICATIONS
  // ============================================

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show notification with custom channel
  Future<void> showNotification({
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      channelDescription: 'Notification channel',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ============================================
  // SPECIFIC NOTIFICATION TYPES
  // ============================================

  /// Deadline reminder (3 days)
  Future<void> showDeadlineReminder3Days(
      String taskTitle, String taskId) async {
    await showNotification(
      title: '⏰ Deadline Reminder',
      body: '$taskTitle is due in 3 days',
      channelId: 'deadline_reminders',
      payload: '{"type":"task","id":"$taskId"}',
    );
  }

  /// Deadline reminder (tomorrow)
  Future<void> showDeadlineReminderTomorrow(
      String taskTitle, String taskId) async {
    await showNotification(
      title: '⚠️ Due Tomorrow',
      body: '$taskTitle is due tomorrow!',
      channelId: 'deadline_reminders',
      payload: '{"type":"task","id":"$taskId"}',
    );
  }

  /// Deadline reminder (today)
  Future<void> showDeadlineReminderToday(
      String taskTitle, String taskId) async {
    await showNotification(
      title: '🔴 Due Today',
      body: '$taskTitle is due today!',
      channelId: 'deadline_reminders',
      payload: '{"type":"task","id":"$taskId"}',
    );
  }

  /// Task overdue
  Future<void> showTaskOverdue(String taskTitle, String taskId) async {
    await showNotification(
      title: '❌ Task Overdue',
      body: '$taskTitle is now overdue',
      channelId: 'deadline_reminders',
      payload: '{"type":"task","id":"$taskId"}',
    );
  }

  /// Task assigned
  Future<void> showTaskAssigned(String taskTitle, String assignedBy) async {
    await showNotification(
      title: '📋 New Task Assigned',
      body: '$assignedBy assigned you "$taskTitle"',
      channelId: 'task_assignments',
    );
  }

  /// Added to project
  Future<void> showAddedToProject(String projectName, String addedBy) async {
    await showNotification(
      title: '🎉 Added to Project',
      body: '$addedBy added you to "$projectName"',
      channelId: 'project_updates',
    );
  }

  /// Removed from project
  Future<void> showRemovedFromProject(String projectName) async {
    await showNotification(
      title: '❌ Removed from Project',
      body: 'You were removed from "$projectName"',
      channelId: 'project_updates',
    );
  }

  /// Friend request
  Future<void> showFriendRequest(String friendName) async {
    await showNotification(
      title: '👋 New Friend Request',
      body: '$friendName sent you a friend request',
      channelId: 'friend_requests',
    );
  }

  /// Custom reminder
  Future<void> showCustomReminder(String reminderName) async {
    await showNotification(
      title: '🔔 Reminder',
      body: reminderName,
      channelId: 'reminders',
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
