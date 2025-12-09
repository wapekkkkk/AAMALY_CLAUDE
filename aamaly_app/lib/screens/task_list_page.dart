// ============================================
// FILE: lib/screens/task_list_page.dart
// ============================================

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../data/mock_data.dart';
import '../utils/task_helper.dart';
import '../widgets/task_card.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'create_task_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String _sortBy = 'deadline'; // deadline, priority, status

  @override
  void initState() {
    super.initState();
    _allTasks = MockData.getTasks();
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        bool matchesStatus =
            _filterStatus == null || task.status == _filterStatus;

        // Priority filter
        bool matchesPriority =
            _filterPriority == null || task.priority == _filterPriority;

        return matchesSearch && matchesStatus && matchesPriority;
      }).toList();

      // Sort
      switch (_sortBy) {
        case 'deadline':
          _filteredTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
          break;
        case 'priority':
          _filteredTasks
              .sort((a, b) => b.priority.index.compareTo(a.priority.index));
          break;
        case 'status':
          _filteredTasks
              .sort((a, b) => a.status.index.compareTo(b.status.index));
          break;
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort Tasks'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                        onSelected: (selected) {
                          setDialogState(
                              () => _filterStatus = selected ? status : null);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Priority',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                        onSelected: (selected) {
                          setDialogState(() =>
                              _filterPriority = selected ? priority : null);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                  DropdownMenuItem(value: 'priority', child: Text('Priority')),
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _sortBy = value);
                  }
                },
              ),
            ],
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
              _applyFiltersAndSort();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFiltersAndSort();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
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
                await AuthService().logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFiltersAndSort();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFiltersAndSort();
              },
            ),
          ),

          // Active Filters Display
          if (_filterStatus != null || _filterPriority != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterStatus != null)
                    Chip(
                      label: Text(
                          'Status: ${TaskHelper.getStatusText(_filterStatus!)}'),
                      onDeleted: () {
                        setState(() => _filterStatus = null);
                        _applyFiltersAndSort();
                      },
                    ),
                  if (_filterPriority != null)
                    Chip(
                      label: Text(
                          'Priority: ${TaskHelper.getPriorityText(_filterPriority!)}'),
                      onDeleted: () {
                        setState(() => _filterPriority = null);
                        _applyFiltersAndSort();
                      },
                    ),
                ],
              ),
            ),

          // Task Count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredTasks.length} task(s) found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
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
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onDelete: () {
                          setState(() {
                            _allTasks.removeWhere((t) => t.id == task.id);
                          });
                          _applyFiltersAndSort();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create task page
          final newTask = await Navigator.push<Task>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTaskPage(),
            ),
          );

          // If task was created, add it to the list
          if (newTask != null) {
            setState(() {
              _allTasks.insert(0, newTask);
            });
            _applyFiltersAndSort();
          }
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
    );
  }
}
