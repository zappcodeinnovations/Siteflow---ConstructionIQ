import 'dart:convert';

import 'package:euroside/modules/announcements/model/announcement_model.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../network/api_endpoint.dart';

import '../services/token_services.dart';

class AnnouncementService {
  /// ==========================================
  /// GET ANNOUNCEMENTS
  /// ==========================================

  static Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final token = await TokenManager.getAccessToken();

      final uri = Uri.parse(
        "${ApiEndpoints.baseUrl}"
        "${ApiEndpoints.announcements}",
      );

      debugPrint("📡 ANNOUNCEMENT URL: $uri");

      final response = await http.get(
        uri,

        headers: {
          "Authorization": "Bearer $token",

          "Accept": "application/json",
        },
      );

      debugPrint(
        "📡 STATUS CODE: "
        "${response.statusCode}",
      );

      debugPrint(
        "📡 RESPONSE BODY: "
        "${response.body}",
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List results = decoded["results"] ?? [];

        return results.map((e) => AnnouncementModel.fromJson(e)).toList();
      }

      throw Exception("Failed to fetch announcements");
    } catch (e, stackTrace) {
      debugPrint("❌ ANNOUNCEMENT ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }
}
