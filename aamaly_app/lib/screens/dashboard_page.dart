// ============================================
// FILE: lib/screens/dashboard_page.dart (UPDATED WITH PROJECT COLORS)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/firebase_auth_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import 'login_page.dart';
import 'task_detail_page.dart';
import 'create_task_page.dart';
import 'project_list_page.dart';
import 'project_detail_page.dart';
import 'calendar_page.dart';
import 'create_project_page.dart';
import 'search_page.dart';
import 'collaborators_page.dart';
import '../data/mock_users.dart';

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

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home - already here
        break;
      case 1: // Calendar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        );
        break;
      case 2: // Add New
        _showAddNewDialog();
        break;
      case 3: // Collaborators
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CollaboratorsPage()),
        );
        break;
      case 4: // Search
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
        break;
    }
  }

  void _showAddNewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFF2196F3)),
              title: const Text('New Task'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateTaskPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFF2196F3)),
              title: const Text('New Project'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateProjectPage()),
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Have a nice day.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2196F3),
                    child: IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          try {
                            await _authService.logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
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
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs with Real-time Counts
            StreamBuilder<List<Task>>(
              stream: _taskService.getAllUserTasks(userId),
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

            // Project Cards (Real-time from Firestore)
            StreamBuilder<List<Project>>(
              stream: _projectService.getAllUserProjects(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No projects yet',
                              style: TextStyle(color: Colors.grey[600])),
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
                              backgroundColor: const Color(0xFF2196F3),
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
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(projects[index], index);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Task Section Title
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
                      color: Color(0xFF1A1A2E),
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
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // ✅ UPDATED: Task List with NESTED StreamBuilder
            Expanded(
              child: StreamBuilder<List<Project>>(
                stream: _projectService.getAllUserProjects(userId),
                builder: (context, projectSnapshot) {
                  final projects = projectSnapshot.data ?? [];

                  return StreamBuilder<List<Task>>(
                    stream: _taskService.getAllUserTasks(userId),
                    builder: (context, taskSnapshot) {
                      if (taskSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (taskSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${taskSnapshot.error}'),
                        );
                      }

                      var tasks = taskSnapshot.data ?? [];

                      // Apply filter
                      if (_selectedFilter == 'in_progress') {
                        tasks = tasks
                            .where((t) => t.status == TaskStatus.inProgress)
                            .toList();
                      } else if (_selectedFilter == 'completed') {
                        tasks = tasks
                            .where((t) => t.status == TaskStatus.completed)
                            .toList();
                      }

                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateTaskPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create Task'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Show only first 5 tasks
                      final displayTasks = tasks.take(5).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayTasks.length,
                        itemBuilder: (context, index) {
                          // ✅ NOW PASS PROJECTS
                          return _buildTaskCard(displayTasks[index], projects);
                        },
                      );
                    },
                  );
                },
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
            color: isSelected ? const Color(0xFF2196F3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
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
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                        color: Colors.white.withOpacity(0.2),
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
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_vert, color: Colors.white.withOpacity(0.8)),
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
            ...project.taskTypes.take(2).map((type) => Padding(
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
                )),
            const Spacer(),
            if (project.hasCollaborators)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${project.collaboratorIds.length} ${project.collaboratorIds.length == 1 ? 'member' : 'members'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
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
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${project.totalTasks > 0 ? ((project.completedTasks / project.totalTasks) * 100).toStringAsFixed(0) : '0'}% Complete',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Created ${DateFormat('MMM d, yyyy').format(project.dateCreated)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Now accepts projects list
  Widget _buildTaskCard(Task task, List<Project> projects) {
    final isCompleted = task.status == TaskStatus.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;

    // ✅ GET PROJECT COLOR
    Project? project;
    try {
      project = projects.firstWhere(
        (p) => p.name == task.projectName || p.code == task.projectName,
      );
    } catch (e) {
      project = null;
    }

    // ✅ Use project color or default blue
    final projectColor = project?.color ?? const Color(0xFF2196F3);

    Color statusColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = Colors.green;
        statusLabel = 'Completed';
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.blue;
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'To Do';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ✅ ICON WITH PROJECT COLOR
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.1),
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
                          color: isCompleted
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due ${DateFormat('MMM d, yyyy').format(task.deadline)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: daysUntil < 0 ? Colors.red : Colors.grey[600],
                          fontWeight: daysUntil < 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                // ✅ PROJECT BADGE WITH PROJECT COLOR
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: projectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                  foregroundColor: isCompleted ? Colors.orange : Colors.green,
                  side: BorderSide(
                      color: isCompleted ? Colors.orange : Colors.green),
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
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
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
              backgroundColor: Color(0xFF2196F3),
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
    );
  }
}
