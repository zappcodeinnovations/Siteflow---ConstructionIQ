import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoint.dart';
import 'package:geolocator/geolocator.dart';

class ClockService {
  static Future<Map<String, dynamic>> clockIn({
    required int projectId,
    required double latitude,
    required double longitude,
    String notes = "",
  }) async {
    try {
      final body = {
        "project_id": projectId,
        "latitude": _formatCoordinate(latitude),
        "longitude": _formatCoordinate(longitude),
        "notes": notes,
      };

      final response = await ApiClient.post(ApiEndpoints.clockIn, body);

      _validateResponse(response);

      debugPrint("📡 CLOCK-IN RESPONSE: $response");

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ CLOCK-IN ERROR: $e");
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

  static String _formatCoordinate(double value) {
    return value.toStringAsFixed(6);
  }
}

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception("Location disabled");

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permission denied forever");
    }

    return await Geolocator.getCurrentPosition();
  }
}
