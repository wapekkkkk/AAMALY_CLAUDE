// ============================================
// FILE: lib/screens/profile_page.dart
// COMPLETE PROFILE PAGE - PRIORITY 1 FEATURES
// ============================================

import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/friend_service.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'my_statistics_page.dart';
import 'task_history_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = FirebaseAuthService();
  final _projectService = ProjectService();
  final _taskService = TaskService();
  final _friendService = FriendService();
// ===== Theme (Dark) =====
  static const Color _bg = Color(0xFF0E141B);
  static const Color _card = Color(0xFF121A23);
  static const Color _card2 = Color(0xFF0F1720);
  static const Color _border = Color(0x1AFFFFFF); // white 10%
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF9AA4B2);

  static const Color _accent = Color(0xFF7C4DFF); // purple
  static const Color _accent2 = Color(0xFF00E5FF); // cyan (optional highlight)

  int _projectCount = 0;
  int _taskCount = 0;
  int _friendCount = 0;
  bool _isLoading = true;
  bool _notificationsEnabled = true; // TODO: Load from preferences

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final projects = await _projectService.getAllUserProjects(userId).first;
        final tasks = await _taskService.getMyTasks(userId).first;
        final friends = await _friendService.getFriendsWithDetails(userId);

        setState(() {
          _projectCount = projects.length;
          _taskCount = tasks.length;
          _friendCount = friends.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '';
    final userInitials = user?.initials ?? 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0E141B),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ✅ 1. HEADER SECTION (Gradient + Avatar + Name)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7C4DFF),
                      Color(0xFF00E5FF),
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
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // ✅ Avatar with Initials
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C4DFF),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .scale(begin: const Offset(0.5, 0.5), delay: 200.ms),

                    const SizedBox(height: 16),

                    // ✅ Name
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1, delay: 300.ms),

                    const SizedBox(height: 4),

                    // ✅ Email
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.1, delay: 350.ms),

                    const SizedBox(height: 20),

                    // ✅ Edit Profile Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                        if (result == true) {
                          setState(() {}); // Refresh to show updated info
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), delay: 400.ms),

                    const SizedBox(height: 30),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
            ),

            // ✅ 2. STATS ROW
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
                              const Color(0xFF7C4DFF),
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
                              Icons.people,
                              _friendCount.toString(),
                              'Friends',
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

            // ✅ 3. ACCOUNT SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      children: [
                        _buildListTile(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                          subtitle: 'Name, email, bio',
                          onTap: () => _showComingSoon(),
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.lock_outline,
                          title: 'Email & Password',
                          subtitle: 'Change your email or password',
                          onTap: () => _showComingSoon(),
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle:
                              _notificationsEnabled ? 'Enabled' : 'Disabled',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              // TODO: Save to preferences
                            },
                            activeColor: const Color(0xFF7C4DFF),
                          ),
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.1, delay: 600.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ✅ 4. ACTIVITY SECTION
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
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      children: [
                        _buildListTile(
                          icon: Icons.bar_chart_outlined,
                          title: 'My Statistics',
                          subtitle: 'View your productivity stats',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyStatisticsPage(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.history,
                          title: 'Task History',
                          subtitle: 'View completed tasks',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TaskHistoryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.1, delay: 700.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ✅ 5. ABOUT SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      children: [
                        _buildListTile(
                          icon: Icons.info_outline,
                          title: 'About Aamaly',
                          subtitle: 'Learn more about the app',
                          onTap: () => _showAboutDialog(),
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we protect your data',
                          onTap: () => _showComingSoon(),
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'Our terms and conditions',
                          onTap: () => _showComingSoon(),
                        ),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        _buildListTile(
                          icon: Icons.phone_iphone,
                          title: 'Version',
                          subtitle: '1.0.0',
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(begin: 0.1, delay: 800.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            // ✅ 6. LOGOUT BUTTON (Danger Zone)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms)
                  .shake(delay: 1200.ms, duration: 300.ms),
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w600,
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

  // ✅ Build List Tile
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.22)),
        ),
        child: Icon(icon, color: _accent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: _muted)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      splashColor: _accent.withOpacity(0.08),
      hoverColor: _accent.withOpacity(0.06),
    );
  }

  // ✅ Show Logout Dialog
  void _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
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
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _authService.logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Show About Dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Aamaly',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.task_alt, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
            'A collaborative task management app for students and teams.'),
        const SizedBox(height: 12),
        const Text('Built with Flutter & Firebase'),
        const SizedBox(height: 8),
        const Text('© 2025 Aamaly. All rights reserved.'),
      ],
    );
  }

  // ✅ Show Coming Soon
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon! 🚀'),
        backgroundColor: Color(0xFF7C4DFF),
      ),
    );
  }
}
