import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/forgot_password_view.dart';
import 'package:euroside/modules/Auth/view/set_password.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:euroside/utils/google_fonts_fallback.dart';
import 'package:euroside/utils/user_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final bool showLogoutMessage;
  final String? logoutMessage;

  const SignInScreen({
    super.key,
    this.showLogoutMessage = false,
    this.logoutMessage,
  });

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _sessionWarningDialogShown = false;

  static const Color _accentBlue = Color(0xFF003DA5);
  static const Color _pageBg = Color(0xFFF5F6FA);

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _showValidationMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFF0D1B3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _showSingleDeviceSessionDialog(
    String message,
    Map<String, dynamic>? data,
  ) async {
    if (!mounted) return false;

    bool shouldRetryLogin = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isProcessing = false;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Iconsax.warning_2,
                    color: Color(0xFFF59E0B),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Active Session Detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can log out the other device and continue here.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      setModalState(() => isProcessing = true);
                                      final email = _emailController.text
                                          .trim();
                                      final ok = await ref
                                          .read(authControllerProvider.notifier)
                                          .logoutOtherDevice(email);
                                      if (!mounted || !dialogContext.mounted) {
                                        return;
                                      }
                                      setModalState(() => isProcessing = false);
                                      if (ok) {
                                        shouldRetryLogin = true;
                                        Navigator.of(dialogContext).pop();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Logout Other Device',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldRetryLogin;
  }

  void _openForgotPasswordScreen() {
    final email = _emailController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: email),
      ),
    );
  }

  String _friendlyLoginError(String error) {
    final cleanedError = error.split('|BACKEND_JSON|').first.trim();
    final normalizedError = cleanedError.toLowerCase();

    if (normalizedError.contains("invalid credentials") ||
        normalizedError.contains(
          "unable to log in with provided credentials",
        ) ||
        normalizedError.contains(
          "no active account found with the given credentials",
        )) {
      return "Invalid email or password.";
    }

    if (normalizedError.contains("network error")) {
      return "Unable to reach the server. Check your internet connection or try again later.";
    }

    if (normalizedError.contains("server error")) {
      return "Server error. Please try again later.";
    }

    if (normalizedError.contains("failed host lookup") ||
        normalizedError.contains("no address associated with hostname") ||
        normalizedError.contains("socketexception")) {
      return "Unable to reach the server. Check your internet connection or try again later.";
    }

    return cleanedError;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).clearMessages();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showLogoutMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(widget.logoutMessage ?? "Logout successful"),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _sessionWarningDialogShown = false;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showValidationMessage('Please enter your email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showValidationMessage('Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showValidationMessage('Please enter your password');
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    print("🧪 [LOGIN TEST] Login button tapped for email=$email");

    final shouldSetPassword = await authController.login(email, password);
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);

    if (authState.sessionWarningMessage != null &&
        !_sessionWarningDialogShown) {
      _sessionWarningDialogShown = true;
      final retryLogin = await _showSingleDeviceSessionDialog(
        authState.sessionWarningMessage!,
        authState.sessionWarningData,
      );
      if (!mounted) return;

      if (!retryLogin) {
        return;
      }

      final retryShouldSetPassword = await authController.login(
        email,
        password,
      );
      if (!mounted) return;
      final retryState = ref.read(authControllerProvider);
      if (retryState.error != null) {
        return;
      }
      if (retryState.sessionWarningMessage != null) {
        _showValidationMessage(retryState.sessionWarningMessage!);
        return;
      }

      resetUserSessionCache(ref);

      print(
        "🧪 [LOGIN TEST] Retry login route for email=$email "
        "setPassword=$retryShouldSetPassword",
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => retryShouldSetPassword
              ? SetPasswordScreen(email: email)
              : const NavigationScreen(),
        ),
      );
      return;
    }

    if (authState.error == null) {
      resetUserSessionCache(ref);

      print(
        "🧪 [LOGIN TEST] Login route for email=$email "
        "setPassword=$shouldSetPassword",
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => shouldSetPassword
              ? SetPasswordScreen(email: email)
              : const NavigationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loginError = authState.error == null
        ? null
        : _friendlyLoginError(authState.error!);

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Back button ───────────────────────────────────────────
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(10),
              //     border: Border.all(color: const Color(0xFFE8EBF0), width: 1),
              //   ),
              //   child: const Icon(
              //     Icons.chevron_left_rounded,
              //     color: Color(0xFF0D1B3E),
              //     size: 22,
              //   ),
              // ),
              const SizedBox(height: 20),

              // ── Logo ──────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    // color: _accentBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/logo/2.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Title & subtitle ──────────────────────────────────────
              Center(
                child: Text(
                  'Login',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B3E),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Login to your Euroside enterprise\naccount to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Email ─────────────────────────────────────────────────
              _buildFieldLabel('Email*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE), // light background
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Iconsax.sms,
                      size: 18,
                      color: const Color.fromARGB(255, 39, 6, 226),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Password ──────────────────────────────────────────────
              _buildFieldLabel('Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: _obscurePassword,

                // 🔥 CUSTOM PREFIX ICON
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE), // light blue bg
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.password_check,
                      size: 18,
                      color: const Color.fromARGB(255, 39, 6, 226),
                    ),
                  ),
                ),

                // 🔥 CUSTOM SUFFIX ICON
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Container(
                      width: 30,
                      height: 30,
                      // decoration: BoxDecoration(
                      //   color: Colors.grey.shade100,
                      //   borderRadius: BorderRadius.circular(14),
                      // ),
                      child: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        size: 22,
                        color: const Color.fromARGB(255, 39, 6, 226),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openForgotPasswordScreen,
                  style: TextButton.styleFrom(
                    foregroundColor: _accentBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accentBlue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Success Message ────────────────────────────────────────
              if (authState.successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.verify,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Success',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authState.successMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF2E7D32),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Error ─────────────────────────────────────────────────
              if (loginError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Iconsax.warning_2,
                          color: Color(0xFFD32F2F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login Failed',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loginError,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFD32F2F),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── Sign In button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accentBlue.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Don't have account ────────────────────────────────────
              // Center(
              //   child: RichText(
              //     text: TextSpan(
              //       style: GoogleFonts.inter(
              //         fontSize: 13,
              //         color: Colors.black45,
              //       ),
              //       children: [
              //         const TextSpan(text: "Don't have an account? "),
              //         WidgetSpan(
              //           child: GestureDetector(
              //             onTap: () {
              //               /* navigate to register */
              //             },
              //             child: Text(
              //               'Sign up',
              //               style: GoogleFonts.inter(
              //                 fontSize: 13,
              //                 fontWeight: FontWeight.w600,
              //                 color: _accentBlue,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0D1B3E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E4EA), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D1B3E)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
