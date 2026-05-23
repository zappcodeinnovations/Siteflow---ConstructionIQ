import 'dart:async';

import 'package:euroside/modules/all_projects/controller/all_project_state.dart';
import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/services/all_project_service.dart';
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

      final List data = response["data"] ?? response["projects"] ?? response["results"] ?? [];

      final projectModels = data
          .map((e) => AllprojectModel.fromJson(e))
          .toList();

      print("✅ PROJECT COUNT: ${projectModels.length}");

      state = state.copyWith(isLoading: false, projects: projectModels);
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
