// ============================================
// FILE: lib/screens/task_history_page.dart
// TASK HISTORY PAGE - Completed Tasks List
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firebase_auth_service.dart';
import '../services/task_service.dart';
import 'task_detail_page.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({Key? key}) : super(key: key);

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  final _authService = FirebaseAuthService();
  final _taskService = TaskService();

  List<Task> _completedTasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, week, month

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final allTasks = await _taskService.getMyTasks(userId).first;

        final completed =
            allTasks.where((t) => t.status == TaskStatus.completed).toList();

        // Sort by deadline (most recent first)
        completed.sort((a, b) => b.deadline.compareTo(a.deadline));

        setState(() {
          _completedTasks = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading task history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _completedTasks
            .where((t) => t.deadline.isAfter(weekAgo))
            .toList();

      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        return _completedTasks
            .where((t) => t.deadline.isAfter(monthStart))
            .toList();

      default:
        return _completedTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTasks = _filteredTasks;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('Task History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ✅ FILTER TABS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab('All Time', 'all'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterTab('This Week', 'week'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterTab('This Month', 'month'),
                ),
              ],
            ),
          ),

          // ✅ TASK LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(displayTasks[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Filter Tab
  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
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
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  // ✅ Build Task Card
  Widget _buildTaskCard(Task task) {
    final now = DateTime.now();
    final daysAgo = now.difference(task.deadline).inDays;
    final timeAgo = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';

    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange;
        break;
      case TaskPriority.low:
        priorityColor = Colors.green;
        break;
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
        child: Row(
          children: [
            // ✅ Checkmark Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // ✅ Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.projectName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(task.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ✅ Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priority == TaskPriority.high
                    ? 'High'
                    : task.priority == TaskPriority.medium
                        ? 'Med'
                        : 'Low',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Build Empty State
  Widget _buildEmptyState() {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case 'week':
        message = 'No tasks completed this week';
        subtitle = 'Complete some tasks to see them here!';
        break;
      case 'month':
        message = 'No tasks completed this month';
        subtitle = 'Complete some tasks to see them here!';
        break;
      default:
        message = 'No completed tasks yet';
        subtitle = 'Complete tasks to build your history!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
