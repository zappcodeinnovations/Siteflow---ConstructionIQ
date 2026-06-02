import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class ClockOutService {
  static Future<Map<String, dynamic>> clockOut({
    required int projectId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final body = {
        "project_id": projectId,
        "latitude": _formatCoordinate(latitude),
        "longitude": _formatCoordinate(longitude),
        if (notes != null) "notes": notes,
      };

      final response = await ApiClient.post(ApiEndpoints.clockOut, body);

      debugPrint("📡 CLOCK OUT RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ CLOCK OUT ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  static String _formatCoordinate(double value) {
    return value.toStringAsFixed(6);
  }
}
