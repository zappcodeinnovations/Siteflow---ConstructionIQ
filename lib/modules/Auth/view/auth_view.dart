import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/set_password.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final bool showLogoutMessage;

  const SignInScreen({super.key, this.showLogoutMessage = false});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
      return "Network error. Please try again.";
    }

    if (normalizedError.contains("server error")) {
      return "Server error. Please try again later.";
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
            content: const Text("Logout successful"),
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
    final shouldSetPassword = await authController.login(email, password);
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    if (authState.error == null) {
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
                    'assets/logo/Euroside_Logo.png',
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

              // ── Remember me + Forgot password ─────────────────────────
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Row(
              //       children: [
              //         SizedBox(
              //           width: 20,
              //           height: 20,
              //           child: Checkbox(
              //             value: _rememberMe,
              //             onChanged: (v) =>
              //                 setState(() => _rememberMe = v ?? false),
              //             activeColor: _accentBlue,
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(4),
              //             ),
              //             side: const BorderSide(
              //               color: Color(0xFFCDD1DA),
              //               width: 1.5,
              //             ),
              //             materialTapTargetSize:
              //                 MaterialTapTargetSize.shrinkWrap,
              //           ),
              //         ),
              //         const SizedBox(width: 8),
              //         Text(
              //           'Remember me',
              //           style: GoogleFonts.inter(
              //             fontSize: 13,
              //             color: Colors.black54,
              //           ),
              //         ),
              //       ],
              //     ),
              //     GestureDetector(
              //       onTap: () {
              //         Navigator.of(context).push(
              //           MaterialPageRoute(
              //             builder: (_) => SetPasswordScreen(
              //               email: _emailController.text.trim(),
              //             ),
              //             // builder: (_) => NavigationScreen(),
              //           ),
              //         );
              //       },
              //       child: Text(
              //         'Forgot Password?',
              //         style: GoogleFonts.inter(
              //           fontSize: 13,
              //           fontWeight: FontWeight.w500,
              //           color: _accentBlue,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
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
