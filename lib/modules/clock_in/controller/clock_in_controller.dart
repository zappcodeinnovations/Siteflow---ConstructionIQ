import 'package:euroside/services/clock_in_services.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../model/clock_in_model.dart';

class ClockController {
  double? _extractDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _logBackendLocationDetails(Map<String, dynamic> response) {
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final backendProjectLat =
        _extractDouble(response['project_latitude']) ??
        _extractDouble(data['project_latitude']);
    final backendProjectLng =
        _extractDouble(response['project_longitude']) ??
        _extractDouble(data['project_longitude']);
    final backendUserLat =
        _extractDouble(response['user_latitude']) ??
        _extractDouble(data['user_latitude']);
    final backendUserLng =
        _extractDouble(response['user_longitude']) ??
        _extractDouble(data['user_longitude']);

    if (backendProjectLat != null ||
        backendProjectLng != null ||
        backendUserLat != null ||
        backendUserLng != null) {
      debugPrint(
        '[ClockIn][DEBUG] Backend location details => projectLat=$backendProjectLat, projectLng=$backendProjectLng, userLat=$backendUserLat, userLng=$backendUserLng',
      );
    }
  }

  Future<ClockInResponse?> clockIn(int projectId) async {
    try {
      final position = await LocationService.getCurrentLocation();
      debugPrint(
        '[ClockIn][DEBUG] User current location => lat=${position.latitude}, lng=${position.longitude}',
      );

      final response = await ClockService.clockIn(
        projectId: projectId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint("✅ CLOCK IN RESPONSE: $response");

      if (response['data'] != null) {
        debugPrint("⏱️ ACTIVE CLOCK DATA: ${response['data']}");
      }

      _logBackendLocationDetails(response);

      final clockResponse = ClockInResponse.fromJson(response);

      debugPrint("📩 Message: ${clockResponse.message}");
      debugPrint("📏 Distance: ${clockResponse.distance}");
      debugPrint("📍 Allowed Radius: ${clockResponse.allowedRadius}");
      debugPrint("✅ Within Radius: ${clockResponse.withinRadius}");
      debugPrint(
        '[ClockIn][DEBUG] Location match result => ${clockResponse.withinRadius ? 'MATCHED (clock-in allowed)' : 'MISMATCH (clock-in blocked)'}',
      );

      // Compact one-line summary for easy scanning in logs
      final backendProjectLat =
          _extractDouble(response['project_latitude']) ??
          _extractDouble(
            response['data'] is Map<String, dynamic>
                ? response['data']['project_latitude']
                : null,
          );
      final backendProjectLng =
          _extractDouble(response['project_longitude']) ??
          _extractDouble(
            response['data'] is Map<String, dynamic>
                ? response['data']['project_longitude']
                : null,
          );

      final projectLatLng =
          (backendProjectLat != null && backendProjectLng != null)
          ? '${backendProjectLat.toStringAsFixed(6)},${backendProjectLng.toStringAsFixed(6)}'
          : 'unknown';

      final userLatLng =
          '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';

      // Try to reverse-geocode both project and user coordinates for a detailed address
      String projectAddress = 'unknown';
      String userAddress = 'unknown';

      try {
        if (backendProjectLat != null && backendProjectLng != null) {
          final projectPlacemarks = await placemarkFromCoordinates(
            backendProjectLat,
            backendProjectLng,
          );

          if (projectPlacemarks.isNotEmpty) {
            projectAddress = _formatDetailedAddress(projectPlacemarks.first);
          }
        }
      } catch (e) {
        debugPrint(
          '[ClockIn][DEBUG] Failed to reverse-geocode project coords: $e',
        );
      }

      try {
        final userPlacemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (userPlacemarks.isNotEmpty) {
          userAddress = _formatDetailedAddress(userPlacemarks.first);
        }
      } catch (e) {
        debugPrint(
          '[ClockIn][DEBUG] Failed to reverse-geocode user coords: $e',
        );
      }

      debugPrint(
        '[ClockIn][SUMMARY] project:$projectLatLng ($projectAddress) vs user:$userLatLng ($userAddress) => distance ${clockResponse.distance} m, allowed ${clockResponse.allowedRadius} m, result: ${clockResponse.withinRadius ? 'MATCHED' : 'MISMATCH'}',
      );

      // 🔄 Step 3: Return parsed response
      return clockResponse;
    } catch (e) {
      debugPrint("❌ CLOCK CONTROLLER ERROR: $e");
      rethrow;
    }
  }

  String _formatDetailedAddress(Placemark place) {
    final parts = <String>[
      place.subThoroughfare?.trim() ?? '',
      place.thoroughfare?.trim() ?? '',
      place.subLocality?.trim() ?? '',
      place.locality?.trim() ?? '',
      place.administrativeArea?.trim() ?? '',
      place.postalCode?.trim() ?? '',
      place.country?.trim() ?? '',
    ];

    final cleaned = parts.where((part) => part.isNotEmpty).toList();

    if (cleaned.isEmpty) return '';

    return cleaned.join(', ');
  }
}
