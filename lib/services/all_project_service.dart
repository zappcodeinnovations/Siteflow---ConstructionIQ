import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class AllProjectService {
  static Future<Map<String, dynamic>> getProjects() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.allProjects);

      _validateResponse(response);

      debugPrint("📡 PROJECTTT API RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ PROJECT API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ GET PROJECT DETAILS
  static Future<Map<String, dynamic>> getProjectDetails(int projectId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.projectDetails(projectId),
      );

      _validateResponse(response, key: "data");

      debugPrint("📡 PROJECT DETAILS RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ PROJECT DETAILS ERROR: $e");
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
