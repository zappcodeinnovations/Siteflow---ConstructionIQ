import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/set_password.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:euroside/utils/google_fonts_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty || phone.isEmpty) {
      _showValidationMessage('Please fill all fields');
      return;
    }

    if (email.isEmpty) {
      _showValidationMessage('Please enter your email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showValidationMessage('Please enter a valid email address');
      return;
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showValidationMessage('Please enter your password');
      return;
    }

    if (password != confirmPassword) {
      _showValidationMessage('Passwords do not match');
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    
    final shouldSetPassword = await authController.register(
      email: email,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    if (!mounted) return;
    final authState = ref.read(authControllerProvider);

    if (authState.error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => shouldSetPassword
              ? SetPasswordScreen(email: email)
              : const NavigationScreen(),
        ),
        (route) => false,
      );
    }
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
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D1B3E)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.black38,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EBF0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8EBF0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final registerError = authState.error == null
        ? null
        : _friendlyLoginError(authState.error!);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D1B3E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Register',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D1B3E),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // ── Title & subtitle ──────────────────────────────────────
              Center(
                child: Text(
                  'Create an Account',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B3E),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Sign up for your Euroside enterprise\naccount to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('First Name*'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _firstNameController,
                          hintText: 'John',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Last Name*'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _lastNameController,
                          hintText: 'Doe',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Username*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hintText: 'johndoe123',
                prefixIcon: const Icon(Iconsax.user, size: 18, color: _accentBlue),
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Phone Number*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hintText: '9876543210',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Iconsax.call, size: 18, color: _accentBlue),
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Email*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Iconsax.sms, size: 18, color: _accentBlue),
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Iconsax.password_check, size: 18, color: _accentBlue),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                    size: 22,
                    color: _accentBlue,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Confirm Password*'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Iconsax.password_check, size: 18, color: _accentBlue),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  child: Icon(
                    _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                    size: 22,
                    color: _accentBlue,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Error ─────────────────────────────────────────────────
              if (registerError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.warning_2, color: Color(0xFFD32F2F), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          registerError,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFD32F2F),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── Register button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
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
                          'Register',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
}
