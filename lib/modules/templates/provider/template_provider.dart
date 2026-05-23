import 'package:euroside/modules/templates/controller/project_template_state.dart';
import 'package:euroside/modules/templates/controller/template_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final projectTemplateControllerProvider =
    StateNotifierProvider<ProjectTemplateController, ProjectTemplateState>(
        (ref) {
  return ProjectTemplateController();
});