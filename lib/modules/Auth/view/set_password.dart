import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/services/token_services.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:euroside/utils/google_fonts_fallback.dart';
import 'package:euroside/utils/user_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isForgotPassword;

  const SetPasswordScreen({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _accentBlue = Color(0xFF003DA5);
  static const Color _pageBg = Color(0xFFF5F6FA);

  Future<void> _goToLogin() async {
    ref.read(authControllerProvider.notifier).clearMessages();
    await TokenManager.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).clearMessages();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    print("🧪 [SET PASSWORD TEST] Button tapped for email=${widget.email}");

    if (widget.isForgotPassword) {
      final accessToken = await TokenManager.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _showSnack('Please sign in first to change your password.');
        return;
      }
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnack("Please fill in all fields");
      return;
    }
    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }
    if (password != confirmPassword) {
      _showSnack("Passwords do not match");
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .setPassword(widget.email, password, confirmPassword);

    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    print(
      "🧪 [SET PASSWORD TEST] Completed for email=${widget.email} "
      "success=$success error=${state.error}",
    );

    if (state.error != null) {
      _showSnack(_friendlySetPasswordError(state.error!));
      return;
    }
    if (success) {
      if (widget.isForgotPassword) {
        _goToLogin();
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const NavigationScreen()),
          (route) => false,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            resetUserSessionCache(ref);
          }
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFF0D1B3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _friendlySetPasswordError(String error) {
    final cleanedError = error
        .split('|BACKEND_JSON|')
        .first
        .trim()
        .toLowerCase();

    if (cleanedError.contains('password and confirm password must match') ||
        cleanedError.contains('passwords do not match') ||
        cleanedError.contains('confirm password does not match')) {
      return 'Passwords do not match.';
    }

    if (cleanedError.contains('password') &&
        cleanedError.contains('at least') &&
        cleanedError.contains('character')) {
      return 'Password must be at least 6 characters.';
    }

    if (cleanedError.contains('required')) {
      return 'Please fill in all required fields.';
    }

    if (cleanedError.contains('too common')) {
      return 'This password is too common. Please try a different one.';
    }

    if (cleanedError.contains('entirely numeric')) {
      return 'This password is entirely numeric. Please include letters.';
    }

    if (cleanedError.contains('too similar')) {
      return 'This password is too similar to your email or username. Please choose a different one.';
    }

    if (cleanedError.contains('network error') ||
        cleanedError.contains('socketexception') ||
        cleanedError.contains('failed host lookup')) {
      return 'Network error. Please try again.';
    }

    if (cleanedError.contains('server error') ||
        cleanedError.contains('500') ||
        cleanedError.contains('502') ||
        cleanedError.contains('503')) {
      return 'Server error. Please try again later.';
    }

    return 'Unable to Reset password. Please try again.';
  }

  String _strengthLabel(String pw) {
    if (pw.length < 6) return 'Weak';
    if (pw.length < 10) return 'Fair';
    return 'Strong';
  }

  Color _strengthColor(String pw) {
    if (pw.length < 6) return const Color(0xFFD32F2F);
    if (pw.length < 10) return const Color(0xFFF59E0B);
    return const Color(0xFF1A6B3C);
  }

  int _strengthLevel(String pw) {
    if (pw.length < 6) return 1;
    if (pw.length < 10) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final pw = _passwordController.text;
    final cpw = _confirmPasswordController.text;
    final passwordError = authState.error == null
        ? null
        : _friendlySetPasswordError(authState.error!);

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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _goToLogin,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EBF0)),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF0D1B3E),
                      size: 22,
                    ),
                  ),
                ),
              ),

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

              const SizedBox(height: 16),

              // ── Title & subtitle ──────────────────────────────────────
              Center(
                child: Text(
                  widget.isForgotPassword ? 'Reset Password' : 'Set Password',
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
                  widget.isForgotPassword
                      ? 'Update your password to keep your\nEuroside enterprise account secure'
                      : 'Create a secure password for your\nEuroside enterprise account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black45,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Password ──────────────────────────────────────────────
              _fieldLabel('Enter Your Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE), // light blue bg
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.password_check,
                      size: 18,
                      color: const Color.fromARGB(255, 39, 6, 226),
                    ),
                  ),
                ),
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: const Color.fromARGB(255, 39, 6, 226),
                  ),
                ),
              ),

              // ── Strength bar ──────────────────────────────────────────
              if (pw.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: List.generate(3, (i) {
                    final active = i < _strengthLevel(pw);
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: active
                              ? _strengthColor(pw)
                              : const Color(0xFFE0E4EA),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password strength',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      _strengthLabel(pw),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _strengthColor(pw),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 18),

              // ── Confirm Password ──────────────────────────────────────
              _fieldLabel('Confirm Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                obscureText: _obscureConfirmPassword,
                onChanged: (_) => setState(() {}),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE), // light blue bg
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.password_check,
                      size: 18,
                      color: const Color.fromARGB(255, 39, 6, 226),
                    ),
                  ),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  child: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: const Color.fromARGB(255, 39, 6, 226),
                  ),
                ),
              ),

              // ── Match hint ────────────────────────────────────────────
              if (cpw.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pw == cpw ? 'Passwords match' : 'Passwords do not match',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: pw == cpw
                        ? const Color(0xFF1A6B3C)
                        : const Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 14),
              ] else
                const SizedBox(height: 4),

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
              if (passwordError != null) ...[
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
                              'Error',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              passwordError,
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
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

              // ── Submit ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _setPassword,
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
                          widget.isForgotPassword
                              ? 'Reset Password'
                              : 'Set Password',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: _goToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                      children: [
                        const TextSpan(text: 'Already have a password? '),
                        TextSpan(
                          text: 'Login',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF0D1B3E),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D1B3E)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
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
