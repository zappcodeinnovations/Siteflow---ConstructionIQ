import 'package:euroside/modules/form/model/form_model.dart';
import 'package:euroside/modules/form/model/form_status_kpi_model.dart';
import 'package:euroside/services/form_service.dart';
import 'package:flutter/material.dart';

class FormsController {
  /// ✅ FETCH FORMS
  Future<List<FormItem>> fetchForms({
    int? jobId,
    bool selectedOnly = false,
  }) async {
    try {
      final response = await FormService.getForms(
        jobId: jobId,
        selectedOnly: selectedOnly,
      );

      final List list = response["results"] ?? [];

      List<FormItem> forms = list.map((item) {
        return FormItem.fromJson(item);
      }).toList();

      debugPrint("📡 TOTAL FORMS => ${forms.length}");

      return forms;
    } catch (e, stackTrace) {
      debugPrint("❌ FORMS CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ FETCH SELECTED FORMS FOR A JOB
  Future<List<FormItem>> fetchSelectedJobForms(int jobId) async {
    try {
      debugPrint("📥 FETCH SELECTED JOB FORMS => jobId: $jobId");

      final response = await FormService.getSelectedJobForms(jobId);

      final List list = response["results"] ?? [];

      final List<FormItem> forms = list.map((item) {
        return FormItem.fromJson(item);
      }).toList();

      debugPrint("📡 SELECTED JOB FORMS COUNT => ${forms.length}");

      for (final form in forms) {
        debugPrint(
          "📄 SELECTED FORM => id: ${form.id}, name: ${form.name}, slug: ${form.slug}",
        );
      }

      return forms;
    } catch (e, stackTrace) {
      debugPrint("❌ SELECTED JOB FORMS CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ FETCH FORM STATUS KPI
  Future<FormStatusKpiModel> fetchFormStatusKpi() async {
    try {
      final response = await FormService.getFormStatusKpi();

      debugPrint("📡 KPI RESPONSE => $response");

      return FormStatusKpiModel.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint("❌ KPI CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ SUBMIT FORM
  Future<bool> submitForm({
    required String formId,
    String? projectId,
    String? jobId,
    Map<String, String>? fields,
  }) async {
    try {
      debugPrint("📤 FORM ID => $formId");
      debugPrint("📤 PROJECT ID => $projectId");
      debugPrint("📤 JOB ID => $jobId");
      debugPrint("📤 FIELDS => $fields");

      final response = await FormService.submitForm(
        formId: formId,
        projectId: projectId,
        jobId: jobId,
        fields: fields,
      );

      debugPrint("📡 SUBMIT RESPONSE => $response");

      /// ✅ SUCCESS CHECK
      final bool success =
          response["success"] == true ||
          response["status"] == true ||
          response["message"] != null;

      return success;
    } catch (e, stackTrace) {
      debugPrint("❌ SUBMIT FORM CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }
}
