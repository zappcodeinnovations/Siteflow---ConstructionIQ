import 'dart:async';
import 'dart:convert';

import 'package:euroside/modules/all_projects/controller/all_project_state.dart';
import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/services/all_project_service.dart';
import 'package:euroside/services/local_project_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllProjectController extends StateNotifier<AllProjectState> {
  AllProjectController() : super(AllProjectState());

  Timer? _messageTimer;

  /// AUTO CLEAR MESSAGE
  void _scheduleClearMessages() {
    _messageTimer?.cancel();

    _messageTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(error: null, successMessage: null);
    });
  }

  /// SET ERROR
  void _setError(String message) {
    state = state.copyWith(
      isLoading: false,
      isSubmitting: false,
      error: message,
      successMessage: null,
    );

    _scheduleClearMessages();
  }

  /// CLEAR MESSAGE MANUALLY
  void clearMessages() {
    _messageTimer?.cancel();

    state = state.copyWith(error: null, successMessage: null);
  }

  Future<void> fetchProjects({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && state.projects.isNotEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await AllProjectService.getProjects();

      debugPrint("🔥 RESPONSE: $response");
      try {
        debugPrint("🔥 JSON RESPONSE: ${jsonEncode(response)}");
      } catch (_) {}

      final List data = response["data"] ?? response["projects"] ?? response["results"] ?? [];

      final projectModels = data.map((e) {
        final projectData = e is Map<String, dynamic> && e.containsKey('project') && e['project'] != null
            ? e['project'] as Map<String, dynamic>
            : e as Map<String, dynamic>;
        return AllprojectModel.fromJson(projectData);
      }).toList();

      final localProjects = await LocalProjectService.getLocalProjects();
      
      final allProjects = [...localProjects, ...projectModels];

      print("✅ PROJECT COUNT: ${allProjects.length}");

      state = state.copyWith(isLoading: false, projects: allProjects);
    } catch (e) {
      debugPrint("❌ FETCH ERROR: $e");

      _setError(_handleError(e));
    }
  }

  /// FETCH PROJECT DETAILS
  Future<void> fetchProjectDetails(int projectId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await AllProjectService.getProjectDetails(projectId);

      final project = AllprojectModel.fromJson(response["data"]);

      state = state.copyWith(isLoading: false, selectedProject: project);
    } catch (e) {
      _setError(_handleError(e));
    }
  }

  /// ADD LOCAL PROJECT
  Future<void> addLocalProject(AllprojectModel project) async {
    await LocalProjectService.saveLocalProject(project);
    final updatedProjects = [project, ...state.projects];
    state = state.copyWith(projects: updatedProjects);
  }

  /// HANDLE ERROR
  String _handleError(dynamic e) {
    return e.toString().replaceAll("Exception:", "").trim();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}
