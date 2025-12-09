// ============================================
// FILE: lib/data/mock_data.dart
// ============================================

import '../models/task.dart';

class MockData {
  static List<Task> getTasks() {
    return [
      Task(
        id: '1',
        title: 'Complete FYP Chapter 3',
        description:
            'Finish writing the methodology chapter for the final year project',
        deadline: DateTime.now().add(const Duration(days: 3)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        projectName: 'Final Year Project',
      ),
      Task(
        id: '2',
        title: 'Database Design Review',
        description: 'Review and finalize the database schema',
        deadline: DateTime.now().add(const Duration(days: 7)),
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        projectName: 'Final Year Project',
      ),
      Task(
        id: '3',
        title: 'Prepare Presentation Slides',
        description: 'Create slides for the mid-semester presentation',
        deadline: DateTime.now().add(const Duration(days: 5)),
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        projectName: 'INFO 4401',
      ),
      Task(
        id: '4',
        title: 'Flutter UI Implementation',
        description: 'Implement the task listing page UI',
        deadline: DateTime.now().add(const Duration(days: 2)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        projectName: 'Final Year Project',
      ),
      Task(
        id: '5',
        title: 'Literature Review Update',
        description: 'Add new references to chapter 2',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        projectName: 'Final Year Project',
      ),
      Task(
        id: '6',
        title: 'Team Meeting Minutes',
        description: 'Document the weekly team meeting',
        deadline: DateTime.now().add(const Duration(days: 1)),
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        projectName: 'Group Project',
      ),
    ];
  }
}
