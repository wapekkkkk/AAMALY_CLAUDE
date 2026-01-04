// ============================================
// FILE: lib/screens/task_history_page.dart
// UPDATED THEME: Dark + Neon (matches Profile/TaskDetail)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/task_service.dart';
import '../task/task_detail_page.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({Key? key}) : super(key: key);

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  // ===== Theme (Dark) =====
  static const Color _bg = Color(0xFF0E141B);
  static const Color _card = Color(0xFF121A23);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _text = Color(0xFFF8FAFC);
  static const Color _muted = Color(0xFF9AA4B2);
  static const Color _accent = Color(0xFF7C4DFF);
  static const Color _accent2 = Color(0xFF00E5FF);

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

        completed.sort((a, b) => b.deadline.compareTo(a.deadline));

        setState(() {
          _completedTasks = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: const Text('Task History'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Bar (Card)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildFilterTab('All Time', 'all')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterTab('This Week', 'week')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterTab('This Month', 'month')),
                ],
              ),
            ),
          ),

          // Tasks
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_accent, _accent2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF0F1720),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final now = DateTime.now();
    final daysAgo = now.difference(task.deadline).inDays;
    final timeAgo = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';

    Color priorityColor;
    String prLabel;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red;
        prLabel = 'High';
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange;
        prLabel = 'Med';
        break;
      case TaskPriority.low:
        priorityColor = Colors.green;
        prLabel = 'Low';
        break;
    }

    final projectLabel =
        task.projectName.trim().isEmpty ? 'No project' : task.projectName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailPage(task: task)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Completed icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.22)),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.folder, size: 14, color: _muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          projectLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: _muted),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(task.deadline),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: _muted.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Priority
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor.withOpacity(0.25)),
              ),
              child: Text(
                prLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: priorityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case 'week':
        message = 'No tasks completed this week';
        subtitle = 'Complete some tasks to see them here.';
        break;
      case 'month':
        message = 'No tasks completed this month';
        subtitle = 'Complete some tasks to see them here.';
        break;
      default:
        message = 'No completed tasks yet';
        subtitle = 'Complete tasks to build your history.';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72, color: _muted.withOpacity(0.6)),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
