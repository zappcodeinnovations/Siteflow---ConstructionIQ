import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification_services.dart';
import '../model/app_notification_model.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotificationModel>>((ref) async {
      ref.keepAlive();
      return NotificationService.getNotifications();
    });
