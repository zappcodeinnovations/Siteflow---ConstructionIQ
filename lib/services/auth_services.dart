import 'package:euroside/network/api_endpoint.dart';
import 'package:euroside/services/token_services.dart';

import '../network/api_client.dart';

class AuthService {
  // Operative Login
  static Future<Map<String, dynamic>> operativeLogin({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.operativeLogin, {
      "email": email,
      "password": password,
    });
    print('[AuthService][operativeLogin] Backend response: $response');

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
    final response = await ApiClient.post(ApiEndpoints.login, {
      "email": email,
      "password": password,
    });
    print('[AuthService][login] Backend response: $response');

    await TokenManager.saveTokens(response["access"], response["refresh"]);

    return response;
  }

  // Refresh Token
  static Future<String?> refreshAccessToken() async {
    final refreshToken = await TokenManager.getRefreshToken();

    if (refreshToken == null) return null;

    final response = await ApiClient.post(ApiEndpoints.refreshToken, {
      "refresh": refreshToken,
    });
    print('[AuthService][refreshAccessToken] Backend response: $response');

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
    print('[AuthService][setPassword] Backend response: $response');

    return response;
  }

  // Logout
  static Future<void> logout() async {
    await TokenManager.clearAll();
  }
}
