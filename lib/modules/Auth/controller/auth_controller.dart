import 'dart:async';
import 'dart:convert';

import 'package:euroside/services/auth_services.dart';
import 'package:euroside/services/current_clock_session_service.dart';
import 'package:euroside/services/profile_services.dart';
import 'package:euroside/services/token_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/auth_model.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final String? successMessage;
  final String? sessionWarningMessage;
  final Map<String, dynamic>? sessionWarningData;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.successMessage,
    this.sessionWarningMessage,
    this.sessionWarningData,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    String? successMessage,
    String? sessionWarningMessage,
    Map<String, dynamic>? sessionWarningData,
    bool clearSessionWarning = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      error: error,
      successMessage: successMessage,
      sessionWarningMessage: clearSessionWarning
          ? null
          : sessionWarningMessage ?? this.sessionWarningMessage,
      sessionWarningData: clearSessionWarning
          ? null
          : sessionWarningData ?? this.sessionWarningData,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  Timer? _messageTimer;

  void _scheduleClearMessages() {
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(error: null, successMessage: null);
    });
  }

  void _setError(String message) {
    state = state.copyWith(
      isLoading: false,
      error: message,
      successMessage: null,
      clearSessionWarning: true,
    );
    _scheduleClearMessages();
  }

  void clearMessages() {
    _messageTimer?.cancel();
    state = state.copyWith(
      error: null,
      successMessage: null,
      clearSessionWarning: true,
    );
  }

  // 🔐 LOGIN
  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
        clearSessionWarning: true,
        clearUser: true,
      );

      print("🔐 [LOGIN FLOW] Starting fresh login API call for email=$email");
      print("📤 LOGIN REQUEST: email=$email password=$password");

      final response = await AuthService.operativeLogin(
        email: email,
        password: password,
      );

      print("✅ [LOGIN FLOW] Login API response received for email=$email");
      print("📤 LOGIN RESPONSE RAW: $response");

      print("📡 LOGIN RESPONSE: $response");

      AuthResponse authResponse = AuthResponse.fromJson(response);
      final shouldSetPassword = !authResponse.user.isPasswordSet;

      print(
        "🧭 [LOGIN FLOW] email=$email "
        "isPasswordSet=${authResponse.user.isPasswordSet} "
        "shouldOpenSetPassword=$shouldSetPassword",
      );

      /// ✅ SAVE TOKEN (IMPORTANT)
      // await TokenManager.saveAccessToken(authResponse.accessToken);

      /// ✅ SAVE LOGIN STATE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("user_email", email);
      await TokenManager.setPasswordSet(email, !shouldSetPassword);

      if (!shouldSetPassword) {
        await CurrentClockSessionService.syncCurrentSession();
      }

      state = state.copyWith(isLoading: false, user: authResponse.user);

      return shouldSetPassword;
    } catch (e, stackTrace) {
      print('❌ [LOGIN ERROR]: $e');
      print('📍 STACKTRACE: $stackTrace');

      if (_isOtherDeviceLoginError(e)) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          successMessage: null,
          sessionWarningMessage: _otherDeviceLoginMessage(e),
          sessionWarningData: _extractBackendJson(e),
        );
        return false;
      }

      _setError(_handleError(e));

      return false;
    }
  }

  // 📝 REGISTER
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
        clearSessionWarning: true,
        clearUser: true,
      );

      print("📝 [REGISTER FLOW] Starting registration for email=$email");

      final response = await AuthService.operativeRegister(
        email: email,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      print("✅ [REGISTER FLOW] API response received for email=$email");

      AuthResponse authResponse = AuthResponse.fromJson(response);
      final shouldSetPassword = !authResponse.user.isPasswordSet;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("user_email", email);
      await TokenManager.setPasswordSet(email, !shouldSetPassword);

      if (!shouldSetPassword) {
        await CurrentClockSessionService.syncCurrentSession();
      }

      state = state.copyWith(isLoading: false, user: authResponse.user);

      return shouldSetPassword;
    } catch (e, stackTrace) {
      print('❌ [REGISTER ERROR]: $e');
      print('📍 STACKTRACE: $stackTrace');

      _setError(_handleError(e));

      return false;
    }
  }

  Future<bool> logoutOtherDevice(String email) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      final response = await AuthService.logoutOtherDevice(email: email);
      final message = response['message']?.toString().trim();

      state = state.copyWith(
        isLoading: false,
        error: null,
        successMessage: message?.isNotEmpty == true
            ? message
            : 'Other device logged out successfully.',
        clearSessionWarning: true,
      );
      _scheduleClearMessages();
      return true;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  // 👤 GET PROFILE
  Future<void> getProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ProfileService.getProfile();

      state = state.copyWith(
        isLoading: false,
        user: User.fromJson(response["user"]),
      );
    } catch (e) {
      print('[AuthController][getProfile] Backend error: $e');
      _setError(_handleError(e));
    }
  }

  // 🔑 SET PASSWORD
  Future<bool> setPassword(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      print("🔑 [SET PASSWORD] API call starting for email=$email");

      final response = await AuthService.setPassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      print("✅ [SET PASSWORD] API response for email=$email: $response");

      final message = _extractSuccessMessage(
        response,
        'Password updated successfully.',
      );
      final normalizedMessage = message.toLowerCase();
      final successValue = response["success"];
      final looksSuccessful =
          successValue == true ||
          response["status"] == true ||
          normalizedMessage.contains('password updated') ||
          normalizedMessage.contains('password changed') ||
          normalizedMessage.contains('password set') ||
          normalizedMessage.contains('success');

      if (looksSuccessful) {
        await TokenManager.setPasswordSet(email, true);

        state = state.copyWith(isLoading: false, successMessage: message);

        print("🧭 [SET PASSWORD] Success, opening home for email=$email");

        return true;
      }

      // ❌ UNKNOWN FAILURE
      _setError("Failed to Reset password");
      print('[AuthController][setPassword] Backend error: $response');

      return false;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  String _extractSuccessMessage(
    Map<String, dynamic> response,
    String fallback,
  ) {
    final dynamic message =
        response["message"] ?? response["detail"] ?? response["success"];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return fallback;
  }

  Map<String, dynamic>? _extractBackendJson(dynamic error) {
    final parts = error.toString().split('|BACKEND_JSON|');
    if (parts.length < 2) return null;

    try {
      final decoded = jsonDecode(parts.last.trim());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  bool _isOtherDeviceLoginError(dynamic error) {
    final backendData = _extractBackendJson(error);
    final errorCode = backendData?['error_code']?.toString().toLowerCase();
    final action = backendData?['action']?.toString().toLowerCase();
    if (errorCode == 'already_logged_in_other_device' ||
        action == 'logout_other_device') {
      return true;
    }

    final normalized = error.toString().toLowerCase();
    return normalized.contains('another device') ||
        normalized.contains('other device') ||
        normalized.contains('other_device') ||
        normalized.contains('already logged') ||
        normalized.contains('already_logged') ||
        normalized.contains('already active') ||
        normalized.contains('active session') ||
        normalized.contains('single device');
  }

  String _otherDeviceLoginMessage(dynamic error) {
    final backendData = _extractBackendJson(error);
    final dynamic backendMessage =
        backendData?['message'] ??
        backendData?['detail'] ??
        backendData?['error'] ??
        backendData?['non_field_errors'];

    if (backendMessage is List && backendMessage.isNotEmpty) {
      final message = backendMessage.first.toString().trim();
      if (message.isNotEmpty) return message;
    }

    if (backendMessage is String && backendMessage.trim().isNotEmpty) {
      return backendMessage.trim();
    }

    final errorCode = backendData?['error_code']?.toString().toLowerCase();
    final action = backendData?['action']?.toString().toLowerCase();
    if (errorCode == 'already_logged_in_other_device' ||
        action == 'logout_other_device') {
      return 'This account is already active on another device.';
    }

    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Exception:', '')
        .split('|BACKEND_JSON|')
        .first
        .trim();

    return message.isNotEmpty
        ? message
        : 'This account is already active on another device.';
  }

  // 📩 FORGOT PASSWORD - SEND OTP
  Future<bool> forgotPassword(String email) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      final response = await AuthService.forgotPassword(email: email);
      final message = _extractSuccessMessage(
        response,
        'OTP sent successfully.',
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
        successMessage: message,
      );
      _scheduleClearMessages();
      return true;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  // ✅ FORGOT PASSWORD - VERIFY OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      final response = await AuthService.verifyOtp(email: email, otp: otp);
      final message = _extractSuccessMessage(
        response,
        'OTP verified successfully.',
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
        successMessage: message,
      );
      _scheduleClearMessages();
      return true;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  // 🔁 FORGOT PASSWORD - RESET PASSWORD
  Future<bool> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      final response = await AuthService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      final message = _extractSuccessMessage(
        response,
        'Password reset successfully.',
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
        successMessage: message,
      );
      _scheduleClearMessages();
      return true;
    } catch (e) {
      _setError(_handleError(e));
      return false;
    }
  }

  // 🚪 LOGOUT
  Future<void> logout() async {
    _messageTimer?.cancel();
    await AuthService.logout();
    state = AuthState();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  // 🧠 ERROR HANDLER (VERY IMPORTANT)
  String _handleError(dynamic e) {
    final errorText = e.toString();
    final sanitizedError = errorText
        .replaceFirst('Exception: ', '')
        .replaceFirst('Exception:', '')
        .split('|BACKEND_JSON|')
        .first
        .trim();

    print("🔥 RAW ERROR: $errorText");

    final normalizedError = sanitizedError.toLowerCase();

    if (normalizedError.contains("invalid credentials") ||
        normalizedError.contains(
          "unable to log in with provided credentials",
        ) ||
        normalizedError.contains(
          "no active account found with the given credentials",
        )) {
      return "Invalid email or password.";
    }

    if (normalizedError.contains("password and confirm password must match")) {
      return "Password and confirm password must match.";
    }

    if ((normalizedError.contains("invalid") ||
            normalizedError.contains("incorrect")) &&
        normalizedError.contains("otp")) {
      return "Invalid OTP. Please try again.";
    }

    if (normalizedError.contains("expired") &&
        normalizedError.contains("otp")) {
      return "OTP has expired. Please request a new one.";
    }

    if (normalizedError.contains("network error")) {
      return "Unable to reach the server. Check your internet connection or try again later.";
    }

    if (normalizedError.contains("server error")) {
      return "Server error. Please try again later.";
    }

    if (normalizedError.contains("failed host lookup") ||
        normalizedError.contains("no address associated with hostname") ||
        normalizedError.contains("socketexception")) {
      return "Unable to reach the server. Check your internet connection or try again later.";
    }

    /// ✅ SHOW REAL ERROR (IMPORTANT)
    return sanitizedError;
  }
}
