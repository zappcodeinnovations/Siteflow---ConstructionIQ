import 'package:euroside/network/api_client.dart';
import 'package:euroside/network/api_endpoint.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentClockSessionService {
  static const String _clockedInKey = "isClockedIn";
  static const String _clockedInProjectIdKey = "clockedInProjectId";
  static const String _clockInStartMillisKey = "clockInStartMillis";
  static const String _clockSessionIdKey = "clockSessionId";
  static const String _clockedInProjectNameKey = "clockedInProjectName";

  static Future<CurrentClockSession> fetchCurrentSession() async {
    final response = await ApiClient.get(ApiEndpoints.currentClockSession);
    return CurrentClockSession.fromJson(response as Map<String, dynamic>);
  }

  static Future<CurrentClockSession?> syncCurrentSession() async {
    try {
      final session = await fetchCurrentSession();
      final prefs = await SharedPreferences.getInstance();

      if (!session.isClockedIn || session.data == null) {
        await clearCachedSession();
        return session;
      }

      final elapsedSeconds = session.data!.elapsedSeconds;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final derivedStartMillis = nowMillis - (elapsedSeconds * 1000);

      await prefs.setBool(_clockedInKey, true);
      await prefs.setInt(_clockedInProjectIdKey, session.data!.projectId);
      await prefs.setInt(_clockInStartMillisKey, derivedStartMillis);
      await prefs.setInt(_clockSessionIdKey, session.data!.clockSessionId);
      await prefs.setString(
        _clockedInProjectNameKey,
        session.data!.projectName,
      );

      return session;
    } catch (e) {
      debugPrint('[CurrentClockSessionService] sync error: $e');
      return null;
    }
  }

  static Future<void> clearCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clockedInKey, false);
    await prefs.remove(_clockedInProjectIdKey);
    await prefs.remove(_clockInStartMillisKey);
    await prefs.remove(_clockSessionIdKey);
    await prefs.remove(_clockedInProjectNameKey);
  }
}

class CurrentClockSession {
  final bool success;
  final bool isClockedIn;
  final CurrentClockSessionData? data;

  const CurrentClockSession({
    required this.success,
    required this.isClockedIn,
    required this.data,
  });

  factory CurrentClockSession.fromJson(Map<String, dynamic> json) {
    return CurrentClockSession(
      success: json['success'] == true,
      isClockedIn: json['is_clocked_in'] == true,
      data: json['data'] is Map<String, dynamic>
          ? CurrentClockSessionData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CurrentClockSessionData {
  final int clockSessionId;
  final int projectId;
  final String projectName;
  final String clockInTime;
  final String serverCurrentTime;
  final int elapsedSeconds;
  final double latitude;
  final double longitude;
  final int employeeId;

  const CurrentClockSessionData({
    required this.clockSessionId,
    required this.projectId,
    required this.projectName,
    required this.clockInTime,
    required this.serverCurrentTime,
    required this.elapsedSeconds,
    required this.latitude,
    required this.longitude,
    required this.employeeId,
  });

  factory CurrentClockSessionData.fromJson(Map<String, dynamic> json) {
    return CurrentClockSessionData(
      clockSessionId: _toInt(json['clock_session_id']),
      projectId: _toInt(json['project_id']),
      projectName: (json['project_name'] ?? '').toString(),
      clockInTime: (json['clock_in_time'] ?? '').toString(),
      serverCurrentTime: (json['server_current_time'] ?? '').toString(),
      elapsedSeconds: _toInt(json['elapsed_seconds']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      employeeId: _toInt(json['employee_id']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
