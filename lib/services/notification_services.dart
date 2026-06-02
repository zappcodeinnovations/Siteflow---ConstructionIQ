import 'package:euroside/modules/notifications/model/app_notification_model.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_endpoint.dart';

class NotificationService {
  static Future<List<AppNotificationModel>> getNotifications() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.operativeNotifications);
      final items = _extractItems(response);

      return items.whereType<Map>().map((item) {
        return AppNotificationModel.fromJson(item.cast<String, dynamic>());
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ NOTIFICATIONS API ERROR: $e');
      debugPrint('📍 STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  static List<dynamic> _extractItems(dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List) return results;

      final data = response['data'];
      if (data is List) return data;

      final notifications = response['notifications'];
      if (notifications is List) return notifications;
    }

    return const [];
  }
}
