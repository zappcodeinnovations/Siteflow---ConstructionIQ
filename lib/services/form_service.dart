import 'dart:io';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class FormService {
  /// ✅ GET ALL FORMS
  static Future<Map<String, dynamic>> getForms({
    int? jobId,
    bool selectedOnly = false,
  }) async {
    try {
      final endpoint = selectedOnly && jobId != null
          ? ApiEndpoints.selectedJobForms(jobId)
          : (jobId != null || selectedOnly)
          ? ApiEndpoints.formsQuery(jobId: jobId, selectedOnly: selectedOnly)
          : ApiEndpoints.formsList;

      final response = await ApiClient.get(endpoint);

      _validateResponse(response, key: "results");

      debugPrint("📡 FORMS API RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ FORMS API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ GET SELECTED FORMS FOR A JOB
  static Future<Map<String, dynamic>> getSelectedJobForms(int jobId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.selectedJobForms(jobId),
      );

      _validateResponse(response, key: "results");

      debugPrint("📡 SELECTED JOB FORMS RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ SELECTED JOB FORMS API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ GET FORM STATUS KPI
  static Future<Map<String, dynamic>> getFormStatusKpi() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.formStatusKpi);

      _validateResponse(response);

      debugPrint("📡 FORM STATUS KPI RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ FORM STATUS KPI ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// 🔥 SUBMIT FORM (MULTIPART)
  static Future<Map<String, dynamic>> submitForm({
    required String formId,
    String? projectId,
    String? jobId,
    String action = "submit",

    /// 🔥 Dynamic fields
    Map<String, String>? fields,

    /// 🔥 Optional file upload
    File? file,
    String? fileKey,
  }) async {
    try {
      final Map<String, String> body = {"form_id": formId, "action": action};

      if (projectId != null) body["project_id"] = projectId;
      if (jobId != null) body["job_id"] = jobId;

      /// ✅ Add dynamic fields
      if (fields != null) {
        body.addAll(fields);
      }

      final response = await ApiClient.multipart(
        ApiEndpoints.submitForm,
        fields: body,
        file: file,
        fileKey: fileKey,
      );

      _validateResponse(response);

      debugPrint("📡 SUBMIT FORM RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ SUBMIT FORM ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ COMMON VALIDATION
  static void _validateResponse(Map<String, dynamic>? response, {String? key}) {
    if (response == null) {
      throw Exception("Empty response from server");
    }

    if (key != null && !response.containsKey(key)) {
      throw Exception("Invalid response format (missing $key)");
    }
  }
}
