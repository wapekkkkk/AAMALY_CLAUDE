// ============================================
// FILE: lib/screens/notifications_page.dart
// NOTIFICATIONS PAGE - Dark Theme (FIXED - No Disappearing!)
// ============================================

import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_auth_service.dart';
import 'dart:async';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notificationService = NotificationService();
  final _authService = FirebaseAuthService();

  String _selectedFilter = 'all';

  // ✅ FIX: Cache the stream to prevent rebuilds
  Stream<List<AppNotification>>? _notificationsStream;
  List<AppNotification> _cachedNotifications = [];

  // ===== Theme Tokens =====
  static const _bg = Color(0xFF0E141B);
  static const _card = Color(0xFF121B24);
  static const _card2 = Color(0xFF0F1720);
  static const _border = Color(0xFF243244);
  static const _text = Color(0xFFEAF0FF);
  static const _muted = Color(0xFF9AA8BD);
  static const _accent = Color(0xFF7C4DFF);
  static const _accent2 = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    // ✅ Initialize stream once
    final currentUserId = _authService.currentUserId;
    if (currentUserId != null) {
      _notificationsStream =
          _notificationService.getUserNotifications(currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Please log in to view notifications',
            style: TextStyle(color: _text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Gradient Header =====
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'mark_all_read') {
                        _markAllAsRead(currentUserId);
                      } else if (value == 'delete_all') {
                        _showDeleteAllDialog(currentUserId);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all, size: 20),
                            SizedBox(width: 12),
                            Text('Mark all as read'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep,
                                size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete all',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ===== Filter Tabs =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                children: [
                  Expanded(child: _buildFilterTab('All', 'all')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterTab('Unread', 'unread')),
                ],
              ),
            ),

            // ===== Notifications List =====
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  // ✅ FIX: Cache the data to prevent disappearing
                  if (snapshot.hasData) {
                    _cachedNotifications = snapshot.data!;
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedNotifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }

                  if (_cachedNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  // ✅ FIX: Filter using cached data
                  final filteredNotifications = _selectedFilter == 'unread'
                      ? _cachedNotifications.where((n) => !n.isRead).toList()
                      : _cachedNotifications;

                  if (filteredNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: filteredNotifications.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                          filteredNotifications[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS
  // ============================================

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withOpacity(0.25) : _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _accent.withOpacity(0.6) : _border,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _accent.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? _text : _muted,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final color = _parseColor(notification.colorHex);
    final icon = _parseIcon(notification.iconName);
    final cardBg = notification.isRead ? _card : _accent.withOpacity(0.12);
    final borderColor =
        notification.isRead ? _border : _accent.withOpacity(0.50);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              backgroundColor: _card2,
            ),
          );
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onNotificationTap(notification),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: notification.isRead ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notification.timeAgoText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _muted.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final title = _selectedFilter == 'unread'
        ? 'No unread notifications'
        : 'No notifications yet';
    final subtitle = _selectedFilter == 'unread'
        ? 'You\'re all caught up!'
        : 'Notifications will appear here';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child:
                  const Icon(Icons.notifications_none, size: 60, color: _muted),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _muted)),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _onNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }
    _handleNotificationTap(notification);
  }

  void _markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('All notifications marked as read'),
              backgroundColor: _card2),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteAllDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        titleTextStyle: const TextStyle(
            color: _text, fontSize: 18, fontWeight: FontWeight.w800),
        contentTextStyle: const TextStyle(color: _muted),
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _text)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _notificationService.deleteAllNotifications(userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('All deleted'),
                        backgroundColor: _card2),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped: ${notification.title}'),
          duration: const Duration(seconds: 1),
          backgroundColor: _card2,
        ),
      );
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  Color _parseColor(String hexColor) {
    var h = hexColor.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'people':
        return Icons.people;
      case 'folder_shared':
        return Icons.folder_shared;
      case 'assignment_ind':
        return Icons.assignment_ind;
      case 'check_circle':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'update':
        return Icons.update;
      case 'notifications':
        return Icons.notifications;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
