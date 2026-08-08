import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/current_clock_session_service.dart';
import '../../services/profile_services.dart';
import '../../services/token_services.dart';
import 'package:euroside/modules/Auth/model/auth_model.dart';

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
      debugPrint("════════ APP INITIALIZATION START ════════");

      /// Optional splash delay
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();

      /// ✅ CHECK LOGIN STATUS
      final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      debugPrint("🔐 IS LOGGED IN => $isLoggedIn");

      if (!isLoggedIn) {
        debugPrint("❌ USER NOT LOGGED IN");

        state = AppStartStatus.unauthenticated;
        return;
      }

      /// ✅ TOKEN CHECK
      final token = await TokenManager.getAccessToken();

      debugPrint("🎟 ACCESS TOKEN => $token");

      if (token == null || token.isEmpty) {
        debugPrint("❌ TOKEN NOT FOUND");

        await prefs.setBool("isLoggedIn", false);

        state = AppStartStatus.unauthenticated;
        return;
      }

      /// ✅ EMAIL CHECK
      final email = prefs.getString("user_email");

      debugPrint("📧 USER EMAIL => $email");

      if (email == null || email.isEmpty) {
        debugPrint("❌ EMAIL NOT FOUND");

        await prefs.setBool("isLoggedIn", false);

        state = AppStartStatus.unauthenticated;
        return;
      }

      /// 🔥 FETCH PROFILE FROM BACKEND
      debugPrint("📡 FETCHING PROFILE");

      final profileResponse = await ProfileService.getProfile();

      debugPrint("📦 PROFILE RESPONSE => $profileResponse");

      final user = profileResponse["user"];

      if (user == null) {
        debugPrint("❌ USER DATA NOT FOUND");

        state = AppStartStatus.unauthenticated;
        return;
      }

      /// 🔐 CHECK PASSWORD STATUS
      final authUser = User.fromJson(user);
      final bool isPasswordSet = authUser.isPasswordSet;

      debugPrint("🔐 IS PASSWORD SET => $isPasswordSet");

      /// 👤 EXTRA USER DEBUGS
      debugPrint("👤 USERNAME => ${user["username"]}");
      debugPrint("📛 DISPLAY NAME => ${user["display_name"]}");
      debugPrint("📧 EMAIL => ${user["email"]}");
      debugPrint("🪪 ROLE => ${user["effective_role"]}");

      /// 🆕 FIRST TIME USER
      if (!isPasswordSet) {
        debugPrint("🆕 REDIRECT TO SET PASSWORD");

        state = AppStartStatus.firstTimeUser;
      } else {
        debugPrint("✅ PASSWORD ALREADY SET");

        /// 🔄 SYNC CURRENT CLOCK SESSION
        await CurrentClockSessionService.syncCurrentSession();

        debugPrint("🏠 REDIRECT TO HOME");

        state = AppStartStatus.authenticated;
      }

      debugPrint("════════ APP INITIALIZATION END ════════");
    } catch (e, stackTrace) {
      debugPrint("❌ APP INITIALIZATION ERROR => $e");
      debugPrint("📍 STACKTRACE => $stackTrace");

      state = AppStartStatus.unauthenticated;
    }
  }
}