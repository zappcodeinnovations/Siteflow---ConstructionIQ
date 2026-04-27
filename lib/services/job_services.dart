import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class JobService {
  /// ✅ GET ALL JOBS
  static Future<Map<String, dynamic>> getJobs() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.jobs);

      _validateResponse(response, key: "jobs");

      debugPrint("📡 JOB API RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ JOB API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// 🔥 GET JOBS BY PROJECT (IMPORTANT FOR YOUR FLOW)
  static Future<Map<String, dynamic>> getJobsByProject(int projectId) async {
    try {
      final endpoint = "${ApiEndpoints.jobs}?project=$projectId";

      final response = await ApiClient.get(endpoint);

      _validateResponse(response, key: "jobs");

      debugPrint("📡 JOB BY PROJECT RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ JOB BY PROJECT ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ COMMON VALIDATION
  static void _validateResponse(
    Map<String, dynamic>? response, {
    String? key,
  }) {
    if (response == null) {
      throw Exception("Empty response from server");
    }

    if (key != null && !response.containsKey(key)) {
      throw Exception("Invalid response format (missing $key)");
    }
  }
}