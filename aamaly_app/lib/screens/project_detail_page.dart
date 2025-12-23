// ============================================
// FILE: lib/screens/project_detail_page.dart (WITH COLLABORATORS)
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/friend_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/permissions_service.dart'; // ✅ NEW
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
  final _friendService = FriendService(); // ✅ ALREADY THERE
  final _authService = FirebaseAuthService(); // ✅ ADD THIS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.project.color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ✅ MANAGE COLLABORATORS BUTTON
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _showCollaboratorsDialog,
            tooltip: 'Manage Collaborators',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
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
                    Text('Delete Project', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: widget.project.color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Name Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.project.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stat Cards Row
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('projects')
                      .doc(widget.project.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int totalTasks = widget.project.totalTasks;
                    int completedTasks = widget.project.completedTasks;
                    int inProgressTasks = widget.project.inProgressTasks;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      totalTasks = data['totalTasks'] ?? 0;
                      completedTasks = data['completedTasks'] ?? 0;
                      inProgressTasks = data['inProgressTasks'] ?? 0;
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.assignment_outlined,
                            totalTasks.toString(),
                            'Total Tasks',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.check_circle_outline,
                            completedTasks.toString(),
                            'Completed',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.pending_outlined,
                            inProgressTasks.toString(),
                            'In Progress',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Tasks Section Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskPage(
                          lockedProjectName: widget.project.name,
                          lockedProjectCode: widget.project.code,
                          project: widget.project,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.project.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Task List
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.getProjectTasks(widget.project.id),
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
                        Text(
                          'Error loading tasks',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
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
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first task to get started!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == TaskStatus.completed;
    final daysUntil = task.deadline.difference(DateTime.now()).inDays;

    // ✅ GET CURRENT USER
    final currentUserId = _authService.currentUserId ?? '';

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

    // ✅ CHECK PERMISSION: Can this user mark task as done?
    final canMarkDone = PermissionsService.canMarkAsDone(
        task: task,
        userId: currentUserId,
        projectOwnerId: widget.project.ownerId,
        projectCollaboratorIds: widget.project.collaboratorIds);

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.project.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.status == TaskStatus.completed
                        ? Icons.check_circle
                        : Icons.assignment_outlined,
                    color: widget.project.color,
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
                          color: isCompleted
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

            // ✅ NEW: Assignee Display
            if (task.assignedToUserId != null)
              FutureBuilder<app_user.User?>(
                future: _getAssignedUser(task.assignedToUserId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final assignee = snapshot.data!;
                    final currentUserId = _authService.currentUserId;
                    final isAssignedToMe = assignee.id == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isAssignedToMe ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAssignedToMe
                              ? Colors.blue[200]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isAssignedToMe
                                ? const Color(0xFF2196F3)
                                : Colors.grey[600],
                            child: Text(
                              assignee.initials,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.person,
                            size: 14,
                            color: isAssignedToMe
                                ? Colors.blue[700]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAssignedToMe
                                ? 'Assigned to You'
                                : 'Assigned to ${assignee.name}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isAssignedToMe
                                  ? Colors.blue[700]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

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
                _buildPriorityBadge(task.priority),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ UPDATED: Mark as Done Button with Permission Check
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ Show permission indicator if user can't mark as done
                if (!canMarkDone)
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View only',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                // ✅ Button enabled/disabled based on permission
                OutlinedButton(
                  onPressed: canMarkDone
                      ? () => _toggleTaskCompletion(task)
                      : null, // ← null disables button
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCompleted ? Colors.orange : Colors.green,
                    side: BorderSide(
                      color: isCompleted ? Colors.orange : Colors.green,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // ✅ Gray out button if disabled
                    disabledForegroundColor: Colors.grey,
                    disabledBackgroundColor: Colors.grey[100],
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
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final currentUserId = _authService.currentUserId ?? '';

    // ✅ DOUBLE CHECK: Verify user has permission
    final canMarkDone = PermissionsService.canMarkAsDone(
        task: task,
        userId: currentUserId,
        projectOwnerId: widget.project.ownerId,
        projectCollaboratorIds: widget.project.collaboratorIds);

    if (!canMarkDone) {
      // ✅ Show error if no permission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You don\'t have permission to change this task status'),
          backgroundColor: Colors.red,
        ),
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
          content: Text(
            task.status == TaskStatus.completed
                ? 'Task marked as in progress!'
                : 'Task marked as done!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEditProjectDialog() async {
    final updatedProject = await showModalBottomSheet<Project>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) =>
              EditProjectBottomSheet(project: widget.project),
        ),
      ),
    );

    if (updatedProject != null) {
      setState(() {});
    }
  }

  void _showDeleteProjectDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${widget.project.name}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also delete all tasks in this project!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await ProjectService().deleteProject(widget.project.id);

        if (mounted) Navigator.pop(context);
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete project: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ✅ NEW: COLLABORATORS DIALOG METHODS
  void _showCollaboratorsDialog() async {
    try {
      final collaborators =
          await _projectService.getProjectCollaborators(widget.project.id);
      final currentUserId = _authService.currentUserId!;
      final friends = await _friendService.getFriendsWithDetails(currentUserId);

      final availableFriends = friends
          .where((friend) =>
              !widget.project.collaboratorIds.contains(friend.id) &&
              friend.id != widget.project.ownerId)
          .toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _CollaboratorsDialog(
          project: widget.project,
          collaborators: collaborators,
          availableFriends: availableFriends,
          onInvite: _inviteToProject,
          onRemove: _removeFromProject,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _inviteToProject(String friendId) async {
    try {
      await _projectService.inviteToProject(
        projectId: widget.project.id,
        friendId: friendId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend invited to project!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        _showCollaboratorsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromProject(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Collaborator'),
        content:
            const Text('Are you sure you want to remove this collaborator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        projectId: widget.project.id,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborator removed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        _showCollaboratorsDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Helper method to get assigned user info
  Future<app_user.User?> _getAssignedUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return app_user.User.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting assigned user: $e');
    }
    return null;
  }
}

// ✅ NEW: COLLABORATORS DIALOG WIDGET
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Collaborators',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2196F3),
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Members (${widget.collaborators.length + 1})'),
                Tab(text: 'Invite (${widget.availableFriends.length})'),
              ],
            ),
            const SizedBox(height: 16),
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
    return ListView(
      children: [
        _buildMemberCard(
          name: 'You (Owner)',
          email: '',
          isOwner: true,
          onRemove: null,
        ),
        ...widget.collaborators.map((collaborator) => _buildMemberCard(
              name: collaborator.name,
              email: collaborator.email,
              isOwner: false,
              onRemove: () => widget.onRemove(collaborator.id),
            )),
        if (widget.collaborators.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No collaborators yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends from the next tab',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
      ],
    );
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isOwner ? Colors.orange : const Color(0xFF2196F3),
            child: Icon(
              isOwner ? Icons.star : Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
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
          children: [
            Icon(Icons.person_add_disabled, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No friends to invite',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'All your friends are already collaborators',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.availableFriends.length,
      itemBuilder: (context, index) {
        final friend = widget.availableFriends[index];
        return _buildInviteCard(friend);
      },
    );
  }

  Widget _buildInviteCard(app_user.User friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2196F3),
            child: Text(
              friend.initials,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  friend.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => widget.onInvite(friend.id),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Invite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
