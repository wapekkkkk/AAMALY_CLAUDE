// ============================================
// FILE: lib/services/permissions_service.dart (UPDATED)
// Add canEditTask and canDeleteTask methods
// ============================================

import '../models/task.dart';

class PermissionsService {
  /// Check if user can mark task as done
  static bool canMarkAsDone({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Owner can mark any task as done
    if (userId == projectOwnerId) return true;

    // Task creator can mark as done
    if (task.assignedToUserId == userId) return true;

    // Assigned user can mark as done
    // (Note: If task has no assignedToUserId, only owner can mark done)

    return false;
  }

  /// ✅ NEW: Check if user can edit task
  static bool canEditTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    String? taskCreatorId, // If you have this field
  }) {
    // 1. Owner can edit any task
    if (userId == projectOwnerId) return true;

    // 2. Task creator can edit (if you track createdBy)
    if (taskCreatorId != null && userId == taskCreatorId) return true;

    // 3. Assigned user can edit
    if (task.assignedToUserId != null && task.assignedToUserId == userId) {
      return true;
    }

    // 4. Other collaborators CANNOT edit
    return false;
  }

  /// ✅ NEW: Check if user can delete task
  static bool canDeleteTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    String? taskCreatorId, // If you have this field
  }) {
    // 1. Owner can delete any task
    if (userId == projectOwnerId) return true;

    // 2. Task creator can delete (if you track createdBy)
    if (taskCreatorId != null && userId == taskCreatorId) return true;

    // 3. Assigned user can delete
    if (task.assignedToUserId != null && task.assignedToUserId == userId) {
      return true;
    }

    // 4. Other collaborators CANNOT delete
    return false;
  }

  /// ✅ NEW: Check if user can view task (everyone in project can view)
  static bool canViewTask({
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Owner can view
    if (userId == projectOwnerId) return true;

    // Collaborators can view
    if (projectCollaboratorIds.contains(userId)) return true;

    return false;
  }

  /// ✅ NEW: Get user role in task
  static String getUserTaskRole({
    required Task task,
    required String userId,
    required String projectOwnerId,
    String? taskCreatorId,
  }) {
    if (userId == projectOwnerId) return 'Owner';
    if (taskCreatorId != null && userId == taskCreatorId) return 'Creator';
    if (task.assignedToUserId == userId) return 'Assigned';
    return 'Viewer';
  }
}
