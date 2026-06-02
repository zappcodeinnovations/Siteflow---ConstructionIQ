import 'package:flutter/material.dart';
import 'package:euroside/network/api_endpoint.dart';

class DrawingConstants {
  static const List<String> statusOptions = ['completed', 'pending', 'issue'];

  static String normalizeDrawingFileUrl(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final relativePath = value.startsWith('/') ? value : '/$value';
    return Uri.parse(ApiEndpoints.baseUrl).resolve(relativePath).toString();
  }

  static bool isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }

    final normalized = url.toLowerCase().split('?').first;
    return normalized.endsWith('.pdf');
  }

  static Uri buildDrawingLocationsUri({
    int? projectId,
    int? levelId,
    String? status,
  }) {
    final queryParameters = <String, String>{};

    if (projectId != null) {
      queryParameters['project_id'] = projectId.toString();
    }

    if (levelId != null) {
      queryParameters['level_id'] = levelId.toString();
    }

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    return Uri.parse(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.drawingLocations}',
    ).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static Color statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'issue':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }

  static Color statusTint(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'completed':
        return const Color(0xFFEAF8EF);
      case 'pending':
        return const Color(0xFFFFF7E6);
      case 'issue':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFEFF4FF);
    }
  }

  static String titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '-';
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}
