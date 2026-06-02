import 'dart:convert';
import 'dart:io';

import 'package:euroside/services/token_services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../modules/Project_photos/model/photos_model.dart';
import '../network/api_endpoint.dart';

class ProjectImageService {
  static String get _imageUrl =>
      "${ApiEndpoints.baseUrl}"
      "${ApiEndpoints.projectPhotos}";

  static const String _photoTimestampPrefix = "project_photo_captured_at_";

  static Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    DateTime? capturedAt,
  }) async {
    try {
      final token = await TokenManager.getAccessToken();

      final uri = Uri.parse(_imageUrl);

      debugPrint("📡 UPLOAD IMAGE URL: $uri");

      debugPrint("🔐 TOKEN: $token");

      /// REQUEST
      final request = http.MultipartRequest('POST', uri);

      /// HEADERS
      request.headers.addAll({
        "Authorization": "Bearer $token",

        "Accept": "application/json",
      });

      /// IMAGE FILE
      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );

      if (capturedAt != null) {
        request.fields["captured_at"] = capturedAt.toUtc().toIso8601String();
      }

      /// ======================================================
      /// ✅ PRINT IMAGE DETAILS
      /// ======================================================

      debugPrint("🖼️ IMAGE PATH: ${imageFile.path}");

      debugPrint(
        "🖼️ FILE NAME: "
        "${imageFile.path.split('/').last}",
      );

      debugPrint(
        "🖼️ FILE SIZE: "
        "${await imageFile.length()} bytes",
      );

      debugPrint("📡 REQUEST URL: $uri");

      debugPrint("🔐 ACCESS TOKEN: $token");

      debugPrint("📦 REQUEST FIELD: image");

      debugPrint("📤 SENDING IMAGE TO BACKEND...");

      /// SEND
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("📡 UPLOAD STATUS: ${response.statusCode}");

      debugPrint("📡 UPLOAD RESPONSE: ${response.body}");

      /// SUCCESS
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        await _cacheCapturedTimestamp(decoded, capturedAt);

        return decoded;
      }

      throw Exception("Failed to upload image");
    } catch (e, stackTrace) {
      debugPrint("❌ UPLOAD ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> uploadMultipleImages({
    required List<File> images,
    Map<String, DateTime?>? capturedAtByPath,
  }) async {
    try {
      List<Map<String, dynamic>> uploadedImages = [];

      for (final image in images) {
        final response = await uploadImage(
          imageFile: image,

          capturedAt: capturedAtByPath?[image.path],
        );

        uploadedImages.add(response);
      }

      return uploadedImages;
    } catch (e, stackTrace) {
      debugPrint("❌ MULTIPLE IMAGE ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }

  static Future<List<ProjectPhotoModel>> getUploadedImages() async {
    try {
      final token = await TokenManager.getAccessToken();

      final uri = Uri.parse(_imageUrl);

      debugPrint("📡 GET IMAGE URL: $uri");

      debugPrint("🔐 TOKEN: $token");

      final response = await http.get(
        uri,

        headers: {
          "Authorization": "Bearer $token",

          "Accept": "application/json",
        },
      );

      debugPrint("📡 GET STATUS: ${response.statusCode}");

      debugPrint("📡 GET RESPONSE: ${response.body}");

      /// SUCCESS
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List results = decoded["results"] ?? [];

        final photos = <ProjectPhotoModel>[];

        for (final item in results) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final cachedCreatedAt = await _getCachedCapturedTimestamp(item);

          photos.add(
            ProjectPhotoModel.fromJson(
              item,

              overrideCreatedAt: cachedCreatedAt,
            ),
          );
        }

        return photos;
      }

      /// UNAUTHORIZED
      if (response.statusCode == 401) {
        throw Exception("Unauthorized. Please login again.");
      }

      throw Exception("Failed to fetch images");
    } catch (e, stackTrace) {
      debugPrint("❌ GET IMAGE ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }

  static Future<bool> deleteImage(int imageId) async {
    try {
      final token = await TokenManager.getAccessToken();

      final uri = Uri.parse("$_imageUrl$imageId/");

      debugPrint("📡 DELETE IMAGE URL: $uri");

      debugPrint("🔐 TOKEN: $token");

      final response = await http.delete(
        uri,

        headers: {
          "Authorization": "Bearer $token",

          "Accept": "application/json",
        },
      );

      debugPrint("📡 DELETE STATUS: ${response.statusCode}");

      debugPrint("📡 DELETE RESPONSE: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      debugPrint("❌ DELETE ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      rethrow;
    }
  }

  static Future<void> _cacheCapturedTimestamp(
    dynamic responseData,
    DateTime? capturedAt,
  ) async {
    if (capturedAt == null || responseData is! Map<String, dynamic>) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedValue = capturedAt.toUtc().toIso8601String();

    final id = responseData["id"];
    if (id != null) {
      await prefs.setString("$_photoTimestampPrefix$id", storedValue);
    }

    final imageUrl = responseData["image_url"];
    if (imageUrl != null) {
      await prefs.setString("$_photoTimestampPrefix$imageUrl", storedValue);
    }
  }

  static Future<DateTime?> _getCachedCapturedTimestamp(
    Map<String, dynamic> photo,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final id = photo["id"];
    if (id != null) {
      final cachedById = prefs.getString("$_photoTimestampPrefix$id");
      if (cachedById != null) {
        return DateTime.tryParse(cachedById);
      }
    }

    final imageUrl = photo["image_url"];
    if (imageUrl != null) {
      final cachedByUrl = prefs.getString("$_photoTimestampPrefix$imageUrl");
      if (cachedByUrl != null) {
        return DateTime.tryParse(cachedByUrl);
      }
    }

    return null;
  }
}
