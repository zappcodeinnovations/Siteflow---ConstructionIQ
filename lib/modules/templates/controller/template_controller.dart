import 'dart:async';
import 'package:euroside/modules/templates/model/template_model.dart';
import 'package:euroside/services/template_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_template_state.dart';

class ProjectTemplateController extends StateNotifier<ProjectTemplateState> {
  ProjectTemplateController() : super(ProjectTemplateState());

  Timer? _messageTimer;

  void _scheduleClearMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(error: null, successMessage: null);
    });
  }

  void _setError(String message) {
    state = state.copyWith(
      isLoading: false,
      isSubmitting: false,
      error: message,
      successMessage: null,
    );
    _scheduleClearMessages();
  }

  void clearMessages() {
    _messageTimer?.cancel();
    state = state.copyWith(error: null, successMessage: null);
  }

  /// FETCH TEMPLATES
  Future<void> fetchTemplates() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final data = await ProjectTemplateService.getTemplates();

      final templateModels = data
          .map((e) => ProjectTemplateModel.fromJson(e))
          .toList();

      state = state.copyWith(isLoading: false, templates: templateModels);
    } catch (e) {
      _setError(_handleError(e));
    }
  }

  /// SUBMIT TEMPLATE (updated for new API)
  Future<bool> submitTemplate({
    required int projectId,
    required int templateId,
    required List<Map<String, dynamic>> submissions, // [{field_id, value}]
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      final response = await ProjectTemplateService.submitTemplate(
        projectId: projectId,
        templateId: templateId,
        submissions: submissions,
      );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: response["message"] ?? "Success",
      );

      _scheduleClearMessages();

      return response['status'] == true;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  String _handleError(dynamic e) {
    return e.toString().replaceAll("Exception:", "").trim();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}
