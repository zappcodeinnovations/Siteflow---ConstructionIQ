import 'package:euroside/modules/all_projects/controller/all_project_controller.dart';
import 'package:euroside/modules/all_projects/controller/all_project_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AllprojectControllerProvider =
    StateNotifierProvider<AllProjectController, AllProjectState>((ref) {
      final controller = AllProjectController();

      // Auto fetch when provider initializes
      controller.fetchProjects();

      return controller;
    });
