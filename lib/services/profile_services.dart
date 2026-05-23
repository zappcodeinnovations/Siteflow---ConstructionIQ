import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:euroside/network/api_endpoint.dart';
import '../network/api_client.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.profile);

      /// ✅ PRINT FULL RESPONSE
      debugPrint("📡 PROFILE API RESPONSE: $response");

      /// ✅ VALIDATE RESPONSE
      if (response == null) {
        throw Exception("Empty response from server");
      }

      if (!response.containsKey("user")) {
        throw Exception("Invalid response format (missing user)");
      }

      return response;
    } catch (e, stackTrace) {
      /// ❌ PRINT ERROR
      debugPrint("❌ PROFILE API ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow; // send error to controller
    }
  }
}