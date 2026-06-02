import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:euroside/network/api_endpoint.dart';
import 'package:euroside/services/token_services.dart';
import 'package:http/http.dart' as http;
import '../modules/drawing/model/drawing_model.dart';
import '../modules/drawing/utils/drawing_constants.dart';

class DrawingService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  DrawingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<DrawingModel>> fetchDrawingLocations({
    int? projectId,
    int? levelId,
    String? status,
  }) async {
    final uri = DrawingConstants.buildDrawingLocationsUri(
      projectId: projectId,
      levelId: levelId,
      status: status,
    );

    final response = await _sendRequest(uri);

    return _parseResponse(response);
  }

  Future<http.Response> _sendRequest(Uri uri) async {
    final token = await TokenManager.getAccessToken();

    http.Response response;

    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Request timed out while loading drawings.');
    } on SocketException {
      throw Exception('Unable to reach server. Check internet connection.');
    }

    // Handle token expiry
    if (response.statusCode == 401) {
      final body = response.body.trim();
      final isTokenExpired = body.contains('token_not_valid');

      if (isTokenExpired) {
        final refreshed = await _refreshAccessToken();

        if (refreshed) {
          final newToken = await TokenManager.getAccessToken();

          try {
            response = await _client
                .get(
                  uri,
                  headers: {
                    'Accept': 'application/json',
                    if (newToken != null && newToken.isNotEmpty)
                      'Authorization': 'Bearer $newToken',
                  },
                )
                .timeout(_requestTimeout);
          } on TimeoutException {
            throw Exception('Request timed out while loading drawings.');
          } on SocketException {
            throw Exception('Unable to reach server. Check internet connection.');
          }
        } else {
          throw Exception('Session expired. Please login again.');
        }
      }
    }

    return response;
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await TokenManager.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
            ),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refresh': refreshToken,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final accessToken = decoded['access']?.toString();

        if (accessToken != null && accessToken.isNotEmpty) {
          await TokenManager.saveTokens(
            accessToken,
            refreshToken,
          );

          return true;
        }
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  List<DrawingModel> _parseResponse(http.Response response) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to load drawings (HTTP ${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => DrawingModel.fromJson(json))
          .toList();
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid drawing response format');
    }

    final success = decoded['status'];

    if (success is bool && !success) {
      throw Exception(
        decoded['message']?.toString() ??
            'Unable to load drawings',
      );
    }

    final dynamic rawData = decoded['data'];
    final dynamic rawResults = decoded['results'];

    List<dynamic> items = [];

    // Handle API response safely
    if (rawData is List) {
      items = List<dynamic>.from(rawData);
    } else if (rawResults is List) {
      items = List<dynamic>.from(rawResults);
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => DrawingModel.fromJson(json),
        )
        .toList();
  }
}
