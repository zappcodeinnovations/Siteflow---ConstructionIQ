import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class ProjectTemplateService {
  /// ✅ GET PROJECT TEMPLATES
  static Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.projectTemplates);

      _validateResponse(response);

      debugPrint("📡 TEMPLATE API RESPONSE: $response");

      // Use 'data' instead of 'results' as per new API
      final List data = response['data'] ?? [];

      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      debugPrint("❌ TEMPLATE API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ SAVE / SUBMIT TEMPLATE
  static Future<Map<String, dynamic>> submitTemplate({
    required int projectId,
    required int templateId,
    required List<Map<String, dynamic>> submissions, // [{field_id, value}]
  }) async {
    try {
      final body = {
        "project_id": projectId,
        "template_id": templateId,
        "submissions": submissions,
      };

      final response = await ApiClient.post(
        ApiEndpoints.templateSubmission,
        body,
      );

      _validateResponse(response);

      debugPrint("📡 TEMPLATE SUBMIT RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ TEMPLATE SUBMIT ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ COMMON VALIDATION
  static void _validateResponse(Map<String, dynamic>? response) {
    if (response == null) {
      throw Exception("Empty response from server");
    }
  }
}
