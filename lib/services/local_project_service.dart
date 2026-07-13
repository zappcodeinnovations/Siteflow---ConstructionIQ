import 'dart:convert';
import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalProjectService {
  static const String _storageKey = 'local_projects';

  static Future<List<AllprojectModel>> getLocalProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? projectsJson = prefs.getString(_storageKey);

    if (projectsJson == null || projectsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(projectsJson);
      return decoded.map((e) => AllprojectModel.fromJson(e)).toList();
    } catch (e) {
      print("Error decoding local projects: $e");
      return [];
    }
  }

  static Future<void> saveLocalProject(AllprojectModel project) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AllprojectModel> currentProjects = await getLocalProjects();

    currentProjects.add(project);

    final List<Map<String, dynamic>> jsonList = currentProjects.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  static Future<void> clearLocalProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
