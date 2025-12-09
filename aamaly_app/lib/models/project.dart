// ============================================
// FILE: lib/models/project.dart (UPDATED)
// ============================================

import 'task.dart';
import 'package:flutter/material.dart';

class Project {
  final String id;
  final String name;
  final String code;
  final DateTime dateCreated;
  final List<String> taskTypes;
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final Color color; // NEW: Project color
  final String description; // NEW: Project description

  Project({
    required this.id,
    required this.name,
    required this.code,
    required this.dateCreated,
    required this.taskTypes,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    this.color = const Color(0xFF7B68EE), // Default purple
    this.description = '',
  });

  int get todoTasks => totalTasks - completedTasks - inProgressTasks;

  Project copyWith({
    String? id,
    String? name,
    String? code,
    DateTime? dateCreated,
    List<String>? taskTypes,
    int? totalTasks,
    int? completedTasks,
    int? inProgressTasks,
    Color? color,
    String? description,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      dateCreated: dateCreated ?? this.dateCreated,
      taskTypes: taskTypes ?? this.taskTypes,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
