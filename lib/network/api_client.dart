/// 🔄 REFRESH TOKEN

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:euroside/network/api_endpoint.dart';
import 'package:euroside/services/app_network_error_service.dart';
import 'package:euroside/services/session_logout_router.dart';
import 'package:euroside/services/token_services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _networkUnavailableMessage =
      'Unable to reach the server. Check your internet connection or try again later.';
  static const String _sessionExpiredMessage =
      'Your session expired. Please login again.';
  static const String _serverErrorLogoutMessage =
      'Server error occurred. Please login again.';

  static Exception _networkException() {
    return Exception(_networkUnavailableMessage);
  }

  /// ✅ COMMON HEADERS
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
  }) async {
    String? token = await TokenManager.getAccessToken();

    return {
      "Content-Type": "application/json",
      if (includeAuth && token != null) "Authorization": "Bearer $token",
    };
  }

  static bool _isNetworkIssue(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection timed out') ||
        error.toString().contains('Network error');
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await TokenManager.getRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.refreshToken),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refresh}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data["access"];
        if (newAccess != null) {
          await TokenManager.saveTokens(newAccess, refresh);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static void _redirectToLogin({required String message}) {
    unawaited(SessionLogoutRouter.routeToLogin(logoutMessage: message));
  }

  static Future<dynamic> get(
    String endpoint, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      debugPrint('📤 GET => ${ApiEndpoints.baseUrl + endpoint}');

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      debugPrint('❌ GET TIMEOUT => $e');
      AppNetworkErrorService.report(_networkUnavailableMessage);
      throw _networkException();
    } on Exception catch (e) {
      // Try refresh if token expired
      if (e.toString().contains('token_not_valid')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.get(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }

        _redirectToLogin(message: _sessionExpiredMessage);
        throw Exception(_sessionExpiredMessage);
      }
      if (_isNetworkIssue(e)) {
        debugPrint('❌ GET NETWORK ERROR => $e');
        AppNetworkErrorService.report(_networkUnavailableMessage);
      }
      throw _networkException();
    }
  }

  /// ✅ MULTIPART API (FOR FORM SUBMIT)
  static Future<dynamic> multipart(
    String endpoint, {
    required Map<String, String> fields,
    File? file,
    String? fileKey,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);

      final request = http.MultipartRequest("POST", uri);

      /// 🔥 ADD AUTH HEADER (IMPORTANT)
      String? token = await TokenManager.getAccessToken();
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      /// ❗ DO NOT ADD Content-Type manually
      /// MultipartRequest handles it automatically

      /// ✅ ADD FIELDS
      request.fields.addAll(fields);

      /// ✅ ADD FILE (OPTIONAL)
      if (file != null && fileKey != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileKey, file.path),
        );
      }

      /// 🚀 SEND REQUEST
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      print("❌ MULTIPART TIMEOUT ERROR: $e");
      AppNetworkErrorService.report(_networkUnavailableMessage);
      throw Exception(_networkUnavailableMessage);
    } on SocketException catch (e) {
      print("❌ MULTIPART SOCKET ERROR: $e");
      AppNetworkErrorService.report(_networkUnavailableMessage);
      throw Exception(_networkUnavailableMessage);
    } catch (e) {
      print("❌ MULTIPART ERROR: $e");
      // Preserve non-network errors (validation/backend messages)
      if (e.toString().contains('token_not_valid')) {
        _redirectToLogin(message: _sessionExpiredMessage);
      }
      rethrow;
    }
  }

  /// ✅ POST API
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(includeAuth: includeAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on Exception catch (e) {
      // Handle token refresh request specially
      if (e.toString().contains('token_not_valid')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.post(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(includeAuth: includeAuth),
            body: jsonEncode(body),
          );
          return _handleResponse(retryResponse);
        }

        _redirectToLogin(message: _sessionExpiredMessage);
        throw Exception(_sessionExpiredMessage);
      }

      // Network/timeouts -> convert to friendly network error
      if (e is SocketException ||
          e is TimeoutException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('Network error')) {
        AppNetworkErrorService.report(_networkUnavailableMessage);
        throw _networkException();
      }

      // Preserve other (backend/validation) errors so callers can inspect details
      rethrow;
    }
  }

  /// ✅ PUT API (for future use)
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on Exception catch (e) {
      if (e.toString().contains('token_not_valid')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.put(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          );
          return _handleResponse(retryResponse);
        }

        _redirectToLogin(message: _sessionExpiredMessage);
        throw Exception(_sessionExpiredMessage);
      }

      if (e is SocketException ||
          e is TimeoutException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('Network error')) {
        AppNetworkErrorService.report(_networkUnavailableMessage);
        throw _networkException();
      }

      rethrow;
    }
  }

  /// ✅ DELETE API
  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on Exception catch (e) {
      if (e.toString().contains('token_not_valid')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.delete(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }

        _redirectToLogin(message: _sessionExpiredMessage);
        throw Exception(_sessionExpiredMessage);
      }

      if (e is SocketException ||
          e is TimeoutException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('Network error')) {
        AppNetworkErrorService.report(_networkUnavailableMessage);
        throw _networkException();
      }

      rethrow;
    }
  }

  /// ✅ RESPONSE HANDLER (🔥 VERY IMPORTANT)
  static dynamic _handleResponse(http.Response response) {
    print("📡 STATUS CODE: ${response.statusCode}");
    print("📡 RESPONSE BODY: ${response.body}");

    final body = response.body.trim();
    final lowerBody = body.toLowerCase();
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';

    if (response.statusCode >= 500) {
      _redirectToLogin(message: _serverErrorLogoutMessage);
    }

    if (contentType.contains('text/html') ||
        lowerBody.startsWith('<!doctype html') ||
        lowerBody.startsWith('<html')) {
      AppNetworkErrorService.report('Unexpected HTML response from server.');
      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try later.');
      }
      throw Exception('Unexpected HTML response from server.');
    }

    dynamic data;
    try {
      data = body.isNotEmpty ? jsonDecode(body) : {};
    } on FormatException {
      if (response.statusCode >= 500) {
        throw Exception('Server error. Please try later.');
      }
      throw Exception('Invalid server response format.');
    }

    /// 🔐 TOKEN EXPIRED
    if (response.statusCode == 401 && data["code"] == "token_not_valid") {
      // Let the request methods handle refresh logic
      throw Exception("token_not_valid");
    }

    /// 🔐 UNAUTHORIZED (missing/invalid auth header)
    if (response.statusCode == 401) {
      final detail = data['detail']?.toString() ?? '';

      if (detail == 'Authentication credentials were not provided.') {
        _redirectToLogin(message: _sessionExpiredMessage);
      } else {
        unawaited(SessionLogoutRouter.routeToLoginFromAnotherDevice());
      }

      throw Exception(
        data["detail"] ?? "Authentication failed. Please login again.",
      );
    }

    /// ✅ SUCCESS
    if (response.statusCode == 200 || response.statusCode == 201) {
      AppNetworkErrorService.clear();
      return data;
    }

    /// ❌ VALIDATION ERROR (like your clock-in distance error)
    if (response.statusCode == 400) {
      String errorMessage = _extractErrorMessage(data);
      // Include the full response body in the exception for UI error parsing
      throw Exception('$errorMessage |BACKEND_JSON| ${response.body}');
    }

    /// ❌ CONFLICT (for example: account active on another device)
    if (response.statusCode == 409) {
      String errorMessage = _extractErrorMessage(data);
      throw Exception('$errorMessage |BACKEND_JSON| ${response.body}');
    }

    /// ❌ FORBIDDEN
    if (response.statusCode == 403) {
      throw Exception(data["detail"] ?? "You don't have permission.");
    }

    /// ❌ NOT FOUND
    if (response.statusCode == 404) {
      throw Exception("Resource not found.");
    }

    /// ❌ SERVER ERROR
    if (response.statusCode >= 500) {
      _redirectToLogin(message: _serverErrorLogoutMessage);
      throw Exception("Server error. Please try later.");
    }

    /// ❌ FALLBACK
    throw Exception(
      data["detail"] ??
          data["error"] ??
          data["message"] ??
          "Something went wrong",
    );
  }

  /// 🔥 EXTRACT ERROR MESSAGE FROM VARIOUS API RESPONSE FORMATS
  static String _extractErrorMessage(dynamic data) {
    // 📌 Handle non_field_errors (Django REST Framework)
    if (data is Map && data.containsKey("non_field_errors")) {
      final errors = data["non_field_errors"];
      if (errors is List && errors.isNotEmpty) {
        return errors[0].toString();
      }
    }

    // 📌 Handle field-specific errors (Django REST Framework)
    if (data is Map) {
      for (var key in data.keys) {
        if (key != "non_field_errors") {
          final value = data[key];
          if (value is List && value.isNotEmpty) {
            return value[0].toString();
          } else if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    }

    // 📌 Handle standard error fields
    if (data["detail"] != null) {
      return data["detail"].toString();
    }

    if (data["message"] != null) {
      return data["message"].toString();
    }

    if (data["error"] != null) {
      return data["error"].toString();
    }

    return "Invalid request. Please check input.";
  }
}
