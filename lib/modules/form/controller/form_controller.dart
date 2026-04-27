import 'package:euro_side/modules/form/model/form_model.dart';
import 'package:euro_side/services/form_service.dart';
import 'package:flutter/material.dart';

class FormsController {
  /// ✅ FETCH FORMS
  Future<List<FormItem>> fetchForms() async {
    try {
      final response = await FormService.getForms();

      final List list = response["results"];

      List<FormItem> forms = list.map((item) {
        return FormItem.fromJson(item);
      }).toList();

      return forms;
    } catch (e) {
      debugPrint("❌ FORMS CONTROLLER ERROR: $e");
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
      final response = await FormService.submitForm(
        formId: formId,
        projectId: projectId,
        jobId: jobId,
        fields: fields,
      );

      return response != null;
    } catch (e) {
      debugPrint("❌ SUBMIT FORM CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}
