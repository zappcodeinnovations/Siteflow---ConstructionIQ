import 'package:euroside/services/clock_in_services.dart';
import 'package:flutter/material.dart';
import '../model/clock_in_model.dart';

class ClockController {
  Future<ClockInResponse?> clockIn(int projectId) async {
    try {
      final position = await LocationService.getCurrentLocation();
      debugPrint("📍 LATLANG: ${position.latitude}");
      debugPrint("📍 LNG: ${position.longitude}");

      final response = await ClockService.clockIn(
        projectId: projectId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint("✅ CLOCK IN RESPONSE: $response");

      if (response['data'] != null) {
        debugPrint("⏱️ ACTIVE CLOCK DATA: ${response['data']}");
      }
      final clockResponse = ClockInResponse.fromJson(response);

      debugPrint("📩 Message: ${clockResponse.message}");
      debugPrint("📏 Distance: ${clockResponse.distance}");
      debugPrint("📍 Allowed Radius: ${clockResponse.allowedRadius}");
      debugPrint("✅ Within Radius: ${clockResponse.withinRadius}");

      // 🔄 Step 3: Convert response
      return ClockInResponse.fromJson(response);
    } catch (e) {
      debugPrint("❌ CLOCK CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}
