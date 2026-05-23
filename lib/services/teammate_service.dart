import 'dart:convert';

import 'package:euroside/modules/Team/model/teammate_model.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../network/api_endpoint.dart';

import '../services/token_services.dart';

class TeammateService {
  static Future<List<TeammateModel>> getProjectTeammates(int projectId) async {
    try {
      final token = await TokenManager.getAccessToken();

      final uri = Uri.parse(
        "${ApiEndpoints.baseUrl}"
        "${ApiEndpoints.projectTeammates(projectId)}",
      );

      debugPrint("📡 TEAMMATES URL: $uri");

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

        final List teammates = decoded["data"]["teammates"] ?? [];

        return teammates.map((e) => TeammateModel.fromJson(e)).toList();
      }

      throw Exception("Failed to fetch teammates");
    } catch (e, stackTrace) {
      debugPrint("❌ TEAMMATE ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }
}
