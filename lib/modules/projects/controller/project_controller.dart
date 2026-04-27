import 'package:euro_side/services/projects_services.dart';
import 'package:flutter/material.dart';
import '../model/project_model.dart';

class ProjectController {
  Future<List<ProjectModel>> fetchProjects() async {
    try {
      final response = await ProjectService.getProjects();

      final List list = response["projects"];

      List<ProjectModel> projects = list.map((item) {
        return ProjectModel.fromJson(item["project"]);
      }).toList();

      return projects;
    } catch (e) {
      debugPrint("❌ CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}