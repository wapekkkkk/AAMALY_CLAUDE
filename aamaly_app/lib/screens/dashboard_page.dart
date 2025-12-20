// ============================================
// FILE: lib/screens/dashboard_page.dart
// ============================================
//try test
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../data/mock_data.dart';
import '../data/mock_projects.dart';
import '../services/auth_service.dart';
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
import '../services/firebase_auth_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _selectedFilter = 'all'; // all, my_project, in_progress, completed
  final _authService = AuthService();

  List<Task> _allTasks = [];
  List<Project> _allProjects = [];

  @override
  void initState() {
    super.initState();
    _allTasks = MockData.getTasks();
    _allProjects = MockProjects.getProjects();
  }

  int get _myProjectCount => _allProjects.length;
  int get _inProgressCount =>
      _allTasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get _completedCount =>
      _allTasks.where((t) => t.status == TaskStatus.completed).length;

  List<Task> get _filteredTasks {
    switch (_selectedFilter) {
      case 'my_project':
        return _allTasks;
      case 'in_progress':
        return _allTasks
            .where((t) => t.status == TaskStatus.inProgress)
            .toList();
      case 'completed':
        return _allTasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();
      default:
        return _allTasks;
    }
  }

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
      case 3: // Collaborators (CHANGED from Notifications)
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
                final newTask = await Navigator.push<Task>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateTaskPage()),
                );
                if (newTask != null) {
                  setState(() {
                    _allTasks.insert(0, newTask);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFF2196F3)),
              title: const Text('New Project'),
              onTap: () async {
                Navigator.pop(context);
                final newProject = await Navigator.push<Project>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateProjectPage()),
                );
                if (newProject != null) {
                  setState(() {
                    _allProjects.insert(0, newProject);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _authService.currentUser?.name.split(' ').first ?? 'User';

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
                                    backgroundColor: Colors.red),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          try {
                            await FirebaseAuthService().logout();

                            // Clear all routes and go to login
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
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

            // Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterTab('My Project', _myProjectCount, 'my_project'),
                  const SizedBox(width: 12),
                  _buildFilterTab(
                      'In-progress', _inProgressCount, 'in_progress'),
                  const SizedBox(width: 12),
                  _buildFilterTab('Completed', _completedCount, 'completed'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Project Cards (Horizontal Scroll)
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _allProjects.length,
                itemBuilder: (context, index) {
                  final project = _allProjects[index];
                  return _buildProjectCard(project, index);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Task Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full task list
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

            // Task List
            Expanded(
              child: _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount:
                          _filteredTasks.length > 5 ? 5 : _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return _buildTaskCard(task);
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
    // Use project's actual color
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
                // Project Icon + Group Badge
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
                    // Group Icon Badge (shows if collaborative)
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
                          child: const Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 12,
                          ),
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
            ...project.taskTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                )),
            const Spacer(),

            // ✨ FIXED: Show collaborator avatars if project has team members
            if (project.hasCollaborators)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // Avatar Stack (show first 3) - FIXED positioning
                    ...List.generate(
                      project.collaboratorIds.length > 3
                          ? 3
                          : project.collaboratorIds.length,
                      (i) {
                        final userId = project.collaboratorIds[i];
                        final user = MockUsers.getUserById(userId);
                        return Transform.translate(
                          offset: Offset(i * -8.0, 0), // Overlap effect
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Text(
                                user?.initials ?? '?',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: project.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 8),

                    // Member count
                    Text(
                      '${project.collaboratorIds.length} ${project.collaboratorIds.length == 1 ? 'member' : 'members'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Progress Bar
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
              'Date Created ${DateFormat('MMM d, yyyy').format(project.dateCreated)}',
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

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == TaskStatus.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;

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
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.status == TaskStatus.completed
                        ? Icons.check_circle
                        : Icons.assignment,
                    color: const Color(0xFF2196F3),
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

            // Tags Row
            Row(
              children: [
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.projectName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),

            // Toggle Completion Button
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

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final newStatus = task.status == TaskStatus.completed
            ? TaskStatus.inProgress
            : TaskStatus.completed;

        _allTasks[index] = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          deadline: task.deadline,
          status: newStatus,
          priority: task.priority,
          projectName: task.projectName,
        );
      }
    });

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
            icon: Icon(Icons.people,
                size: 28), // CHANGED from notifications to people
            label: 'Team', // CHANGED label
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 28), label: 'Search'),
        ],
      ),
    );
  }
}
