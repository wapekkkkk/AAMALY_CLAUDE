// ============================================
// FILE: lib/screens/project_detail_page.dart (DARK THEME + LIVE PROJECT COLOR)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/push_notification_service.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/friend_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/permissions_service.dart';
import '../models/user.dart' as app_user;
import '../services/task_service.dart';
import '../services/project_service.dart';
import '../widgets/edit_project_bottom_sheet.dart';
import 'task_detail_page.dart';
import 'create_task_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final TaskService _taskService = TaskService();
  final ProjectService _projectService = ProjectService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FriendService _friendService = FriendService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // ✅ IMPORTANT: keep a local project so UI updates after edit / firestore changes
  late Project _project;

  // Dark theme colors
  static const Color _bg = Color(0xFF0E141B);
  static const Color _surface = Color(0xFF121A23);
  static const Color _surface2 = Color(0xFF0F1720);
  static const Color _border = Color(0xFF1F2A37);
  static const Color _text = Color(0xFFEAF0F7);
  static const Color _muted = Color(0xFF9AA6B2);

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  Future<void> _notifyAllCollaborators() async {
    final currentUserId = _authService.currentUserId ?? '';

    // Check if user is owner
    if (_project.ownerId != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only project owner can send notifications'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Get all tasks in this project
      final tasks = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: _project.id)
          .get();

      print('🔍 Total tasks in project: ${tasks.docs.length}'); // ✅ DEBUG

      // Find users with incomplete tasks
      final Map<String, int> userTaskCounts = {};

      for (var taskDoc in tasks.docs) {
        final taskData = taskDoc.data();
        final status = taskData['status'] as String?;
        final assignedTo = taskData['assignedToUserId'] as String?;

        print(
            '🔍 Task: ${taskData['title']} | Status: $status | Assigned: $assignedTo'); // ✅ DEBUG

        // Only count incomplete tasks
        if (assignedTo != null &&
            assignedTo.isNotEmpty &&
            status != 'completed') {
          userTaskCounts[assignedTo] = (userTaskCounts[assignedTo] ?? 0) + 1;
          print('✅ Counted task for user: $assignedTo'); // ✅ DEBUG
        }
      }

      print('🔍 Users with pending tasks: $userTaskCounts'); // ✅ DEBUG

      if (userTaskCounts.isEmpty) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No pending tasks to notify about!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Send notifications to each user with pending tasks
      int notificationsSent = 0;

      for (var entry in userTaskCounts.entries) {
        final userId = entry.key;
        final taskCount = entry.value;

        print(
            '🔍 Trying to notify user: $userId with $taskCount tasks'); // ✅ DEBUG

        try {
          // Get user's FCM token
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data();
          final fcmToken = userData?['fcmToken'] as String?;
          final userName = userData?['name'] as String? ?? 'User';

          print(
              '🔍 User: $userName | FCM Token: ${fcmToken != null ? "Found" : "Missing"}'); // ✅ DEBUG

          if (fcmToken != null && fcmToken.isNotEmpty) {
            // ✅ IMPORTANT: This only sends LOCAL notification, not to other devices!
            await PushNotificationService().sendCustomNotification(
              fcmToken: fcmToken,
              title: '${_project.name} - Pending Tasks',
              body:
                  'You have $taskCount pending task${taskCount > 1 ? 's' : ''} to complete!',
            );

            print('✅ Notification sent to $userName'); // ✅ DEBUG
            notificationsSent++;
          } else {
            print('❌ No FCM token for $userName'); // ✅ DEBUG
          }
        } catch (e) {
          print('❌ Failed to notify user $userId: $e'); // ✅ DEBUG
        }
      }

      print('🎉 Total notifications sent: $notificationsSent'); // ✅ DEBUG

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationsSent > 0
                  ? 'Notified $notificationsSent collaborator${notificationsSent != 1 ? 's' : ''} about pending tasks!'
                  : 'No collaborators have FCM tokens registered!',
            ),
            backgroundColor:
                notificationsSent > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _notifyAllCollaborators: $e'); // ✅ DEBUG

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Convert Firestore value -> Color safely
  Color _parseColor(dynamic value, {Color fallback = const Color(0xFF2196F3)}) {
    try {
      if (value == null) return fallback;
      if (value is int) return Color(value);
      if (value is String) {
        // supports "#RRGGBB" or "0xFFRRGGBB"
        final cleaned = value.replaceAll('#', '').replaceAll('0x', '');
        if (cleaned.length == 6) {
          return Color(int.parse('FF$cleaned', radix: 16));
        }
        if (cleaned.length == 8) {
          return Color(int.parse(cleaned, radix: 16));
        }
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // ✅ listen to project doc so color/name/code updates live
      stream: _firestore.collection('projects').doc(_project.id).snapshots(),
      builder: (context, snapshot) {
        // Keep stats defaults from current object
        int totalTasks = _project.totalTasks;
        int completedTasks = _project.completedTasks;
        int inProgressTasks = _project.inProgressTasks;

        // ✅ if firestore has new data, update local project fields
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          totalTasks = (data['totalTasks'] ?? totalTasks) as int;
          completedTasks = (data['completedTasks'] ?? completedTasks) as int;
          inProgressTasks = (data['inProgressTasks'] ?? inProgressTasks) as int;

          final newName = (data['name'] ?? _project.name) as String;
          final newCode = (data['code'] ?? _project.code) as String;
          final newDesc =
              (data['description'] ?? _project.description) as String;
          final newOwnerId = (data['ownerId'] ?? _project.ownerId) as String;

          final newColor = _parseColor(data['color'], fallback: _project.color);

          final newCollaborators = (data['collaboratorIds'] is List)
              ? List<String>.from(data['collaboratorIds'])
              : _project.collaboratorIds;

          // ✅ update local project only if changed
          final shouldUpdate = newName != _project.name ||
              newCode != _project.code ||
              newDesc != _project.description ||
              newOwnerId != _project.ownerId ||
              newColor.value != _project.color.value ||
              newCollaborators.length != _project.collaboratorIds.length;

          if (shouldUpdate) {
            _project = _project.copyWith(
              name: newName,
              code: newCode,
              description: newDesc,
              ownerId: newOwnerId,
              color: newColor,
              collaboratorIds: newCollaborators,
              totalTasks: totalTasks,
              completedTasks: completedTasks,
              inProgressTasks: inProgressTasks,
              // dateCreated + taskTypes stay the same automatically
            );
          }
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false, // ✅ title a bit left
            titleSpacing: 0, // ✅ closer to back button
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),

            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _project.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ prevents overflow by shrinking text
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Project Details',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            actions: [
              // ✅ Bell (owner only)
              if (_authService.currentUserId == _project.ownerId)
                IconButton(
                  icon: const Icon(Icons.notifications_active, size: 22),
                  onPressed: _notifyAllCollaborators,
                  tooltip: 'Notify All Collaborators',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                ),

              // ✅ Team icon (compact, close to bell)
              IconButton(
                icon: const Icon(Icons.group, size: 22),
                onPressed: _showCollaboratorsDialog,
                tooltip: 'Manage Collaborators',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
              ),

              // ✅ Menu icon compact too
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 22),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditProjectDialog();
                    } else if (value == 'delete') {
                      _showDeleteProjectDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Edit Project'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete Project',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6), // tiny right padding
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Color-coded header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _project.color,
                      _project.color.withOpacity(0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.folder,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _project.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.22)),
                                ),
                                child: Text(
                                  _project.code,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(Icons.assignment_outlined,
                                totalTasks.toString(), 'Total')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(Icons.check_circle_outline,
                                completedTasks.toString(), 'Done')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(Icons.pending_outlined,
                                inProgressTasks.toString(), 'In Progress')),
                      ],
                    ),
                  ],
                ),
              ),

              // Tasks header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTaskPage(
                              lockedProjectName: _project.name,
                              lockedProjectCode: _project.code,
                              project: _project,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _project.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              // Task list
              Expanded(
                child: StreamBuilder<List<Task>>(
                  stream: _taskService.getProjectTasks(_project.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            const Text('Error loading tasks',
                                style: TextStyle(fontSize: 18, color: _muted)),
                          ],
                        ),
                      );
                    }

                    final tasks = snapshot.data ?? [];

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined,
                                size: 64, color: Colors.white30),
                            const SizedBox(height: 16),
                            const Text('No tasks yet',
                                style: TextStyle(fontSize: 18, color: _text)),
                            const SizedBox(height: 8),
                            const Text('Create your first task to get started!',
                                style: TextStyle(fontSize: 14, color: _muted)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _buildTaskCard(tasks[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == TaskStatus.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;

    final currentUserId = _authService.currentUserId ?? '';

    // ✅ status colors (inProgress uses project color)
    Color statusColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = Colors.green;
        statusLabel = 'Completed';
        break;
      case TaskStatus.inProgress:
        statusColor = _project.color;
        statusLabel = 'In Progress';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'To Do';
    }

    return FutureBuilder<String?>(
      future: _getTaskCreator(task.id),
      builder: (context, creatorSnapshot) {
        final taskCreatorId = creatorSnapshot.data;

        final canMarkDone = PermissionsService.canMarkAsDone(
          task: task,
          userId: currentUserId,
          projectOwnerId: _project.ownerId,
          projectCollaboratorIds: _project.collaboratorIds,
          taskCreatorId: taskCreatorId,
        );

        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TaskDetailPage(task: task)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _project.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _project.color.withOpacity(0.25)),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.assignment_outlined,
                        color: _project.color,
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
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isCompleted ? Colors.white38 : _text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due ${DateFormat('MMM d, yyyy').format(task.deadline)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: daysUntil < 0 ? Colors.red[300] : _muted,
                              fontWeight: daysUntil < 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white24),
                  ],
                ),

                const SizedBox(height: 12),

                // Assignee display (theme + project color)
                if (task.assignedToUserId != null)
                  FutureBuilder<app_user.User?>(
                    future: _getAssignedUser(task.assignedToUserId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null)
                        return const SizedBox.shrink();
                      final assignee = snapshot.data!;
                      final isAssignedToMe =
                          assignee.id == (_authService.currentUserId);

                      final accent =
                          isAssignedToMe ? _project.color : Colors.white24;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isAssignedToMe
                                  ? _project.color.withOpacity(0.55)
                                  : _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isAssignedToMe
                                  ? _project.color
                                  : Colors.white24,
                              child: Text(
                                assignee.initials,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.person, size: 14, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              isAssignedToMe
                                  ? 'Assigned to You'
                                  : 'Assigned to ${assignee.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAssignedToMe ? _project.color : _muted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: statusColor.withOpacity(0.30)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityBadge(task.priority),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ NEW: Show badge based on assignment status
                    if (task.assignedToUserId != null &&
                        task.assignedToUserId!.isNotEmpty) ...[
                      // Task is assigned to someone
                      if (!canMarkDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.visibility,
                                  size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                'View only',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      // ✅ Task is UNASSIGNED - show "Available for all"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.people, size: 14, color: Colors.blue),
                            SizedBox(width: 6),
                            Text(
                              'Available for all',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // ✅ Button - only enabled if canMarkDone is true
                    OutlinedButton(
                      onPressed: canMarkDone
                          ? () => _toggleTaskCompletion(task)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isCompleted ? Colors.orange : Colors.green,
                        side: BorderSide(
                          color: isCompleted ? Colors.orange : Colors.green,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        disabledForegroundColor: Colors.white24,
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        isCompleted ? 'Mark as In Progress' : 'Mark as Done',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ); // ✅ Closing FutureBuilder
  } // ✅ Closing _buildTaskCard method

  Future<void> _toggleTaskCompletion(Task task) async {
    final currentUserId = _authService.currentUserId ?? '';

    final canMarkDone = PermissionsService.canMarkAsDone(
      task: task,
      userId: currentUserId,
      projectOwnerId: _project.ownerId,
      projectCollaboratorIds: _project.collaboratorIds,
    );

    if (!canMarkDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('You don\'t have permission to change this task status'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      if (task.status == TaskStatus.completed) {
        await TaskService().markAsInProgress(task.id);
      } else {
        await TaskService().markAsComplete(task.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(task.status == TaskStatus.completed
              ? 'Task marked as in progress!'
              : 'Task marked as done!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    String label;

    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showEditProjectDialog() async {
    final updatedProject = await showModalBottomSheet<Project>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => EditProjectBottomSheet(project: _project),
        ),
      ),
    );

    // ✅ update local immediately (Firestore stream will also update)
    if (updatedProject != null && mounted) {
      setState(() => _project = updatedProject);
    }
  }

  void _showDeleteProjectDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Delete Project', style: TextStyle(color: _text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${_project.name}"?',
                style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[300], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all tasks in this project!',
                      style: TextStyle(
                          color: Colors.red[200],
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await ProjectService().deleteProject(_project.id);

        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Project deleted successfully!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete project: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Collaborators dialog
  void _showCollaboratorsDialog() async {
    try {
      final collaborators =
          await _projectService.getProjectCollaborators(_project.id);
      final currentUserId = _authService.currentUserId!;
      final friends = await _friendService.getFriendsWithDetails(currentUserId);

      final availableFriends = friends
          .where((friend) =>
              !_project.collaboratorIds.contains(friend.id) &&
              friend.id != _project.ownerId)
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _CollaboratorsDialog(
          project: _project, // ✅ use current color
          collaborators: collaborators,
          availableFriends: availableFriends,
          onInvite: _inviteToProject,
          onRemove: _removeFromProject,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _inviteToProject(String friendId) async {
    try {
      await _projectService.inviteToProject(
          projectId: _project.id, friendId: friendId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Friend invited to project!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        _showCollaboratorsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromProject(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title:
            const Text('Remove Collaborator', style: TextStyle(color: _text)),
        content: const Text(
            'Are you sure you want to remove this collaborator?',
            style: TextStyle(color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _projectService.removeFromProject(
          projectId: _project.id, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Collaborator removed'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        _showCollaboratorsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<app_user.User?> _getAssignedUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) return app_user.User.fromMap(doc.data()!, doc.id);
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<String?> _getTaskCreator(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      return doc.data()?['createdBy'] as String?;
    } catch (e) {
      return null;
    }
  }
}

// ============================================
// Collaborators Dialog (theme + project color)
// ============================================

class _CollaboratorsDialog extends StatefulWidget {
  final Project project;
  final List<app_user.User> collaborators;
  final List<app_user.User> availableFriends;
  final Function(String) onInvite;
  final Function(String) onRemove;

  const _CollaboratorsDialog({
    required this.project,
    required this.collaborators,
    required this.availableFriends,
    required this.onInvite,
    required this.onRemove,
  });

  @override
  State<_CollaboratorsDialog> createState() => _CollaboratorsDialogState();
}

class _CollaboratorsDialogState extends State<_CollaboratorsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _surface = Color(0xFF121A23);
  static const Color _surface2 = Color(0xFF0F1720);
  static const Color _border = Color(0xFF1F2A37);
  static const Color _text = Color(0xFFEAF0F7);
  static const Color _muted = Color(0xFF9AA6B2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _border)),
      child: Container(
        height: 520,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Collaborators',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _text)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _text),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              indicatorColor: widget.project.color,
              labelColor: widget.project.color,
              unselectedLabelColor: _muted,
              tabs: [
                Tab(text: 'Members (${widget.collaborators.length + 1})'),
                Tab(text: 'Invite (${widget.availableFriends.length})'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(),
                  _buildInviteTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    // ✅ FIX: Get current user ID
    final currentUserId = FirebaseAuthService().currentUserId ?? '';
    final isCurrentUserOwner = widget.project.ownerId == currentUserId;

    return ListView(
      children: [
        // ✅ FIX: Show actual owner, not always "You"
        FutureBuilder<app_user.User?>(
          future: _getOwnerUser(widget.project.ownerId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final owner = snapshot.data!;
            final isMe = owner.id == currentUserId;

            return _buildMemberCard(
              name: isMe ? 'You (Owner)' : owner.name,
              email: isMe ? '' : owner.email,
              isOwner: true,
              onRemove: null,
            );
          },
        ),

        // Show collaborators
        ...widget.collaborators.map(
          (c) => _buildMemberCard(
            name: c.id == currentUserId ? 'You' : c.name,
            email: c.id == currentUserId ? '' : c.email,
            isOwner: false,
            onRemove: () => widget.onRemove(c.id),
          ),
        ),

        if (widget.collaborators.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: const [
                Icon(Icons.people_outline, size: 48, color: Colors.white30),
                SizedBox(height: 12),
                Text('No collaborators yet', style: TextStyle(color: _muted)),
                SizedBox(height: 8),
                Text('Invite friends from the next tab',
                    style: TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
      ],
    );
  }

// ✅ ADD THIS HELPER METHOD in _CollaboratorsDialogState class
  Future<app_user.User?> _getOwnerUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return app_user.User.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting owner: $e');
    }
    return null;
  }

  Widget _buildMemberCard({
    required String name,
    required String email,
    required bool isOwner,
    VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isOwner ? Colors.orange : widget.project.color,
            child: Icon(isOwner ? Icons.star : Icons.person,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _text)),
                if (email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          if (!isOwner && onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    if (widget.availableFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_add_disabled, size: 48, color: Colors.white30),
            SizedBox(height: 12),
            Text('No friends to invite', style: TextStyle(color: _muted)),
            SizedBox(height: 8),
            Text('All your friends are already collaborators',
                style: TextStyle(fontSize: 12, color: _muted),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.availableFriends.length,
      itemBuilder: (context, index) =>
          _buildInviteCard(widget.availableFriends[index]),
    );
  }

  Widget _buildInviteCard(app_user.User friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: widget.project.color,
            child: Text(friend.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _text)),
                Text(friend.email,
                    style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => widget.onInvite(friend.id),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Invite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.project.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
