// ============================================
// FILE: lib/widgets/task_card.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/task_helper.dart';
import '../screens/task/task_detail_page.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onDelete;

  const TaskCard({super.key, required this.task, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(task: task),
            ),
          );

          // If task was deleted, trigger callback
          if (result == 'delete' && onDelete != null) {
            onDelete!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TaskHelper.getPriorityColor(task.priority)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: TaskHelper.getPriorityColor(task.priority),
                      ),
                    ),
                    child: Text(
                      TaskHelper.getPriorityText(task.priority),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: TaskHelper.getPriorityColor(task.priority),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Project Name
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    task.projectName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status and Deadline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TaskHelper.getStatusColor(task.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.status == TaskStatus.completed
                              ? Icons.check_circle
                              : task.status == TaskStatus.inProgress
                                  ? Icons.pending
                                  : Icons.circle_outlined,
                          size: 16,
                          color: TaskHelper.getStatusColor(task.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          TaskHelper.getStatusText(task.status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: TaskHelper.getStatusColor(task.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(task.deadline),
                        style: TextStyle(
                          fontSize: 13,
                          color: isOverdue ? Colors.red : Colors.grey[700],
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Overdue warning
              if (isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue by ${task.daysUntilDeadline.abs()} day(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
