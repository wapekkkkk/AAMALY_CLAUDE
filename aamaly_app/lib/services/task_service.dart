// ============================================
// FILE: lib/services/task_service.dart (FIXED)
// REAL FIRESTORE TASK SERVICE
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';
import 'deadline_notification_scheduler.dart';
import '../models/task.dart';
import 'project_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProjectService _projectService = ProjectService();

  // CREATE TASK
  Future<String> createTask({
    required String title,
    required String description,
    required DateTime deadline,
    required String status,
    required String priority,
    required String projectName,
    required String createdBy,
    String? projectId,
    String? assignedToUserId,
  }) async {
    try {
      final docRef = await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'status': status,
        'priority': priority,
        'projectName': projectName,
        'projectId': projectId,
        'assignedToUserId': assignedToUserId,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update project stats if projectId exists
      if (projectId != null) {
        await _projectService.updateProjectStats(projectId); // ✅ Removed userId
      }

      // ✅ SCHEDULE DEADLINE NOTIFICATIONS (for all tasks)
      final task = Task(
        id: docRef.id,
        title: title,
        description: description,
        deadline: deadline,
        status: _stringToTaskStatus(status),
        priority: _stringToTaskPriority(priority),
        projectName: projectName,
        assignedToUserId: assignedToUserId,
      );
      await DeadlineNotificationScheduler()
          .scheduleTaskDeadlineNotifications(task);

      // ✅ SEND NOTIFICATIONS if task is assigned
      if (assignedToUserId != null && assignedToUserId.isNotEmpty) {
        final creatorDoc =
            await _firestore.collection('users').doc(createdBy).get();
        final creatorName = creatorDoc.data()?['name'] ?? 'Someone';

        // In-app notification
        await NotificationService().sendTaskAssignedNotification(
          toUserId: assignedToUserId,
          taskTitle: title,
          taskId: docRef.id,
          projectName: projectName,
          assignedByName: creatorName,
        );

        // Push notification
        await PushNotificationService().showTaskAssigned(title, creatorName);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // GET USER'S TASKS (all tasks created by user OR assigned to user)
  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('createdBy', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _taskFromFirestore(doc)).toList();
    });
  }

  // GET ASSIGNED TASKS (tasks assigned to specific user)
  Stream<List<Task>> getAssignedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _taskFromFirestore(doc)).toList();
    });
  }

  // GET ALL USER TASKS (created OR assigned)
  Stream<List<Task>> getAllUserTasks(String userId) {
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['createdBy'] == userId ||
                data['assignedToUserId'] == userId;
          })
          .map((doc) => _taskFromFirestore(doc))
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
    });
  }

  // ✅ GET MY TASKS (created by me OR assigned to me)
  // This is the recommended method for dashboard - clearer name than getAllUserTasks
  Stream<List<Task>> getMyTasks(String userId) async* {
    // Get user's projects first
    final userProjectsSnapshot = await _firestore
        .collection('projects')
        .where('collaboratorIds', arrayContains: userId)
        .get();

    final userProjectIds =
        userProjectsSnapshot.docs.map((doc) => doc.id).toList();

    // Also get projects where user is owner
    final ownedProjectsSnapshot = await _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: userId)
        .get();

    userProjectIds.addAll(ownedProjectsSnapshot.docs.map((doc) => doc.id));

    // Listen to tasks
    yield* _firestore.collection('tasks').snapshots().map((snapshot) {
      final myTasks = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final createdBy = data['createdBy'] as String?;
            final assignedTo = data['assignedToUserId'] as String?;
            final projectId = data['projectId'] as String?;

            // ✅ RULE 1: Show tasks ASSIGNED TO ME (regardless of who created it)
            if (assignedTo != null &&
                assignedTo.isNotEmpty &&
                assignedTo == userId) {
              return true;
            }

            // ✅ RULE 2: Show UNASSIGNED tasks in MY projects (available for anyone)
            if ((assignedTo == null || assignedTo.isEmpty) &&
                projectId != null &&
                userProjectIds.contains(projectId)) {
              return true;
            }

            // ❌ RULE 3: DON'T show tasks assigned to OTHER people
            // (Even if I created them)
            if (assignedTo != null &&
                assignedTo.isNotEmpty &&
                assignedTo != userId) {
              return false;
            }

            // ✅ RULE 4: Show tasks I CREATED that are NOT assigned to anyone else
            // (This covers unassigned tasks I created)
            if (createdBy == userId &&
                (assignedTo == null || assignedTo.isEmpty)) {
              return true;
            }

            return false;
          })
          .map((doc) => _taskFromFirestore(doc))
          .toList();

      // Sort by deadline (nearest first)
      myTasks.sort((a, b) => a.deadline.compareTo(b.deadline));

      return myTasks;
    });
  }

  // GET PROJECT TASKS
  Stream<List<Task>> getProjectTasks(String projectId) {
    return _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        // .orderBy('deadline', descending: false)  // ⚠️ Commented out temporarily
        .snapshots()
        .map((snapshot) {
      // Sort in memory instead
      final tasks =
          snapshot.docs.map((doc) => _taskFromFirestore(doc)).toList();
      tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      return tasks;
    });
  }

  // GET TASK BY ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (!doc.exists) return null;
      return _taskFromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  // UPDATE TASK
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('tasks').doc(taskId).update(updates);

      // If status changed, update project stats
      if (updates.containsKey('status')) {
        final task = await getTaskById(taskId);
        if (task != null && task.projectName.isNotEmpty) {
          // ✅ Find project by task's projectName
          final projectQuery = await _firestore
              .collection('projects')
              .where('code', isEqualTo: task.projectName)
              .limit(1)
              .get();

          if (projectQuery.docs.isNotEmpty) {
            await _projectService.updateProjectStats(
                projectQuery.docs.first.id); // ✅ Removed userId
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // DELETE TASK
  Future<void> deleteTask(String taskId) async {
    try {
      // ✅ Cancel deadline notifications first
      await DeadlineNotificationScheduler().cancelTaskNotifications(taskId);

      final task = await getTaskById(taskId);
      await _firestore.collection('tasks').doc(taskId).delete();

      // Update project stats
      if (task != null && task.projectName.isNotEmpty) {
        final projectQuery = await _firestore
            .collection('projects')
            .where('code', isEqualTo: task.projectName)
            .limit(1)
            .get();

        if (projectQuery.docs.isNotEmpty) {
          await _projectService.updateProjectStats(
              projectQuery.docs.first.id); // ✅ Removed userId
        }
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // MARK TASK AS COMPLETE
  Future<void> markAsComplete(String taskId) async {
    await updateTask(taskId, {'status': 'completed'});
    // ✅ Cancel deadline notifications when completed
    await DeadlineNotificationScheduler().cancelTaskNotifications(taskId);
  }

  // MARK TASK AS IN PROGRESS
  Future<void> markAsInProgress(String taskId) async {
    await updateTask(taskId, {'status': 'inProgress'});
  }

  // MARK TASK AS TODO
  Future<void> markAsTodo(String taskId) async {
    await updateTask(taskId, {'status': 'todo'});
  }

  // ASSIGN TASK TO USER
  Future<void> assignTask(String taskId, String userId) async {
    await updateTask(taskId, {'assignedToUserId': userId});
  }

  // UNASSIGN TASK
  Future<void> unassignTask(String taskId) async {
    await updateTask(taskId, {'assignedToUserId': null});
  }

  // Helper: Convert Firestore document to Task object
  Task _taskFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: _stringToTaskStatus(data['status']),
      priority: _stringToTaskPriority(data['priority']),
      projectName: data['projectName'] ?? 'No Project',
      assignedToUserId: data['assignedToUserId'],
    );
  }

  // Helper: Convert string to TaskStatus enum
  TaskStatus _stringToTaskStatus(String? status) {
    switch (status) {
      case 'completed':
        return TaskStatus.completed;
      case 'inProgress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.todo;
    }
  }

  // Helper: Convert string to TaskPriority enum
  TaskPriority _stringToTaskPriority(String? priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  // Helper: Convert TaskStatus enum to string
  static String taskStatusToString(TaskStatus status) {
    return status.toString().split('.').last;
  }

  // Helper: Convert TaskPriority enum to string
  static String taskPriorityToString(TaskPriority priority) {
    return priority.toString().split('.').last;
  }
}
