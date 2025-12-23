// ============================================
// FILE: lib/services/permissions_service.dart
// PERMISSION MATRIX IMPLEMENTATION
// ============================================

import '../models/task.dart';

class PermissionsService {
  /// Check if user can VIEW task
  /// Everyone can view tasks in projects they're part of
  static bool canViewTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Project owner can always view
    if (userId == projectOwnerId) return true;

    // Assigned person can view
    if (task.assignedToUserId == userId) return true;

    // Team members can view
    if (projectCollaboratorIds.contains(userId)) return true;

    return false;
  }

  /// Check if user can VIEW task details
  /// Same as viewing task
  static bool canViewDetails({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    return canViewTask(
      task: task,
      userId: userId,
      projectOwnerId: projectOwnerId,
      projectCollaboratorIds: projectCollaboratorIds,
    );
  }

  /// Check if user can VIEW task files
  /// Everyone in project can view files
  static bool canViewFiles({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Project owner can view
    if (userId == projectOwnerId) return true;

    // Assigned person can view
    if (task.assignedToUserId == userId) return true;

    // Team members can view
    if (projectCollaboratorIds.contains(userId)) return true;

    return false;
  }

  /// Check if user can DOWNLOAD task files
  /// Everyone in project can download files
  static bool canDownloadFiles({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    // Project owner can download
    if (userId == projectOwnerId) return true;

    // Assigned person can download
    if (task.assignedToUserId == userId) return true;

    // Team members can download
    if (projectCollaboratorIds.contains(userId)) return true;

    return false;
  }

  /// Check if user can EDIT task
  /// Only project owner and assigned person can edit
  static bool canEditTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds, // ✅ ADD THIS PARAMETER
  }) {
    // Project owner can always mark as done
    if (userId == projectOwnerId) return true;

    // Assigned person can mark as done
    if (task.assignedToUserId == userId) return true;

    // ✅ NEW: If task is UNASSIGNED, any project member can mark it as done
    if (task.assignedToUserId == null) {
      // Check if user is a collaborator in this project
      if (projectCollaboratorIds.contains(userId)) {
        return true;
      }
    }

    // Team members CANNOT mark as done (unless task is unassigned)
    return false;
  }

  /// Check if user can UPLOAD files to task
  /// Only project owner and assigned person can upload
  static bool canUploadFiles({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds, // ✅ ADD THIS PARAMETER
  }) {
    // Project owner can always mark as done
    if (userId == projectOwnerId) return true;

    // Assigned person can mark as done
    if (task.assignedToUserId == userId) return true;

    // ✅ NEW: If task is UNASSIGNED, any project member can mark it as done
    if (task.assignedToUserId == null) {
      // Check if user is a collaborator in this project
      if (projectCollaboratorIds.contains(userId)) {
        return true;
      }
    }

    // Team members CANNOT mark as done (unless task is unassigned)
    return false;
  }

  /// Check if user can DELETE files from task
  /// Owner can delete any file, assigned person can delete only their own files
  static bool canDeleteFile({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required String fileOwnerId,
  }) {
    // Project owner can delete any file
    if (userId == projectOwnerId) return true;

    // Assigned person can delete ONLY their own files
    if (task.assignedToUserId == userId && userId == fileOwnerId) {
      return true;
    }

    // Team members CANNOT delete files
    return false;
  }

  /// Check if user can MARK task as done
  /// Only project owner and assigned person can mark as done
  static bool canMarkAsDone({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds, // ✅ ADD THIS PARAMETER
  }) {
    // Project owner can always mark as done
    if (userId == projectOwnerId) return true;

    // Assigned person can mark as done
    if (task.assignedToUserId == userId) return true;

    // ✅ NEW: If task is UNASSIGNED, any project member can mark it as done
    if (task.assignedToUserId == null) {
      // Check if user is a collaborator in this project
      if (projectCollaboratorIds.contains(userId)) {
        return true;
      }
    }

    // Team members CANNOT mark as done (unless task is unassigned)
    return false;
  }

  /// Check if user can DELETE task
  /// Only project owner can delete tasks
  static bool canDeleteTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
  }) {
    // Only project owner can delete
    return userId == projectOwnerId;
  }

  /// Check if user can REASSIGN task
  /// Only project owner can reassign tasks
  static bool canReassignTask({
    required Task task,
    required String userId,
    required String projectOwnerId,
  }) {
    // Only project owner can reassign
    return userId == projectOwnerId;
  }

  /// Get user role in project
  /// Returns: 'owner', 'assigned', 'team_member', or 'none'
  static String getUserRole({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    if (userId == projectOwnerId) {
      return 'owner';
    }

    if (task.assignedToUserId == userId) {
      return 'assigned';
    }

    if (projectCollaboratorIds.contains(userId)) {
      return 'team_member';
    }

    return 'none';
  }

  /// Check if user has ANY access to task
  static bool hasAnyAccess({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
  }) {
    return getUserRole(
          task: task,
          userId: userId,
          projectOwnerId: projectOwnerId,
          projectCollaboratorIds: projectCollaboratorIds,
        ) !=
        'none';
  }

  /// Get permission summary for debugging
  static Map<String, bool> getPermissionSummary({
    required Task task,
    required String userId,
    required String projectOwnerId,
    required List<String> projectCollaboratorIds,
    String? fileOwnerId,
  }) {
    return {
      'canView': canViewTask(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canViewDetails': canViewDetails(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canViewFiles': canViewFiles(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canDownloadFiles': canDownloadFiles(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canEdit': canEditTask(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canUploadFiles': canUploadFiles(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canDeleteFile': fileOwnerId != null
          ? canDeleteFile(
              task: task,
              userId: userId,
              projectOwnerId: projectOwnerId,
              fileOwnerId: fileOwnerId,
            )
          : false,
      'canMarkAsDone': canMarkAsDone(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
        projectCollaboratorIds: projectCollaboratorIds,
      ),
      'canDelete': canDeleteTask(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
      ),
      'canReassign': canReassignTask(
        task: task,
        userId: userId,
        projectOwnerId: projectOwnerId,
      ),
    };
  }
}
