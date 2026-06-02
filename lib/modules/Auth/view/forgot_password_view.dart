import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/utils/google_fonts_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _step = 1;

  static const Color _accentBlue = Color(0xFF003DA5);
  static const Color _pageBg = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).clearMessages();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    return emailRegex.hasMatch(email);
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

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('Please enter your email');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(email);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (!success) {
      _showSnack(_friendlyError(authState.error ?? 'Unable to send OTP.'));
      return;
    }

    setState(() => _step = 2);
    _showSnack(authState.successMessage ?? 'OTP sent successfully.');
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack('Please enter the OTP');
      return;
    }
    if (otp.length < 4) {
      _showSnack('Please enter a valid OTP');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email, otp);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (!success) {
      _showSnack(_friendlyError(authState.error ?? 'Unable to verify OTP.'));
      return;
    }

    setState(() => _step = 3);
    _showSnack(authState.successMessage ?? 'OTP verified successfully.');
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    if (newPassword.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPasswordWithOtp(email, otp, newPassword, confirmPassword);

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (!success) {
      _showSnack(
        _friendlyError(authState.error ?? 'Unable to reset your password.'),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            authState.successMessage ??
                'Password reset successful. Please login.',
          ),
        ),
      );
    });
  }

  String _friendlyError(String error) {
    final cleanedError = error.split('|BACKEND_JSON|').first.trim();
    final normalized = cleanedError.toLowerCase();

    if ((normalized.contains('invalid') || normalized.contains('incorrect')) &&
        normalized.contains('otp')) {
      return 'Invalid OTP. Please try again.';
    }

    if (normalized.contains('expired') && normalized.contains('otp')) {
      return 'OTP has expired. Please request a new OTP.';
    }

    if (normalized.contains('network error') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup')) {
      return 'Network error. Please try again.';
    }

    if (normalized.contains('server error')) {
      return 'Server error. Please try again later.';
    }

    return cleanedError;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0D1B3E),
        title: Text(
          'Forgot Password',
          style: GoogleFonts.inter(
            color: const Color(0xFF0D1B3E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 1
                  ? 'Step 1 of 3: Send OTP'
                  : _step == 2
                  ? 'Step 2 of 3: Verify OTP'
                  : 'Step 3 of 3: Reset Password',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _accentBlue,
              ),
            ),
            const SizedBox(height: 14),

            _buildFieldLabel('Email*'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              enabled: _step == 1,
            ),

            if (_step >= 2) ...[
              const SizedBox(height: 18),
              _buildFieldLabel('OTP*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _otpController,
                hintText: 'Enter OTP',
                keyboardType: TextInputType.number,
                enabled: _step >= 2,
              ),
            ],

            if (_step == 3) ...[
              const SizedBox(height: 18),
              _buildFieldLabel('New Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _newPasswordController,
                hintText: '••••••••',
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _accentBlue,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Confirm Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _accentBlue,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : (_step == 1
                          ? _sendOtp
                          : _step == 2
                          ? _verifyOtp
                          : _resetPassword),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accentBlue.withOpacity(0.6),
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
                        _step == 1
                            ? 'Send OTP'
                            : _step == 2
                            ? 'Verify OTP'
                            : 'Reset Password',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            if (_step == 2) ...[
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: authState.isLoading ? null : _sendOtp,
                  child: Text(
                    'Resend OTP',
                    style: GoogleFonts.inter(
                      color: _accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
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
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E4EA), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D1B3E)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.black38),
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
