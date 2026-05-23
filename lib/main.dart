import 'dart:io';

import 'package:euroside/modules/splash/splash_screen.dart';
import 'package:euroside/services/app_network_error_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// WEBVIEW INITIALIZATION
  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Euro Side',

      theme: ThemeData(
        useMaterial3: true,

        primaryColor: const Color(0xff2563EB),

        scaffoldBackgroundColor: const Color(0xffF4F7FB),

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563EB)),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xffF4F7FB),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xff0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xff0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xff2563EB),
        ),
      ),

      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            ValueListenableBuilder<AppNetworkErrorState?>(
              valueListenable: AppNetworkErrorService.notifier,
              builder: (context, error, _) {
                if (error == null) {
                  return const SizedBox.shrink();
                }

                return Positioned.fill(
                  child: Material(
                    color: Colors.black.withOpacity(0.28),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF1F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.wifi_off_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  error.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111318),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: AppNetworkErrorService.clear,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Dismiss',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
