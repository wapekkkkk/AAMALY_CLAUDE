// ============================================
// FILE: lib/screens/friend_profile_page.dart
// UPDATED THEME: Dark + Neon (matches ProfilePage)
// ============================================

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/task.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/friend_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FriendProfilePage extends StatefulWidget {
  final User friend;

  const FriendProfilePage({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  // ===== Theme (Dark) =====
  static const Color _bg = Color(0xFF0E141B);
  static const Color _card = Color(0xFF121A23);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF9AA4B2);
  static const Color _accent = Color(0xFF7C4DFF);
  static const Color _accent2 = Color(0xFF00E5FF);

  final _authService = FirebaseAuthService();
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _friendService = FriendService();

  int _projectCount = 0;
  int _taskCount = 0;
  int _completedTaskCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendStats();
  }

  Future<void> _loadFriendStats() async {
    try {
      final projects =
          await _projectService.getAllUserProjects(widget.friend.id).first;
      final tasks = await _taskService.getUserTasks(widget.friend.id).first;

      final completed =
          tasks.where((t) => t.status == TaskStatus.completed).length;

      setState(() {
        _projectCount = projects.length;
        _taskCount = tasks.length;
        _completedTaskCount = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRemoveFriendDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        titleTextStyle: const TextStyle(
            color: _text, fontWeight: FontWeight.w800, fontSize: 18),
        contentTextStyle:
            const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        title: const Text('Remove Friend'),
        content: Text('Remove ${widget.friend.name} from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final currentUserId = _authService.currentUserId;
        if (currentUserId != null) {
          await _friendService.removeFriend(
            userId: currentUserId,
            friendId: widget.friend.id,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.friend.name} removed from friends'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove friend: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon! 🚀'),
        backgroundColor: _accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _taskCount > 0
        ? (_completedTaskCount / _taskCount * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ✅ HEADER (same style as ProfilePage)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accent2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // AppBar row
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            onSelected: (value) {
                              if (value == 'remove') _showRemoveFriendDialog();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove,
                                        color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Remove Friend',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.friend.initials,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _accent,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .scale(begin: const Offset(0.5, 0.5), delay: 200.ms),

                    const SizedBox(height: 14),

                    Text(
                      widget.friend.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1, delay: 300.ms),

                    const SizedBox(height: 4),

                    Text(
                      widget.friend.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 16),

                    // Friend badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.55)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Friend',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), delay: 400.ms),

                    const SizedBox(height: 26),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
            ),

            // ✅ STATS ROW (dark cards)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.folder,
                              _projectCount.toString(),
                              'Projects',
                              _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.assignment,
                              _taskCount.toString(),
                              'Tasks',
                              const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.check_circle,
                              '$completionRate%',
                              'Complete',
                              const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.1, delay: 500.ms),
              ),
            ),

            // ✅ ACTIVITY
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: 'Activity',
                  child: _buildSectionCard(
                    children: [
                      _buildListTile(
                        icon: Icons.assignment_outlined,
                        title: 'Total Tasks',
                        subtitle: '$_taskCount tasks created',
                        onTap: null,
                      ),
                      _divider(),
                      _buildListTile(
                        icon: Icons.check_circle_outline,
                        title: 'Completed Tasks',
                        subtitle: '$_completedTaskCount tasks completed',
                        onTap: null,
                      ),
                      _divider(),
                      _buildListTile(
                        icon: Icons.folder_outlined,
                        title: 'Projects',
                        subtitle: '$_projectCount active projects',
                        onTap: null,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideX(begin: 0.1, delay: 600.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ✅ COLLABORATION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _Section(
                  title: 'Collaboration',
                  child: _buildSectionCard(
                    children: [
                      _buildListTile(
                        icon: Icons.people_outline,
                        title: 'Shared Projects',
                        subtitle: 'View projects you collaborate on',
                        onTap: () => _showComingSoon(),
                      ),
                      _divider(),
                      _buildListTile(
                        icon: Icons.message_outlined,
                        title: 'Send Message',
                        subtitle: 'Send a message to ${widget.friend.name}',
                        onTap: () => _showComingSoon(),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .slideX(begin: 0.1, delay: 700.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.white.withOpacity(0.08));

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withOpacity(0.18)),
        ),
        child: Icon(icon, color: _accent, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: _text,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: _muted)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  static const Color _text = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _text,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
