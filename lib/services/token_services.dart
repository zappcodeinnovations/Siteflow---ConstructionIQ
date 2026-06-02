import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String accessTokenKey = "access_token";
  static const String refreshTokenKey = "refresh_token";
  static const String userEmailKey = "user_email";
  static const String clockedInProjectIdsKey = "clockedInProjectIds";
  static const String _passwordSetPrefix = "isPasswordSet_";
  static const String _firstLoginPrefix = "isFirstLogin_";

  static String _normalizedEmail(String email) {
    return email.trim().toLowerCase();
  }

  // 🔐 SAVE TOKENS
  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, access);
    await prefs.setString(refreshTokenKey, refresh);
  }

  /// REMOVE CLOCKED-IN PROJECT
  static Future<void> removeClockedInProjectId(int projectId) async {
    final ids = await getClockedInProjectIds();

    ids.remove(projectId);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      clockedInProjectIdsKey,

      ids.map((e) => e.toString()).toList(),
    );
  }

  // 📥 GET ACCESS TOKEN
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  // 📥 GET REFRESH TOKEN
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  // 👤 SAVE USER EMAIL
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userEmailKey, email);
  }

  // 📥 GET USER EMAIL
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  static Future<void> setPasswordSet(String email, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizedEmail(email);
    await prefs.setBool("$_passwordSetPrefix$normalizedEmail", value);
    await prefs.setBool("$_firstLoginPrefix$normalizedEmail", !value);
  }

  static Future<bool> hasPasswordSetValue(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizedEmail(email);
    return prefs.containsKey("$_passwordSetPrefix$normalizedEmail") ||
        prefs.containsKey("$_firstLoginPrefix$normalizedEmail");
  }

  static Future<bool> isPasswordSet(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizedEmail(email);
    final storedValue = prefs.getBool("$_passwordSetPrefix$normalizedEmail");
    if (storedValue != null) {
      return storedValue;
    }

    final legacyFirstLogin = prefs.getBool(
      "$_firstLoginPrefix$normalizedEmail",
    );
    if (legacyFirstLogin != null) {
      return !legacyFirstLogin;
    }

    return false;
  }

  // 🔑 SET FIRST LOGIN FLAG
  static Future<void> setFirstLogin(String email, bool value) async {
    await setPasswordSet(email, !value);
  }

  // 📥 GET FIRST LOGIN FLAG
  static Future<bool> isFirstLogin(String email) async {
    return !(await isPasswordSet(email));
  }

  // 🧾 GET CLOCKED-IN PROJECT IDS
  static Future<Set<int>> getClockedInProjectIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(clockedInProjectIdsKey) ?? [];
    return raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  // ➕ ADD PROJECT TO CLOCKED-IN IDS
  static Future<void> addClockedInProjectId(int projectId) async {
    final ids = await getClockedInProjectIds();
    ids.add(projectId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      clockedInProjectIdsKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  // ✅ CHECK IF PROJECT CLOCKED-IN
  static Future<bool> isProjectClockedIn(int projectId) async {
    final ids = await getClockedInProjectIds();
    return ids.contains(projectId);
  }

  // 🚪 CLEAR ALL (LOGOUT)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(clockedInProjectIdsKey);
    await prefs.remove("clockInStartMillis");
    await prefs.setBool("isClockedIn", false);
    await prefs.remove("clockedInProjectId");
    await prefs.remove("clockSessionId");
    await prefs.remove("clockedInProjectName");
    await prefs.setBool("isLoggedIn", false);
  }
}
