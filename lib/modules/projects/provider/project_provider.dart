import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/project_controller.dart';
import '../model/project_model.dart';

final projectControllerProvider = Provider<ProjectController>((ref) {
  return ProjectController();
});

final projectListProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final controller = ref.read(projectControllerProvider);
  return controller.fetchProjects();
});