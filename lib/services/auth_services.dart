import 'dart:math';

import 'package:euroside/network/api_endpoint.dart';
import 'package:euroside/services/fcm_service.dart';
import 'package:euroside/services/token_services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthService {
  static const String _deviceIdKey = 'device_id';

  // Operative Login
  static Future<Map<String, dynamic>> operativeLogin({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final fcmToken = await FcmService.getCurrentToken();

    _logLoginToken('operativeLogin', deviceId, fcmToken);

    final payload = {
      'email': email,
      'password': password,
      'device_id': deviceId,
      'fcm_token': fcmToken,
    };

    // ignore: avoid_print
    print('[AuthService][operativeLogin] request payload: $payload');

    final response = await ApiClient.post(
      ApiEndpoints.operativeLogin,
      payload,
      includeAuth: false,
    );

    // Save tokens
    final tokens = response["tokens"];
    await TokenManager.saveTokens(tokens["access"], tokens["refresh"]);

    return response;
  }

  // Normal Token Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final fcmToken = await FcmService.getCurrentToken();

    _logLoginToken('login', deviceId, fcmToken);

    final payload = {
      'email': email,
      'password': password,
      'device_id': deviceId,
      'fcm_token': fcmToken,
    };

    // ignore: avoid_print
    print('[AuthService][login] request payload: $payload');

    final response = await ApiClient.post(
      ApiEndpoints.login,
      payload,
      includeAuth: false,
    );

    await TokenManager.saveTokens(response["access"], response["refresh"]);

    return response;
  }

  // Single device session status
  static Future<Map<String, dynamic>> singleDeviceSession() async {
    final response = await ApiClient.get(ApiEndpoints.singleDeviceSession);

    return Map<String, dynamic>.from(response as Map);
  }

  static Future<Map<String, dynamic>> logoutOtherDevice({
    required String email,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final fcmToken = await FcmService.getCurrentToken();

    final payload = {
      'email': email,
      'device_id': deviceId,
      'fcm_token': fcmToken,
    };

    // ignore: avoid_print
    print('[AuthService][logoutOtherDevice] request payload: $payload');

    final response = await ApiClient.post(
      ApiEndpoints.logoutOtherDevice,
      payload,
    );

    return Map<String, dynamic>.from(response as Map);
  }

  // Refresh Token
  static Future<String?> refreshAccessToken() async {
    final refreshToken = await TokenManager.getRefreshToken();

    if (refreshToken == null) return null;

    final response = await ApiClient.post(ApiEndpoints.refreshToken, {
      "refresh": refreshToken,
    });

    String newAccess = response["access"];

    await TokenManager.saveTokens(newAccess, refreshToken);

    return newAccess;
  }

  // Set Password
  static Future<Map<String, dynamic>> setPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.setPassword, {
      "email": email,
      "password": password,
      "confirm_password": confirmPassword,
    });

    return response;
  }

  // Forgot Password: Send OTP
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.forgotPassword, {
      "email": email,
    });
    print('[AuthService][forgotPassword] Backend response: $response');

    return response;
  }

  // Forgot Password: Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.verifyOtp, {
      "email": email,
      "otp": otp,
    });
    print('[AuthService][verifyOtp] Backend response: $response');

    return response;
  }

  // Forgot Password: Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.resetPassword, {
      "email": email,
      "otp": otp,
      "new_password": newPassword,
      "confirm_password": confirmPassword,
    });
    print('[AuthService][resetPassword] Backend response: $response');

    return response;
  }

  // Logout
  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiEndpoints.logout, {});
    } catch (e) {
      debugPrint('[AuthService][logout] Backend logout skipped: $e');
    } finally {
      await TokenManager.clearAll();
    }
  }

  static Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final platformPrefix = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      TargetPlatform.macOS => 'MACOS',
      TargetPlatform.windows => 'WINDOWS',
      TargetPlatform.linux => 'LINUX',
      TargetPlatform.fuchsia => 'FUCHSIA',
    };

    final randomSuffix = List.generate(12, (_) {
      return Random.secure().nextInt(16).toRadixString(16).toUpperCase();
    }).join();

    final deviceId = '${platformPrefix}_$randomSuffix';
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  /// Ensure a device id exists; useful to call at app startup.
  static Future<void> ensureDeviceIdCreated() async {
    await _getOrCreateDeviceId();
  }

  static void _logLoginToken(String action, String deviceId, String fcmToken) {
    // ignore: avoid_print
    print('[AuthService][$action] device_id: $deviceId');
    // ignore: avoid_print
    print('[AuthService][$action] fcm_token to send: $fcmToken');
  }
}
