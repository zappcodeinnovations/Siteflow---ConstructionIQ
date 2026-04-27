import '../model/template_model.dart';

class ProjectTemplateState {
  final bool isLoading;
  final bool isSubmitting;
  final List<ProjectTemplateModel> templates;
  final String? error;
  final String? successMessage;

  ProjectTemplateState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.templates = const [],
    this.error,
    this.successMessage,
  });

  ProjectTemplateState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<ProjectTemplateModel>? templates,
    String? error,
    String? successMessage,
  }) {
    return ProjectTemplateState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      templates: templates ?? this.templates,
      error: error,
      successMessage: successMessage,
    );
  }
}