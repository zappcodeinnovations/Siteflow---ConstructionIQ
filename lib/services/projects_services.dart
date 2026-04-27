import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class ProjectService {
  static Future<Map<String, dynamic>> getProjects() async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.projects, // 👈 make sure you add this endpoint
      );

      /// ✅ PRINT FULL RESPONSE
      debugPrint("📡 PROJECT API RESPONSE: $response");

      /// ✅ VALIDATE RESPONSE
      if (response == null) {
        throw Exception("Empty response from server");
      }

      if (!response.containsKey("projects")) {
        throw Exception("Invalid response format (missing projects)");
      }

      return response;
    } catch (e, stackTrace) {
      /// ❌ PRINT ERROR
      debugPrint("❌ PROJECT API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }
}