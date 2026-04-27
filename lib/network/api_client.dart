/// 🔄 REFRESH TOKEN

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:euro_side/network/api_endpoint.dart';
import 'package:euro_side/services/token_services.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  /// ✅ COMMON HEADERS
  static Future<Map<String, String>> _getHeaders() async {
    String? token = await TokenManager.getAccessToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
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

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
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
      }
      rethrow;
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
      throw Exception("Request timed out. Please try again.");
    } on SocketException catch (e) {
      print("❌ MULTIPART SOCKET ERROR: $e");
      throw Exception("Network error. Please try again.");
    } catch (e) {
      print("❌ MULTIPART ERROR: $e");
      rethrow;
    }
  }

  /// ✅ POST API
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
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
          final retryResponse = await http.post(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          );
          return _handleResponse(retryResponse);
        }
      }
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
      }
      rethrow;
    }
  }

  /// ✅ RESPONSE HANDLER (🔥 VERY IMPORTANT)
  static dynamic _handleResponse(http.Response response) {
    print("📡 STATUS CODE: ${response.statusCode}");
    print("📡 RESPONSE BODY: ${response.body}");

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    /// 🔐 TOKEN EXPIRED
    if (response.statusCode == 401 && data["code"] == "token_not_valid") {
      // Let the request methods handle refresh logic
      throw Exception("token_not_valid");
    }

    /// 🔐 UNAUTHORIZED (missing/invalid auth header)
    if (response.statusCode == 401) {
      TokenManager.clearAll();
      throw Exception(
        data["detail"] ?? "Authentication failed. Please login again.",
      );
    }

    /// ✅ SUCCESS
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    /// ❌ VALIDATION ERROR (like your clock-in distance error)
    if (response.statusCode == 400) {
      String errorMessage = _extractErrorMessage(data);
      // Include the full response body in the exception for UI error parsing
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
