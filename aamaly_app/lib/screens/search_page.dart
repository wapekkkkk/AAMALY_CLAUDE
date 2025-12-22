// ============================================
// FILE: lib/screens/search_page.dart (UPDATED WITH FIREBASE)
// ============================================

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/task_helper.dart';
import 'task_detail_page.dart';
import '../services/task_service.dart'; // ✅ NEW
import '../services/firebase_auth_service.dart'; // ✅ NEW
import '../utils/logger.dart'; // ✅ NEW
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _taskService = TaskService(); // ✅ NEW
  final _authService = FirebaseAuthService(); // ✅ NEW

  String _searchQuery = '';
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String _sortBy = 'deadline'; // deadline, priority, title

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
        title: const Text('Filter & Sort'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterStatus == null,
                      onSelected: (selected) {
                        setDialogState(() => _filterStatus = null);
                      },
                    ),
                    ...TaskStatus.values.map((status) => FilterChip(
                          label: Text(TaskHelper.getStatusText(status)),
                          selected: _filterStatus == status,
                          selectedColor: TaskHelper.getStatusColor(status)
                              .withOpacity(0.2),
                          onSelected: (selected) {
                            setDialogState(
                                () => _filterStatus = selected ? status : null);
                          },
                        )),
                  ],
                ),

                const SizedBox(height: 16),

                // Priority Filter
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterPriority == null,
                      onSelected: (selected) {
                        setDialogState(() => _filterPriority = null);
                      },
                    ),
                    ...TaskPriority.values.map((priority) => FilterChip(
                          label: Text(TaskHelper.getPriorityText(priority)),
                          selected: _filterPriority == priority,
                          selectedColor: TaskHelper.getPriorityColor(priority)
                              .withOpacity(0.2),
                          onSelected: (selected) {
                            setDialogState(() =>
                                _filterPriority = selected ? priority : null);
                          },
                        )),
                  ],
                ),

                const SizedBox(height: 16),

                // Sort By
                const Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Deadline'),
                      selected: _sortBy == 'deadline',
                      onSelected: (selected) {
                        setDialogState(() => _sortBy = 'deadline');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Priority'),
                      selected: _sortBy == 'priority',
                      onSelected: (selected) {
                        setDialogState(() => _sortBy = 'priority');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Title'),
                      selected: _sortBy == 'title',
                      onSelected: (selected) {
                        setDialogState(() => _sortBy = 'title');
                      },
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
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B68EE),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Tasks',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_filterStatus != null || _filterPriority != null)
                  ? const Color(0xFF7B68EE)
                  : Colors.black,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by title, description, or project...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7B68EE)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _performSearch,
            ),
          ),

          // ✅ Active Filters Display
          if (_filterStatus != null || _filterPriority != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
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
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _filterStatus = null);
                      },
                      backgroundColor: TaskHelper.getStatusColor(_filterStatus!)
                          .withOpacity(0.1),
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
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _filterPriority = null);
                      },
                      backgroundColor:
                          TaskHelper.getPriorityColor(_filterPriority!)
                              .withOpacity(0.1),
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
                        Text(
                          'Error loading tasks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];
                final filteredTasks = _filterAndSortTasks(allTasks);

                // Results count
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
                        style: TextStyle(
                          color: Colors.grey[600],
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
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Start typing to search tasks'
                                        : 'No tasks found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try different keywords or filters',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                      color: const Color(0xFF1A1A2E),
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
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        TaskHelper.getStatusColor(task.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    TaskHelper.getStatusText(task.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: TaskHelper.getStatusColor(task.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              task.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Bottom Row: Project, Priority, Deadline
            Row(
              children: [
                // Project
                Icon(Icons.folder_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  task.projectName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(width: 16),

                // Priority
                Icon(
                  Icons.flag,
                  size: 14,
                  color: TaskHelper.getPriorityColor(task.priority),
                ),
                const SizedBox(width: 4),
                Text(
                  TaskHelper.getPriorityText(task.priority),
                  style: TextStyle(
                    fontSize: 12,
                    color: TaskHelper.getPriorityColor(task.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                // Deadline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isOverdue ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverdue
                            ? 'Overdue'
                            : daysUntil == 0
                                ? 'Today'
                                : '${daysUntil}d',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
