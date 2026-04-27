import 'package:euro_side/services/clock_in_services.dart';
import 'package:flutter/material.dart';
import '../model/clock_in_model.dart';

class ClockController {
  Future<ClockInResponse?> clockIn(int projectId) async {
    try {
      // 📍 Step 1: Get GPS location
      final position = await LocationService.getCurrentLocation();

      // 📡 Step 2: Call your existing service
      final response = await ClockService.clockIn(
        projectId: projectId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 🔄 Step 3: Convert response
      return ClockInResponse.fromJson(response);
    } catch (e) {
      debugPrint("❌ CLOCK CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}
