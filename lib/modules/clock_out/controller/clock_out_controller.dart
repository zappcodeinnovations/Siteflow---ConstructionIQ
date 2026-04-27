import 'package:flutter/material.dart';
import '../../../services/clock_out_services.dart';
import '../model/clock_out_model.dart';

class ClockOutController {
  /// ✅ CLOCK OUT
  Future<bool> clockOut({
    required ClockOutModel model,
  }) async {
    try {
      final response = await ClockOutService.clockOut(
        projectId: model.projectId,
        latitude: model.latitude,
        longitude: model.longitude,
        notes: model.notes,
      );

      return response != null;
    } catch (e) {
      debugPrint("❌ CLOCK CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}