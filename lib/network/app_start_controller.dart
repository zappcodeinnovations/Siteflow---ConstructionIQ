import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/token_services.dart';

enum AppStartStatus {
  loading,
  unauthenticated,
  firstTimeUser,
  authenticated,
}

class AppStartController extends StateNotifier<AppStartStatus> {
  AppStartController() : super(AppStartStatus.loading);

  Future<void> initializeApp() async {
    try {
      // Optional splash delay
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();

      /// ✅ MAIN FIX: check login flag first
      final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      if (!isLoggedIn) {
        state = AppStartStatus.unauthenticated;
        return;
      }

      /// 🔐 Token check (extra safety)
      final token = await TokenManager.getAccessToken();

      if (token == null || token.isEmpty) {
        /// If token missing → force logout
        await prefs.setBool("isLoggedIn", false);
        state = AppStartStatus.unauthenticated;
        return;
      }

      /// 📧 Email check
      final email = prefs.getString("user_email");

      if (email == null || email.isEmpty) {
        await prefs.setBool("isLoggedIn", false);
        state = AppStartStatus.unauthenticated;
        return;
      }

      /// 🆕 First time login check
      final isFirstLogin =
          prefs.getBool("isFirstLogin_$email") ?? true;

      if (isFirstLogin) {
        state = AppStartStatus.firstTimeUser;
      } else {
        state = AppStartStatus.authenticated;
      }
    } catch (e) {
      state = AppStartStatus.unauthenticated;
    }
  }
}