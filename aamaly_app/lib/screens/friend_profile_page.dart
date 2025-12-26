// ============================================
// FILE: lib/screens/friend_profile_page.dart
// FRIEND PROFILE PAGE - View Friend's Public Info
// ============================================

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/task.dart'; // ✅ ADD THIS
import '../services/firebase_auth_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';

class FriendProfilePage extends StatefulWidget {
  final User friend;

  const FriendProfilePage({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
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
      // Load friend's public stats
      final projects =
          await _projectService.getAllUserProjects(widget.friend.id).first;

      final tasks = await _taskService.getUserTasks(widget.friend.id).first;

      final completedTasks =
          tasks.where((t) => t.status == TaskStatus.completed).length;

      setState(() {
        _projectCount = projects.length;
        _taskCount = tasks.length;
        _completedTaskCount = completedTasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friend stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _taskCount > 0
        ? (_completedTaskCount / _taskCount * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ✅ HEADER SECTION (Read-only)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3),
                      const Color(0xFF1976D2),
                    ],
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
                    // AppBar
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // ✅ More options (Remove Friend, etc)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            onSelected: (value) {
                              if (value == 'remove') {
                                _showRemoveFriendDialog();
                              }
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

                    // ✅ Avatar with Initials (Read-only)
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.friend.initials,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ Name
                    Text(
                      widget.friend.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ✅ Email
                    Text(
                      widget.friend.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Friend Badge (instead of Edit button)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Friend',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ✅ STATS ROW (Public Stats)
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
                              const Color(0xFF2196F3),
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
                      ),
              ),
            ),

            // ✅ ACTIVITY SECTION (Public Info Only)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      children: [
                        _buildListTile(
                          icon: Icons.assignment_outlined,
                          title: 'Total Tasks',
                          subtitle: '$_taskCount tasks created',
                          onTap: null,
                        ),
                        const Divider(height: 1),
                        _buildListTile(
                          icon: Icons.check_circle_outline,
                          title: 'Completed Tasks',
                          subtitle: '$_completedTaskCount tasks completed',
                          onTap: null,
                        ),
                        const Divider(height: 1),
                        _buildListTile(
                          icon: Icons.folder_outlined,
                          title: 'Projects',
                          subtitle: '$_projectCount active projects',
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ✅ COLLABORATION SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collaboration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      children: [
                        _buildListTile(
                          icon: Icons.people_outline,
                          title: 'Shared Projects',
                          subtitle: 'View projects you collaborate on',
                          onTap: () => _showComingSoon(),
                        ),
                        const Divider(height: 1),
                        _buildListTile(
                          icon: Icons.message_outlined,
                          title: 'Send Message',
                          subtitle: 'Send a message to ${widget.friend.name}',
                          onTap: () => _showComingSoon(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ✅ Build Stat Card
  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Section Card
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ✅ Build List Tile
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2196F3)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // ✅ Show Remove Friend Dialog
  void _showRemoveFriendDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${widget.friend.name} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
        final currentUserId = _authService.currentUserId; // ✅ Changed to getter
        if (currentUserId != null) {
          // ✅ FIXED: Use named parameters
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
            Navigator.pop(context); // Go back to friends page
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

  // ✅ Show Coming Soon
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon! 🚀'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }
}
