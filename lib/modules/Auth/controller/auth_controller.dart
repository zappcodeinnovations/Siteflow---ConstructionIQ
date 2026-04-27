import 'dart:async';

import 'package:euro_side/services/auth_services.dart';
import 'package:euro_side/services/profile_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/auth_model.dart';

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final String? successMessage;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      successMessage: successMessage,
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
    );
    _scheduleClearMessages();
  }

  void clearMessages() {
    _messageTimer?.cancel();
    state = state.copyWith(error: null, successMessage: null);
  }

  // 🔐 LOGIN
  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        successMessage: null,
      );

      print("📤 LOGIN REQUEST: email=$email password=$password");

      final response = await AuthService.operativeLogin(
        email: email,
        password: password,
      );

      print("📡 LOGIN RESPONSE: $response");

      AuthResponse authResponse = AuthResponse.fromJson(response);

      /// ✅ SAVE TOKEN (IMPORTANT)
      // await TokenManager.saveAccessToken(authResponse.accessToken);

      /// ✅ SAVE LOGIN STATE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("user_email", email);

      state = state.copyWith(isLoading: false, user: authResponse.user);

      /// FIRST LOGIN CHECK
      final isFirstLogin = prefs.getBool("isFirstLogin_$email") ?? true;

      return isFirstLogin;
    } catch (e, stackTrace) {
      print('❌ [LOGIN ERROR]: $e');
      print('📍 STACKTRACE: $stackTrace');

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

      final response = await AuthService.setPassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      // ✅ SUCCESS
      if (response["message"] == "Password updated successfully.") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isFirstLogin_$email", false);

        state = state.copyWith(
          isLoading: false,
          successMessage: response["message"],
        );

        return true;
      }

      // ❌ UNKNOWN FAILURE
      _setError("Failed to set password");
      print('[AuthController][setPassword] Backend error: $response');

      return false;
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

    if (normalizedError.contains("network error")) {
      return "Network error. Please try again.";
    }

    if (normalizedError.contains("server error")) {
      return "Server error. Please try again later.";
    }

    /// ✅ SHOW REAL ERROR (IMPORTANT)
    return sanitizedError;
  }
}
