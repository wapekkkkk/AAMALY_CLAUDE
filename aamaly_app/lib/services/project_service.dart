// ============================================
// FILE: lib/services/project_service.dart
// REAL FIRESTORE PROJECT SERVICE
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE PROJECT
  Future<String> createProject({
    required String name,
    required String code,
    required String description,
    required String ownerId,
    required Color color,
    List<String> collaboratorIds = const [],
    List<String> taskTypes = const [],
  }) async {
    try {
      final docRef = await _firestore.collection('projects').add({
        'name': name,
        'code': code,
        'description': description,
        'ownerId': ownerId,
        'collaboratorIds': collaboratorIds,
        'color': color.value, // Store color as int
        'taskTypes': taskTypes,
        'dateCreated': FieldValue.serverTimestamp(),
        'totalTasks': 0,
        'completedTasks': 0,
        'inProgressTasks': 0,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // GET USER'S PROJECTS (Real-time stream)
  Stream<List<Project>> getUserProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: userId)
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Project(
          id: doc.id,
          name: data['name'] ?? '',
          code: data['code'] ?? '',
          description: data['description'] ?? '',
          ownerId: data['ownerId'] ?? '',
          collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
          color: Color(data['color'] ?? 0xFF2196F3),
          dateCreated:
              (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          taskTypes: List<String>.from(data['taskTypes'] ?? []),
          totalTasks: data['totalTasks'] ?? 0,
          completedTasks: data['completedTasks'] ?? 0,
          inProgressTasks: data['inProgressTasks'] ?? 0,
        );
      }).toList();
    });
  }

  // GET COLLABORATIVE PROJECTS (projects where user is a collaborator)
  Stream<List<Project>> getCollaborativeProjects(String userId) {
    return _firestore
        .collection('projects')
        .where('collaboratorIds', arrayContains: userId)
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Project(
          id: doc.id,
          name: data['name'] ?? '',
          code: data['code'] ?? '',
          description: data['description'] ?? '',
          ownerId: data['ownerId'] ?? '',
          collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
          color: Color(data['color'] ?? 0xFF2196F3),
          dateCreated:
              (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          taskTypes: List<String>.from(data['taskTypes'] ?? []),
          totalTasks: data['totalTasks'] ?? 0,
          completedTasks: data['completedTasks'] ?? 0,
          inProgressTasks: data['inProgressTasks'] ?? 0,
        );
      }).toList();
    });
  }

  // GET ALL USER PROJECTS (owned + collaborative)
  Stream<List<Project>> getAllUserProjects(String userId) {
    return _firestore.collection('projects').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final ownerId = data['ownerId'] ?? '';
        final collaboratorIds =
            List<String>.from(data['collaboratorIds'] ?? []);
        return ownerId == userId || collaboratorIds.contains(userId);
      }).map((doc) {
        final data = doc.data();
        return Project(
          id: doc.id,
          name: data['name'] ?? '',
          code: data['code'] ?? '',
          description: data['description'] ?? '',
          ownerId: data['ownerId'] ?? '',
          collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
          color: Color(data['color'] ?? 0xFF2196F3),
          dateCreated:
              (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          taskTypes: List<String>.from(data['taskTypes'] ?? []),
          totalTasks: data['totalTasks'] ?? 0,
          completedTasks: data['completedTasks'] ?? 0,
          inProgressTasks: data['inProgressTasks'] ?? 0,
        );
      }).toList();
    });
  }

  // GET PROJECT BY ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return Project(
        id: doc.id,
        name: data['name'] ?? '',
        code: data['code'] ?? '',
        description: data['description'] ?? '',
        ownerId: data['ownerId'] ?? '',
        collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
        color: Color(data['color'] ?? 0xFF2196F3),
        dateCreated:
            (data['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        taskTypes: List<String>.from(data['taskTypes'] ?? []),
        totalTasks: data['totalTasks'] ?? 0,
        completedTasks: data['completedTasks'] ?? 0,
        inProgressTasks: data['inProgressTasks'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  // UPDATE PROJECT
  Future<void> updateProject(
      String projectId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('projects').doc(projectId).update(updates);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // DELETE PROJECT
  Future<void> deleteProject(String projectId) async {
    try {
      // Delete all tasks in the project first
      final tasks = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final batch = _firestore.batch();
      for (var doc in tasks.docs) {
        batch.delete(doc.reference);
      }

      // Delete the project
      batch.delete(_firestore.collection('projects').doc(projectId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // ADD COLLABORATOR
  Future<void> addCollaborator(String projectId, String userId) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'collaboratorIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to add collaborator: $e');
    }
  }

  // REMOVE COLLABORATOR
  Future<void> removeCollaborator(String projectId, String userId) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'collaboratorIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to remove collaborator: $e');
    }
  }

  // UPDATE PROJECT STATS (called when tasks change)
  Future<void> updateProjectStats(String projectId) async {
    try {
      // Count tasks
      final tasks = await _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      int totalTasks = tasks.docs.length;
      int completedTasks =
          tasks.docs.where((doc) => doc.data()['status'] == 'completed').length;
      int inProgressTasks = tasks.docs
          .where((doc) => doc.data()['status'] == 'inProgress')
          .length;

      await _firestore.collection('projects').doc(projectId).update({
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'inProgressTasks': inProgressTasks,
      });
    } catch (e) {
      throw Exception('Failed to update project stats: $e');
    }
  }
}
