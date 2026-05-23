import 'package:euroside/modules/all_projects/model/all_project_model.dart';


class AllProjectState {
  final bool isLoading;
  final bool isSubmitting;

  final String? error;
  final String? successMessage;

  final List<AllprojectModel> projects;

  final AllprojectModel? selectedProject;

  AllProjectState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
    this.projects = const [],
    this.selectedProject,
  });

  AllProjectState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? successMessage,
    List<AllprojectModel>? projects,
    AllprojectModel? selectedProject,
  }) {
    return AllProjectState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      successMessage: successMessage,
      projects: projects ?? this.projects,
      selectedProject:
          selectedProject ?? this.selectedProject,
    );
  }
}