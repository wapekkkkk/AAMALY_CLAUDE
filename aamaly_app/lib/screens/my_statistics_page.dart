// ============================================
// FILE: lib/screens/my_statistics_page.dart
// MY STATISTICS PAGE - Task Breakdown & Progress
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firebase_auth_service.dart';
import '../services/task_service.dart';

class MyStatisticsPage extends StatefulWidget {
  const MyStatisticsPage({Key? key}) : super(key: key);

  @override
  State<MyStatisticsPage> createState() => _MyStatisticsPageState();
}

class _MyStatisticsPageState extends State<MyStatisticsPage> {
  final _authService = FirebaseAuthService();
  final _taskService = TaskService();

  List<Task> _allTasks = [];
  bool _isLoading = true;

  // Stats
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _inProgressTasks = 0;
  int _todoTasks = 0;
  int _overdueTasks = 0;
  int _thisWeekTasks = 0;
  int _thisMonthTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final tasks = await _taskService.getMyTasks(userId).first;

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        setState(() {
          _allTasks = tasks;
          _totalTasks = tasks.length;

          _completedTasks =
              tasks.where((t) => t.status == TaskStatus.completed).length;

          _inProgressTasks =
              tasks.where((t) => t.status == TaskStatus.inProgress).length;

          _todoTasks = tasks.where((t) => t.status == TaskStatus.todo).length;

          _overdueTasks = tasks
              .where((t) =>
                  t.deadline.isBefore(now) && t.status != TaskStatus.completed)
              .length;

          _thisWeekTasks =
              tasks.where((t) => t.deadline.isAfter(weekStart)).length;

          _thisMonthTasks =
              tasks.where((t) => t.deadline.isAfter(monthStart)).length;

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _totalTasks > 0
        ? (_completedTasks / _totalTasks * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('My Statistics'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ COMPLETION RATE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Completion Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$completionRate%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_completedTasks of $_totalTasks tasks completed',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ TASK STATUS BREAKDOWN
                  const Text(
                    'Task Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Completed',
                          _completedTasks.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'In Progress',
                          _inProgressTasks.toString(),
                          Colors.blue,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'To Do',
                          _todoTasks.toString(),
                          Colors.orange,
                          Icons.radio_button_unchecked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Overdue',
                          _overdueTasks.toString(),
                          Colors.red,
                          Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ✅ TIME PERIOD BREAKDOWN
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActivityCard(
                    'This Week',
                    _thisWeekTasks.toString(),
                    'Tasks with deadlines this week',
                    Icons.calendar_today,
                  ),

                  const SizedBox(height: 12),

                  _buildActivityCard(
                    'This Month',
                    _thisMonthTasks.toString(),
                    'Tasks with deadlines this month',
                    Icons.calendar_month,
                  ),

                  const SizedBox(height: 12),

                  _buildActivityCard(
                    'Total Tasks',
                    _totalTasks.toString(),
                    'All time task count',
                    Icons.assignment,
                  ),

                  const SizedBox(height: 24),

                  // ✅ PRIORITY BREAKDOWN
                  const Text(
                    'Priority Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPriorityBreakdown(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ✅ Build Status Card
  Widget _buildStatusCard(
      String label, String value, Color color, IconData icon) {
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Build Activity Card
  Widget _buildActivityCard(
      String title, String value, String subtitle, IconData icon) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2196F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Build Priority Breakdown
  Widget _buildPriorityBreakdown() {
    final highPriority =
        _allTasks.where((t) => t.priority == TaskPriority.high).length;
    final mediumPriority =
        _allTasks.where((t) => t.priority == TaskPriority.medium).length;
    final lowPriority =
        _allTasks.where((t) => t.priority == TaskPriority.low).length;

    return Container(
      padding: const EdgeInsets.all(20),
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
          _buildPriorityRow('High Priority', highPriority, Colors.red),
          const SizedBox(height: 12),
          _buildPriorityRow('Medium Priority', mediumPriority, Colors.orange),
          const SizedBox(height: 12),
          _buildPriorityRow('Low Priority', lowPriority, Colors.green),
        ],
      ),
    );
  }

  // ✅ Build Priority Row
  Widget _buildPriorityRow(String label, int count, Color color) {
    final percentage =
        _totalTasks > 0 ? (count / _totalTasks * 100).toStringAsFixed(0) : '0';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count tasks ($percentage%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _totalTasks > 0 ? count / _totalTasks : 0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
