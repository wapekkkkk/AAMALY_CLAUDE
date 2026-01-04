// ============================================
// FILE: lib/screens/calendar_page.dart (DARK THEME UI UPDATE ONLY)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/reminder.dart';
import '../task/task_detail_page.dart';
import 'create_reminder_page.dart';
import '../../services/task_service.dart';
import '../../services/reminder_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/logger.dart';
import '../../utils/error_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  DateTime _currentWeekStart = DateTime.now();

  final _taskService = TaskService();
  final _reminderService = ReminderService();
  final _authService = FirebaseAuthService();

  // 🎨 Theme colors (same family as Dashboard)
  static const Color kBg = Color(0xFF0E141B);
  static const Color kSurface = Color(0xFF151D27);
  static const Color kSurface2 = Color(0xFF1B2430);
  static const Color kBorder = Color(0xFF263241);

  static const Color kText = Color(0xFFF2F4F8);
  static const Color kMuted = Color(0xFF9AA7B4);

  static const Color kPrimary = Color(0xFF7C4DFF);

  // Keep reminders pink (as requested)
  static const Color kPink = Color(0xFFFF69B4);

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(_focusedMonth);
    Logger.navigation('Dashboard', 'CalendarPage');
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _focusedMonth = _currentWeekStart;
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _focusedMonth = _currentWeekStart;
    });
  }

  List<Task> _getTasksForDate(List<Task> allTasks, DateTime date) {
    return allTasks.where((task) {
      return task.deadline.year == date.year &&
          task.deadline.month == date.month &&
          task.deadline.day == date.day;
    }).toList();
  }

  int _getTaskCountForDate(List<Task> allTasks, DateTime date) {
    return _getTasksForDate(allTasks, date).length;
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    try {
      await _reminderService.toggleReminder(reminder.id, !reminder.isActive);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reminder.isActive ? 'Reminder turned off' : 'Reminder turned on',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to toggle reminder', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Keeps your date picker purple
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _focusedMonth = picked;
        _selectedDate = picked;
        _currentWeekStart = _getWeekStart(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view calendar'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,

      // ✅ Dark AppBar
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(242, 244, 248, 1)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: kText),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<List<Task>>(
        stream: _taskService.getAllUserTasks(currentUserId),
        builder: (context, taskSnapshot) {
          final allTasks = taskSnapshot.data ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ✅ Month Header
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM, yyyy')
                            .format(_focusedMonth)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kText,
                          letterSpacing: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: kPrimary.withOpacity(0.25)),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: kPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

                // ✅ Week Calendar with arrows (dark surface)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _previousWeek,
                        icon: const Icon(Icons.chevron_left),
                        color: kPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(child: _buildWeekCalendar(allTasks)),
                      IconButton(
                        onPressed: _nextWeek,
                        icon: const Icon(Icons.chevron_right),
                        color: kPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms)
                    .slideY(begin: -0.05),

                const SizedBox(height: 8),

                // ✅ Task List Section
                _buildTaskList(allTasks),

                const SizedBox(height: 10),

                // ✅ Reminder Section (pink kept)
                _buildReminderSection(currentUserId),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ✅ WEEK CALENDAR (7 days) - Dark theme
  Widget _buildWeekCalendar(List<Task> allTasks) {
    final weekDays = List.generate(7, (index) {
      return _currentWeekStart.add(Duration(days: index));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((date) {
        final isSelected = _selectedDate.year == date.year &&
            _selectedDate.month == date.month &&
            _selectedDate.day == date.day;

        final isToday = DateTime.now().year == date.year &&
            DateTime.now().month == date.month &&
            DateTime.now().day == date.day;

        final taskCount = _getTaskCountForDate(allTasks, date);
        final hasDeadlines = taskCount > 0;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Column(
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 2),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimary
                            : isToday
                                ? kPrimary.withOpacity(0.18)
                                : kSurface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? kPrimary.withOpacity(0.35) : kBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? kPrimary
                                  : kText,
                        ),
                      ),
                    ),
                    if (hasDeadlines)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$taskCount',
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
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// TASK LIST for the selected date (dark)
  Widget _buildTaskList(List<Task> allTasks) {
    final tasksForSelectedDate = _getTasksForDate(allTasks, _selectedDate);
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today\'s Tasks' : 'Tasks',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
              if (tasksForSelectedDate.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withOpacity(0.25)),
                  ),
                  child: Text(
                    '${tasksForSelectedDate.length} ${tasksForSelectedDate.length == 1 ? 'Task' : 'Tasks'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (tasksForSelectedDate.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.event_available, size: 56, color: kMuted),
                    SizedBox(height: 12),
                    Text('No tasks for this day',
                        style: TextStyle(fontSize: 16, color: kText)),
                    SizedBox(height: 6),
                    Text('Enjoy your free time!',
                        style: TextStyle(fontSize: 14, color: kMuted)),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.9, 0.9))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasksForSelectedDate.length,
              itemBuilder: (context, index) {
                final task = tasksForSelectedDate[index];
                return _buildTaskCard(task)
                    .animate()
                    .fadeIn(
                        delay: (50 * index).ms, duration: 300.ms) // ✅ Staggered
                    .slideX(begin: 0.15, delay: (50 * index).ms);
              },
            ),
        ],
      ),
    );
  }

  /// REMINDER SECTION (dark background, but keep pink accents)
  Widget _buildReminderSection(String userId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kText,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateReminderPage()),
                  );

                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPink, // ✅ keep pink
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Reminder>>(
            stream: _reminderService.getUserReminders(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      'Error loading reminders: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[200]),
                    ),
                  ),
                );
              }

              final reminders = snapshot.data ?? [];

              if (reminders.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.alarm_off, size: 48, color: kMuted),
                        SizedBox(height: 12),
                        Text('No reminders yet',
                            style: TextStyle(fontSize: 14, color: kMuted)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _buildReminderCard(reminder)
                      .animate()
                      .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                      .slideX(begin: 0.15, delay: (50 * index).ms);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// TASK CARD (dark)
  Widget _buildTaskCard(Task task) {
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

    Color statusColor;
    switch (task.status) {
      case TaskStatus.completed:
        statusColor = Colors.green;
        break;
      case TaskStatus.inProgress:
        statusColor = Colors.blue;
        break;
      case TaskStatus.todo:
        statusColor = Colors.grey;
        break;
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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kText,
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: statusColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          task.status.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: priorityColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          task.priority
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white.withOpacity(0.55)),
          ],
        ),
      ),
    );
  }

  /// REMINDER CARD (dark surface, but keep pink icon styling)
  Widget _buildReminderCard(Reminder reminder) {
    final frequencyColor =
        ReminderService.getFrequencyColor(reminder.frequency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPink.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.alarm,
              color: kPink,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(reminder.reminderTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: frequencyColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: frequencyColor.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        ReminderService.getFrequencyText(reminder.frequency),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: frequencyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: reminder.isActive,
            activeColor: kPink,
            onChanged: (value) async {
              try {
                await _reminderService.toggleReminder(reminder.id, value);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Reminder activated' : 'Reminder deactivated',
                    ),
                    backgroundColor: kSurface2,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to toggle reminder: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),

          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () => _showDeleteReminderDialog(reminder),
          ),
        ],
      ),
    );
  }

  void _showDeleteReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        titleTextStyle: const TextStyle(
          color: kText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: kMuted),
        title: const Text('Delete Reminder'),
        content: Text(
          'Are you sure you want to delete "${reminder.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // close confirm dialog

              if (!mounted) return;

              // show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: kPink),
                ),
              );

              try {
                await _reminderService.deleteReminder(reminder.id);

                if (!mounted) return;
                Navigator.pop(context); // close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder deleted successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete reminder: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
