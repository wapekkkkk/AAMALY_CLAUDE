// ============================================
// FILE: lib/data/mock_projects.dart
// ============================================

import '../models/project.dart';

class MockProjects {
  static List<Project> getProjects() {
    return [
      Project(
        id: '1',
        name: 'TECHNO INFO 4303',
        code: 'INFO 4303',
        dateCreated: DateTime(2024, 10, 7),
        taskTypes: [],
        totalTasks: 5,
        completedTasks: 2,
        inProgressTasks: 3,
        ownerId: '1', // ADD THIS (current user)
        collaboratorIds: ['1', '2'],
      ),
      Project(
        id: '2',
        name: 'CONTROL AUDIT',
        code: 'INFO 4330',
        dateCreated: DateTime(2024, 9, 15),
        taskTypes: [],
        totalTasks: 3,
        completedTasks: 1,
        inProgressTasks: 2,
        ownerId: '1', // ADD THIS (current user)
        collaboratorIds: [],
      ),
      Project(
        id: '3',
        name: 'FINAL YEAR PROJECT',
        code: 'FYP',
        dateCreated: DateTime(2024, 9, 1),
        taskTypes: [],
        totalTasks: 8,
        completedTasks: 3,
        inProgressTasks: 5,
        ownerId: '1', // ADD THIS (current user)
        collaboratorIds: [],
      ),
    ];
  }
}
