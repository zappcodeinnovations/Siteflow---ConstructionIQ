import 'package:euro_side/modules/templates/controller/project_template_state.dart';
import 'package:euro_side/modules/templates/controller/template_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final projectTemplateControllerProvider =
    StateNotifierProvider<ProjectTemplateController, ProjectTemplateState>(
        (ref) {
  return ProjectTemplateController();
});