// ============================================
// FILE: lib/screens/my_statistics_page.dart
// UPDATED THEME: Dark + Neon (cards + text consistent)
// ============================================

import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/task_service.dart';

class MyStatisticsPage extends StatefulWidget {
  const MyStatisticsPage({Key? key}) : super(key: key);

  @override
  State<MyStatisticsPage> createState() => _MyStatisticsPageState();
}

class _MyStatisticsPageState extends State<MyStatisticsPage> {
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

  List<Task> _allTasks = [];
  bool _isLoading = true;

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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionRate =
        _totalTasks > 0 ? (_completedTasks / _totalTasks) : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: const Text('My Statistics'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion Card (gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accent, _accent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Completion Rate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(completionRate * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_completedTasks of $_totalTasks tasks completed',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: completionRate,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.22),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Task Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Completed',
                          _completedTasks,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'In Progress',
                          _inProgressTasks,
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
                          _todoTasks,
                          Colors.orange,
                          Icons.radio_button_unchecked,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Overdue',
                          _overdueTasks,
                          Colors.red,
                          Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActivityCard(
                    'This Week',
                    _thisWeekTasks,
                    'Tasks with deadlines this week',
                    Icons.calendar_today,
                    _accent,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    'This Month',
                    _thisMonthTasks,
                    'Tasks with deadlines this month',
                    Icons.calendar_month,
                    _accent2,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    'Total Tasks',
                    _totalTasks,
                    'All time task count',
                    Icons.assignment,
                    _accent,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Priority Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _text,
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

  Widget _buildStatusCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            value.toString(),
            style: TextStyle(
              fontSize: 26,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    int value,
    String subtitle,
    IconData icon,
    Color glowColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glowColor.withOpacity(0.22)),
            ),
            child: Icon(icon, color: glowColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: glowColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    final highPriority =
        _allTasks.where((t) => t.priority == TaskPriority.high).length;
    final mediumPriority =
        _allTasks.where((t) => t.priority == TaskPriority.medium).length;
    final lowPriority =
        _allTasks.where((t) => t.priority == TaskPriority.low).length;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          _buildPriorityRow('High Priority', highPriority, Colors.red),
          const SizedBox(height: 14),
          _buildPriorityRow('Medium Priority', mediumPriority, Colors.orange),
          const SizedBox(height: 14),
          _buildPriorityRow('Low Priority', lowPriority, Colors.green),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String label, int count, Color color) {
    final percentage = _totalTasks > 0 ? (count / _totalTasks) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count tasks (${(percentage * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 78,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
