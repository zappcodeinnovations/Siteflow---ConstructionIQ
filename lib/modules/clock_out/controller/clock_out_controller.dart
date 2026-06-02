import 'dart:convert';

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

      final parsed = _parseClockOutError(e);
      final normalized = _normalizeClockOutError(parsed);
      final backendJson = _extractBackendJson(e);

      if (backendJson.isNotEmpty) {
        throw Exception('$normalized |BACKEND_JSON| $backendJson');
      }

      throw Exception(normalized);
    }
  }

  String _extractBackendJson(Object error) {
    final raw = error.toString();
    final marker = raw.indexOf('|BACKEND_JSON|');

    if (marker != -1) {
      return raw.substring(marker + '|BACKEND_JSON|'.length).trim();
    }

    final jsonStart = raw.indexOf('{');
    if (jsonStart != -1) {
      return raw.substring(jsonStart).trim();
    }

    return '';
  }

  String _parseClockOutError(Object error) {
    final raw = error.toString();

    final backendMarker = raw.indexOf('|BACKEND_JSON|');
    if (backendMarker != -1) {
      final jsonPart = raw
          .substring(backendMarker + '|BACKEND_JSON|'.length)
          .trim();
      try {
        final decoded = jsonDecode(jsonPart);
        if (decoded is Map<String, dynamic>) {
          final detail = decoded['detail'];
          if (detail != null) {
            return detail.toString();
          }
        }
      } catch (_) {}
    }

    try {
      final jsonStart = raw.indexOf('{');
      if (jsonStart != -1) {
        final decoded = jsonDecode(raw.substring(jsonStart));
        if (decoded is Map<String, dynamic>) {
          final detail = decoded['detail'];
          if (detail != null) {
            return detail.toString();
          }
        }
      }
    } catch (_) {}

    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }

    return raw;
  }

  String _normalizeClockOutError(String error) {
    final lower = error.toLowerCase();

    const taskSheetHints = [
      'task sheet',
      'task-sheet',
      'fill the task sheet',
      'please fill',
      'fill and submit',
      'submit the form',
      'required form',
      'form required',
    ];

    const wrongLocationHints = [
      'site location',
      'correct location',
      'wrong location',
      'different location',
      'not at the site',
      'outside the site',
      'not appropriate',
      'not apropriet',
      'not allowed',
      'location mismatch',
      'outside location',
      'radius',
    ];

    if (taskSheetHints.any(lower.contains)) {
      return 'Please fill and submit the task sheet before clocking out.';
    }

    if (wrongLocationHints.any(lower.contains)) {
      return 'You are not at the correct site location for this project. Please move to the site area and try clocking out again.';
    }

    return error;
  }
}
