import 'package:flutter/material.dart';

import '../../../services/clock_out_services.dart';

import '../model/clock_out_model.dart';

class ClockOutController {

  Future<bool> clockOut({required ClockOutModel model}) async {
    try {
      

      debugPrint("🚪 CLOCK OUT STARTED");

      debugPrint("📁 Project ID: ${model.projectId}");

      debugPrint("📍 Latitude: ${model.latitude}");

      debugPrint("📍 Longitude: ${model.longitude}");

      debugPrint("📝 Notes: ${model.notes}");

      /// =========================================
      /// API CALL
      /// =========================================

      final response = await ClockOutService.clockOut(
        projectId: model.projectId,

        latitude: model.latitude,

        longitude: model.longitude,

        notes: model.notes,
      );

      /// =========================================
      /// PRINT RESPONSE
      /// =========================================

      debugPrint("✅ CLOCK OUT RESPONSE: $response");

      /// SUCCESS
      if (response != null) {
        debugPrint(
          "🎉 Successfully clocked out "
          "from Project ID: ${model.projectId}",
        );

        return true;
      }

      debugPrint(
        "❌ Clock out failed "
        "for Project ID: ${model.projectId}",
      );

      return false;
    } catch (e, stackTrace) {
      /// =========================================
      /// ERROR LOG
      /// =========================================

      debugPrint("❌ CLOCK CONTROLLER ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      /// =========================================
      /// THROW CLEAN ERROR MESSAGE
      /// =========================================

      final error = e.toString();

      /// FORM REQUIRED
      if (error.toLowerCase().contains("form") ||
          error.toLowerCase().contains("submit")) {
        throw Exception(
          "Please fill and submit the required form before clock out.",
        );
      }

      /// OTHER ERROR
      throw Exception(error);
    }
  }
}
