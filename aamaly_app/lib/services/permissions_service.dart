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
    String? taskCreatorId, // ✅ ADD THIS (optional)
  }) {
    // ✅ NEW RULE: If task is UNASSIGNED, anyone can mark as done
    if (task.assignedToUserId == null || task.assignedToUserId!.isEmpty) {
      return userId == userId;
    }

    // For ASSIGNED tasks:

    // 1. Owner can mark any task as done
    if (userId == projectOwnerId) return true;

    // 2. Task creator can mark as done (if tracked)
    if (taskCreatorId != null && userId == taskCreatorId) return true;

    // 3. Assigned user can mark as done
    if (task.assignedToUserId == userId) return true;

    // 4. Other collaborators CANNOT mark assigned tasks as done
    return false;
  }

  static bool canEditUnassignedTask({
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Owner can edit
    if (userId == projectOwnerId) return true;

    // Any collaborator can edit unassigned tasks
    if (projectCollaboratorIds.contains(userId)) return true;

    return false;
  }

  /// ✅ UPDATE: Modified canEditTask to handle unassigned tasks
  static bool canEditTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds, // ✅ ADD THIS PARAMETER
    String? taskCreatorId,
  }) {
    // ✅ NEW: If task is unassigned, anyone in project can edit
    if (task.assignedToUserId == null || task.assignedToUserId!.isEmpty) {
      return canEditUnassignedTask(
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      );
    }

    // 1. Owner can edit any task
    if (userId == projectOwnerId) return true;

    // 2. Task creator can edit
    if (taskCreatorId != null && userId == taskCreatorId) return true;

    // 3. Assigned user can edit
    if (task.assignedToUserId == userId) return true;

    // 4. Other collaborators CANNOT edit assigned tasks
    return false;
  }

  /// ✅ UPDATE: Modified canDeleteTask to handle unassigned tasks
  static bool canDeleteTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds, // ✅ ADD THIS PARAMETER
    String? taskCreatorId,
  }) {
    // ✅ NEW: If task is unassigned, anyone in project can delete
    if (task.assignedToUserId == null || task.assignedToUserId!.isEmpty) {
      return canEditUnassignedTask(
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      );
    }

    // 1. Owner can delete any task
    if (userId == projectOwnerId) return true;

    // 2. Task creator can delete
    if (taskCreatorId != null && userId == taskCreatorId) return true;

    // 3. Assigned user can delete
    if (task.assignedToUserId == userId) return true;

    // 4. Other collaborators CANNOT delete assigned tasks
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
