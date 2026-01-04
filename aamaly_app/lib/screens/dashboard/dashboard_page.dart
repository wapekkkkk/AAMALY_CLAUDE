// ============================================
// FILE: lib/screens/dashboard_page.dart (DARK THEME UI UPDATE ONLY)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/task.dart';
import '../../models/project.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../task/task_detail_page.dart';
import '../task/create_task_page.dart';
import '../project/project_detail_page.dart';
import '../calendar/calendar_page.dart';
import '../project/create_project_page.dart';
import '../search/search_page.dart';
import '../friends/friends_page.dart';
import '../profile/profile_page.dart';
import '../notifications/notifications_page.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
import '../fcm_test_page.dart'; // ✅ ADD THIS
import '../../services/push_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/page_transitions.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all';

  final _authService = FirebaseAuthService();
  final _projectService = ProjectService();
  final _taskService = TaskService();
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      PushNotificationService().initialize(userId);
      print('✅ Push notifications initialized for user: $userId');
    }
  }

  Future<void> _initializeNotifications() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      await PushNotificationService().initialize(userId);
    }
  }

  // 🎨 App palette (kept inside file, UI only)
  static const Color kBg = Color(0xFF0E141B);
  static const Color kSurface = Color(0xFF151D27);
  static const Color kSurface2 = Color(0xFF1B2430);
  static const Color kBorder = Color(0xFF263241);

  static const Color kText = Color(0xFFF2F4F8);
  static const Color kMuted = Color(0xFF9AA7B4);

  static const Color kPrimary = Color(0xFF7C4DFF);
  static const Color kDanger = Color(0xFFFF5C7A);
  static const Color kWarning = Color(0xFFFFC857);
  static const Color kSuccess = Color(0xFF2EE59D);
  static const Color kInfo = Color(0xFF4DA3FF);

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home - already here, do nothing
        break;

      case 1:
        // Calendar - Slide from right
        Navigator.push(
          context,
          PageTransitions.slideRight(const CalendarPage()),
        );
        break;

      case 2:
        // Add (center button) - Slide from bottom
        _showAddNewDialog();
        break;

      case 3:
        // Friends - Slide from right
        Navigator.push(
          context,
          PageTransitions.slideRight(const FriendsPage()),
        );
        break;

      case 4:
        // Search - Fade transition
        Navigator.push(
          context,
          PageTransitions.fade(const SearchPage()),
        );
        break;
    }
  }

  void _showAddNewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Add New', style: TextStyle(color: kText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt, color: kPrimary),
              title: const Text('New Task', style: TextStyle(color: kText)),
              onTap: () async {
                Navigator.pop(context); // Close dialog first
                await Navigator.push(
                  context,
                  PageTransitions.slideUp(
                      const CreateTaskPage()), // ✅ Smooth slide up!
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: kPrimary),
              title: const Text('New Project', style: TextStyle(color: kText)),
              onTap: () async {
                Navigator.pop(context); // Close dialog first
                await Navigator.push(
                  context,
                  PageTransitions.slideUp(
                      const CreateProjectPage()), // ✅ Smooth slide up!
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final userName = currentUser?.name.split(' ').first ?? 'User';
    final userId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ FIXED HEADER
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $userName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Have a nice day.',
                        style: TextStyle(
                          fontSize: 14,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),

                  // Notification Bell + Profile
                  Row(
                    children: [
                      StreamBuilder<int>(
                        stream: NotificationService().getUnreadCount(userId),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  size: 28,
                                ),
                                color: kPrimary,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsPage(),
                                    ),
                                  );
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: kDanger,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: kPrimary,
                        child: IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfilePage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ FILTER TABS
            StreamBuilder<List<Task>>(
              stream: _taskService.getMyTasks(userId),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final inProgressCount = tasks
                    .where((t) => t.status == TaskStatus.inProgress)
                    .length;
                final completedCount =
                    tasks.where((t) => t.status == TaskStatus.completed).length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      _buildFilterTab('My Tasks', tasks.length, 'all'),
                      const SizedBox(width: 12),
                      _buildFilterTab(
                          'In-progress', inProgressCount, 'in_progress'),
                      const SizedBox(width: 12),
                      _buildFilterTab('Completed', completedCount, 'completed'),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ✅ SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ PROJECT SECTION
                    StreamBuilder<List<Project>>(
                      stream: _projectService.getAllUserProjects(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final projects = snapshot.data ?? [];

                        if (projects.isEmpty) {
                          return Container(
                            height: 200,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: kBorder),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  const Text('No projects yet',
                                      style: TextStyle(color: kMuted)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateProjectPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Project'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 200,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: projects.length,
                            itemBuilder: (context, index) {
                              return _buildProjectCard(projects[index], index);
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ✅ TASK SECTION TITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tasks',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kText,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SearchPage()),
                              );
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(color: kPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ TASK LIST
                    StreamBuilder<List<Project>>(
                      stream: _projectService.getAllUserProjects(userId),
                      builder: (context, projectSnapshot) {
                        final projects = projectSnapshot.data ?? [];

                        return StreamBuilder<List<Task>>(
                          stream: _taskService.getMyTasks(userId),
                          builder: (context, taskSnapshot) {
                            if (taskSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(40.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (taskSnapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text(
                                    'Error: ${taskSnapshot.error}',
                                    style: const TextStyle(color: kText),
                                  ),
                                ),
                              );
                            }

                            var tasks = taskSnapshot.data ?? [];

                            if (_selectedFilter == 'in_progress') {
                              tasks = tasks
                                  .where(
                                      (t) => t.status == TaskStatus.inProgress)
                                  .toList();
                            } else if (_selectedFilter == 'completed') {
                              tasks = tasks
                                  .where(
                                      (t) => t.status == TaskStatus.completed)
                                  .toList();
                            }

                            if (tasks.isEmpty) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox,
                                          size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No tasks found',
                                        style: TextStyle(
                                            fontSize: 16, color: kMuted),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const CreateTaskPage()),
                                          );
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create Task'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final displayTasks = tasks.take(5).toList();

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayTasks.length,
                              itemBuilder: (context, index) {
                                return _buildTaskCard(
                                    displayTasks[index], projects);
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFilterTab(String label, int count, String filter) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : kSurface2,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? kPrimary : kText,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project, int index) {
    final gradientColors = [
      project.color,
      project.color.withOpacity(0.7),
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(project: project),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school,
                          color: Colors.white, size: 20),
                    ),
                    if (project.hasCollaborators)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: kInfo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: Colors.white.withOpacity(0.85)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ...project.taskTypes.take(2).map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            type,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const Spacer(),
            if (project.hasCollaborators)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${project.collaboratorIds.length} ${project.collaboratorIds.length == 1 ? 'member' : 'members'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: project.totalTasks > 0
                    ? project.completedTasks / project.totalTasks
                    : 0.0,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${project.totalTasks > 0 ? ((project.completedTasks / project.totalTasks) * 100).toStringAsFixed(0) : '0'}% Complete',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Created ${DateFormat('MMM d, yyyy').format(project.dateCreated)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, List<Project> projects) {
    final isCompleted = task.status == TaskStatus.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;

    Project? project;
    try {
      project = projects.firstWhere(
        (p) => p.name == task.projectName || p.code == task.projectName,
      );
    } catch (e) {
      project = null;
    }

    final projectColor = project?.color ?? kPrimary;

    Color statusColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = kSuccess;
        statusLabel = 'Completed';
        break;
      case TaskStatus.inProgress:
        statusColor = kInfo;
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = kWarning;
        statusLabel = 'To Do';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.status == TaskStatus.completed
                        ? Icons.check_circle
                        : Icons.assignment,
                    color: projectColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? kMuted : kText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due ${DateFormat('MMM d, yyyy').format(task.deadline)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: daysUntil < 0 ? kDanger : kMuted,
                          fontWeight: daysUntil < 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.white.withOpacity(0.65)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: projectColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    task.projectName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: projectColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _toggleTaskCompletion(task),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isCompleted ? kWarning : kSuccess,
                  side: BorderSide(color: isCompleted ? kWarning : kSuccess),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  isCompleted ? 'Mark as In Progress' : 'Mark as Done',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      if (task.status == TaskStatus.completed) {
        await _taskService.markAsInProgress(task.id);
      } else {
        await _taskService.markAsComplete(task.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.status == TaskStatus.completed
                ? 'Task marked as in progress!'
                : 'Task marked as done!',
          ),
          backgroundColor: kSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: kSurface2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          border: Border(
            top: BorderSide(color: kBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: kSurface2,
          selectedItemColor: kPrimary,
          unselectedItemColor: kMuted,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 28), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today, size: 24), label: 'Projects'),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 28,
                backgroundColor: kPrimary,
                child: Icon(Icons.add, color: Colors.white, size: 32),
              ),
              label: 'Add',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.people, size: 28), label: 'Team'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search, size: 28), label: 'Search'),
          ],
        ),
      ),
    );
  }
}
