import 'dart:io';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class FormService {
  /// ✅ GET ALL FORMS
  static Future<Map<String, dynamic>> getForms() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.formsList);

      _validateResponse(
        response,
        key: "results",
      ); // changed from 'forms' to 'results'

      debugPrint("📡 FORMS API RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ FORMS API ERROR: $e");
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

    /// 🔥 Dynamic fields (important)
    Map<String, String>? fields,

    /// 🔥 Optional file upload (if needed later)
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
