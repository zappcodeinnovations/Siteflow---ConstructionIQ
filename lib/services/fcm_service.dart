import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification == null) {
    await FcmService.showRemoteMessage(message);
  }
}

class FcmService {
  static const String _fcmTokenKey = 'fcm_token';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'euroside_updates',
        'Euro Side updates',
        description: 'Notifications and announcements from Euro Side',
        importance: Importance.high,
      );

  static final ValueNotifier<int> notificationTick = ValueNotifier<int>(0);
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsReady = false;

  /// Initialize Firebase and ensure an FCM token is obtained and persisted.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _ensureLocalNotifications();

      final messaging = FirebaseMessaging.instance;

      // On iOS request permission
      try {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
        );
      } catch (_) {}

      await _storeAndLogToken(await messaging.getToken());

      FirebaseMessaging.onMessage.listen((message) async {
        await showRemoteMessage(message);
        _broadcastNotificationEvent();
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _broadcastNotificationEvent();
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _broadcastNotificationEvent();
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _storeAndLogToken(newToken, isRefresh: true);
        // Optionally: notify backend about token change here.
      });
    } catch (e) {
      // Initialization errors shouldn't block app startup.
      // Keep silent but print for debug.
      // ignore: avoid_print
      print('[FcmService] init error: $e');
    }
  }

  static Future<String> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey) ?? '';
  }

  static Future<String> getCurrentToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      for (var attempt = 0; attempt < 5; attempt++) {
        final token = await messaging.getToken();
        if (token != null && token.trim().isNotEmpty) {
          await _storeAndLogToken(token);
          return token.trim();
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FcmService] getCurrentToken error: $e');
    }

    return getSavedToken();
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await _ensureLocalNotifications();

    final title = _messageTitle(message);
    final body = _messageBody(message);

    if (title.isEmpty && body.isEmpty) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Ensure the ID is a positive 32-bit integer for Android
    final int notificationId = (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;

    await _localNotifications.show(
      id: notificationId,
      title: title.isEmpty ? 'Euro Side' : title,
      body: body,
      notificationDetails: details,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  static Future<void> _ensureLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings: initializationSettings);

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(_androidChannel);
      await androidPlugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _localNotificationsReady = true;
  }

  static String _messageTitle(RemoteMessage message) {
    return (message.notification?.title ??
            message.data['title'] ??
            message.data['heading'] ??
            message.data['subject'] ??
            '')
        .toString()
        .trim();
  }

  static String _messageBody(RemoteMessage message) {
    return (message.notification?.body ??
            message.data['body'] ??
            message.data['message'] ??
            message.data['description'] ??
            '')
        .toString()
        .trim();
  }

  static void _broadcastNotificationEvent() {
    notificationTick.value = notificationTick.value + 1;
  }

  static Future<void> _storeAndLogToken(
    String? token, {
    bool isRefresh = false,
  }) async {
    if (token == null || token.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token.trim());
    final deviceId = prefs.getString('device_id') ?? '<not-set>';

    // ignore: avoid_print
    print(
      isRefresh
          ? '[FcmService] FCM token refreshed: $token'
          : '[FcmService] FCM token: $token',
    );
    // ignore: avoid_print
    print('[FcmService] Device ID: $deviceId');
  }
}
