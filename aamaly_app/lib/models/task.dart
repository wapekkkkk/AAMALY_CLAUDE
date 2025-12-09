// ============================================
// FILE: lib/models/task.dart
// ============================================

enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskStatus status;
  final TaskPriority priority;
  final String projectName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.projectName,
  });

  // Helper methods
  bool get isOverdue =>
      status != TaskStatus.completed && deadline.isBefore(DateTime.now());

  int get daysUntilDeadline => deadline.difference(DateTime.now()).inDays;
}
