import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/services/token_services.dart';
import 'package:flutter/material.dart';

class SessionLogoutRouter {
  SessionLogoutRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static bool _isNavigating = false;

  static Future<void> routeToLogin({
    String logoutMessage = 'Please login again.',
  }) async {
    if (_isNavigating) return;
    _isNavigating = true;

    await TokenManager.clearAll();

    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SignInScreen(
            showLogoutMessage: true,
            logoutMessage: logoutMessage,
          ),
        ),
        (route) => false,
      );
    }

    _isNavigating = false;
  }

  static Future<void> routeToLoginFromAnotherDevice() async {
    await routeToLogin(
      logoutMessage: 'Your login is active on another device.',
    );
  }
}
