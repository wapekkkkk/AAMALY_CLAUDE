// ============================================
// FILE: lib/screens/search_page.dart (DARK THEME UI UPDATE ONLY)
// ============================================

import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../utils/task_helper.dart';
import '../task/task_detail_page.dart';
import '../../services/task_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _taskService = TaskService();
  final _authService = FirebaseAuthService();

  String _searchQuery = '';
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String _sortBy = 'deadline'; // deadline, priority, title

  // 🎨 Theme colors (match FriendsPage)
  static const Color kBg = Color(0xFF0E141B);
  static const Color kAppBarBg = Color(0xFF0B0F14);
  static const Color kSurface = Color(0xFF151D27);
  static const Color kSurface2 = Color(0xFF1B2430);
  static const Color kBorder = Color(0xFF263241);

  static const Color kText = Color(0xFFF2F4F8);
  static const Color kMuted = Color(0xFF9AA7B4);

  static const Color kPrimary = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    Logger.navigation('Dashboard', 'SearchPage');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // ✅ Filter and sort tasks
  List<Task> _filterAndSortTasks(List<Task> allTasks) {
    // Apply search filter
    var filtered = allTasks.where((task) {
      if (_searchQuery.isEmpty) return true;

      final titleMatch = task.title.toLowerCase().contains(_searchQuery);
      final descMatch = task.description.toLowerCase().contains(_searchQuery);
      final projectMatch =
          task.projectName.toLowerCase().contains(_searchQuery);

      return titleMatch || descMatch || projectMatch;
    }).toList();

    // Apply status filter
    if (_filterStatus != null) {
      filtered =
          filtered.where((task) => task.status == _filterStatus).toList();
    }

    // Apply priority filter
    if (_filterPriority != null) {
      filtered =
          filtered.where((task) => task.priority == _filterPriority).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'deadline':
        filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'priority':
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text(
          'Filter & Sort',
          style: TextStyle(color: kText),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                const Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterStatus == null,
                      selectedColor: kPrimary.withOpacity(0.2),
                      checkmarkColor: kPrimary,
                      labelStyle: TextStyle(
                        color: _filterStatus == null ? kText : kMuted,
                        fontWeight:
                            _filterStatus == null ? FontWeight.w600 : null,
                      ),
                      backgroundColor: kSurface2,
                      side: const BorderSide(color: kBorder),
                      onSelected: (_) =>
                          setDialogState(() => _filterStatus = null),
                    ),
                    ...TaskStatus.values.map((status) {
                      final c = TaskHelper.getStatusColor(status);
                      final selected = _filterStatus == status;
                      return FilterChip(
                        label: Text(TaskHelper.getStatusText(status)),
                        selected: selected,
                        selectedColor: c.withOpacity(0.25),
                        checkmarkColor: c,
                        labelStyle: TextStyle(
                          color: selected ? kText : kMuted,
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                        backgroundColor: kSurface2,
                        side: const BorderSide(color: kBorder),
                        onSelected: (v) => setDialogState(
                            () => _filterStatus = v ? status : null),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Priority Filter
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterPriority == null,
                      selectedColor: kPrimary.withOpacity(0.2),
                      checkmarkColor: kPrimary,
                      labelStyle: TextStyle(
                        color: _filterPriority == null ? kText : kMuted,
                        fontWeight:
                            _filterPriority == null ? FontWeight.w600 : null,
                      ),
                      backgroundColor: kSurface2,
                      side: const BorderSide(color: kBorder),
                      onSelected: (_) =>
                          setDialogState(() => _filterPriority = null),
                    ),
                    ...TaskPriority.values.map((priority) {
                      final c = TaskHelper.getPriorityColor(priority);
                      final selected = _filterPriority == priority;
                      return FilterChip(
                        label: Text(TaskHelper.getPriorityText(priority)),
                        selected: selected,
                        selectedColor: c.withOpacity(0.25),
                        checkmarkColor: c,
                        labelStyle: TextStyle(
                          color: selected ? kText : kMuted,
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                        backgroundColor: kSurface2,
                        side: const BorderSide(color: kBorder),
                        onSelected: (v) => setDialogState(
                            () => _filterPriority = v ? priority : null),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Sort By
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Deadline'),
                      selected: _sortBy == 'deadline',
                      selectedColor: kPrimary.withOpacity(0.25),
                      labelStyle: TextStyle(
                        color: _sortBy == 'deadline' ? kText : kMuted,
                        fontWeight:
                            _sortBy == 'deadline' ? FontWeight.w600 : null,
                      ),
                      backgroundColor: kSurface2,
                      side: const BorderSide(color: kBorder),
                      onSelected: (_) =>
                          setDialogState(() => _sortBy = 'deadline'),
                    ),
                    ChoiceChip(
                      label: const Text('Priority'),
                      selected: _sortBy == 'priority',
                      selectedColor: kPrimary.withOpacity(0.25),
                      labelStyle: TextStyle(
                        color: _sortBy == 'priority' ? kText : kMuted,
                        fontWeight:
                            _sortBy == 'priority' ? FontWeight.w600 : null,
                      ),
                      backgroundColor: kSurface2,
                      side: const BorderSide(color: kBorder),
                      onSelected: (_) =>
                          setDialogState(() => _sortBy = 'priority'),
                    ),
                    ChoiceChip(
                      label: const Text('Title'),
                      selected: _sortBy == 'title',
                      selectedColor: kPrimary.withOpacity(0.25),
                      labelStyle: TextStyle(
                        color: _sortBy == 'title' ? kText : kMuted,
                        fontWeight: _sortBy == 'title' ? FontWeight.w600 : null,
                      ),
                      backgroundColor: kSurface2,
                      side: const BorderSide(color: kBorder),
                      onSelected: (_) =>
                          setDialogState(() => _sortBy = 'title'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterPriority = null;
                _sortBy = 'deadline';
              });
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to search tasks'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kAppBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Tasks',
          style: TextStyle(
            color: kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_filterStatus != null || _filterPriority != null)
                  ? kPrimary
                  : kMuted,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: kBg,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: kText),
              decoration: InputDecoration(
                hintText: 'Search by title, description, or project...',
                hintStyle: const TextStyle(color: kMuted),
                prefixIcon: const Icon(Icons.search, color: kPrimary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: kMuted),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: kSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kPrimary, width: 1.2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _performSearch,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, delay: 300.ms),

          // ✅ Active Filters Display
          if (_filterStatus != null || _filterPriority != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kBg,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_filterStatus != null)
                    Chip(
                      avatar: Icon(
                        Icons.circle,
                        size: 12,
                        color: TaskHelper.getStatusColor(_filterStatus!),
                      ),
                      label: Text(
                        'Status: ${TaskHelper.getStatusText(_filterStatus!)}',
                        style: const TextStyle(fontSize: 12, color: kText),
                      ),
                      deleteIcon:
                          const Icon(Icons.close, size: 16, color: kMuted),
                      onDeleted: () => setState(() => _filterStatus = null),
                      backgroundColor: kSurface,
                      shape: StadiumBorder(
                        side: const BorderSide(color: kBorder),
                      ),
                    ),
                  if (_filterPriority != null)
                    Chip(
                      avatar: Icon(
                        Icons.flag,
                        size: 12,
                        color: TaskHelper.getPriorityColor(_filterPriority!),
                      ),
                      label: Text(
                        'Priority: ${TaskHelper.getPriorityText(_filterPriority!)}',
                        style: const TextStyle(fontSize: 12, color: kText),
                      ),
                      deleteIcon:
                          const Icon(Icons.close, size: 16, color: kMuted),
                      onDeleted: () => setState(() => _filterPriority = null),
                      backgroundColor: kSurface,
                      shape: StadiumBorder(
                        side: const BorderSide(color: kBorder),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ✅ Task List with StreamBuilder
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.getAllUserTasks(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading tasks',
                          style: TextStyle(fontSize: 16, color: kMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(fontSize: 14, color: kMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];
                final filteredTasks = _filterAndSortTasks(allTasks);

                return Column(
                  children: [
                    // Result Count
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '${filteredTasks.length} task(s) found',
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Task List
                    Expanded(
                      child: filteredTasks.isEmpty
                          ? Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.search_off
                                      : Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Start typing to search tasks'
                                      : 'No tasks found',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: kMuted,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try different keywords or filters',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kMuted,
                                    ),
                                  ),
                                ],
                              ],
                            )
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .slideX(begin: 0.1, delay: 400.ms))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isOverdue = task.isOverdue;
    final daysUntil = task.daysUntilDeadline;

    final statusColor = TaskHelper.getStatusColor(task.status);
    final priorityColor = TaskHelper.getPriorityColor(task.priority);

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
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kText,
                      decoration: task.status == TaskStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    TaskHelper.getStatusText(task.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 13,
                color: kMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Bottom Row: Project, Priority, Deadline
            Row(
              children: [
                // Project
                const Icon(Icons.folder_outlined, size: 14, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.projectName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 12),

                // Priority
                Icon(Icons.flag, size: 14, color: priorityColor),
                const SizedBox(width: 4),
                Text(
                  TaskHelper.getPriorityText(task.priority),
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // Deadline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withOpacity(0.18)
                        : Colors.blue.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isOverdue ? Colors.red : Colors.blue)
                          .withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isOverdue ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOverdue
                            ? 'OVERDUE'
                            : daysUntil == 0
                                ? 'TODAY'
                                : '${daysUntil}D',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : Colors.blue,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, delay: 500.ms),
    );
  }
}
