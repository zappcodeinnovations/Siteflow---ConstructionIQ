import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/modules/Auth/view/set_password.dart';
import 'package:euroside/network/app_start_controller.dart';
import 'package:euroside/network/app_start_provider.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _float;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _float = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

    Future.microtask(() {
      ref.read(appStartProvider.notifier).initializeApp();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStartProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasNavigated || !mounted) return;

      if (appState == AppStartStatus.unauthenticated) {
        _hasNavigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      } else if (appState == AppStartStatus.firstTimeUser) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString("user_email") ?? "";
        _hasNavigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SetPasswordScreen(email: email)),
        );
      } else if (appState == AppStartStatus.authenticated) {
        _hasNavigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavigationScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white, // clean minimal background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(0, _float.value),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(scale: _scale, child: child),
              ),
            );
          },
          child: Container(
            width: 120,
            height: 120,
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(20),
            //   // boxShadow: [
            //   //   BoxShadow(
            //   //     color: Colors.black.withOpacity(0.1),
            //   //     blurRadius: 12,
            //   //     offset: const Offset(0, 6),
            //   //   ),
            //   // ],
            // ),
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo/Euroside_Logo.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
