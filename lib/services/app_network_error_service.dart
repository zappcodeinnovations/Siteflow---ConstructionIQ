import 'package:flutter/foundation.dart';

class AppNetworkErrorState {
  final String title;
  final String message;

  const AppNetworkErrorState({required this.title, required this.message});
}

class AppNetworkErrorService {
  static final ValueNotifier<AppNetworkErrorState?> notifier =
      ValueNotifier<AppNetworkErrorState?>(null);

  static void report(String message, {String title = 'Network unavailable'}) {
    notifier.value = AppNetworkErrorState(title: title, message: message);
  }

  static void clear() {
    notifier.value = null;
  }
}
