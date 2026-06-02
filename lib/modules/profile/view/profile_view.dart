import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/utils/google_fonts_fallback.dart';
import 'package:euroside/utils/user_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:euroside/services/session_logout_router.dart';
import '../model/profile_model.dart';
import '../provider/profile_provider.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const bg = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF3F4F6);
  static const textPrimary = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const textLabel = Color(0xFF9CA3AF);
  static const accent = Color(0xFF4F46E5);
  static const accentBg = Color(0xFFEEF2FF);
  static const accentBorder = Color(0xFFE0E7FF);
  static const redText = Color(0xFFDC2626);
  static const redBorder = Color(0xFFFCA5A5);
  static const redBg = Color(0xFFFFF7F7);
  static const badgeBg = Color(0xFFF3F4F6);
  static const badgeText = Color(0xFF374151);
}

// ─────────────────────────────────────────────
//  PROFILE VIEW
// ─────────────────────────────────────────────
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(profileControllerProvider.notifier).getProfile();
      await ref.read(profileControllerProvider.notifier).checkLocationStatus();
    });
  }

  // ── helpers ──────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _or(String v, [String fallback = '—']) => v.isNotEmpty ? v : fallback;

  // ── logout logic (unchanged) ─────────────────
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool('isClockedIn') ?? false;

    if (isClockedIn) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: 'Please clock out from your current project before logging out.',
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: const Color(0xFF1F2937),
        textColor: Colors.white,
        fontSize: 14,
      );
      return;
    }

    setState(() => isLoggingOut = true);

    final messenger = SessionLogoutRouter.scaffoldMessengerKey.currentState;
    final navigator = SessionLogoutRouter.navigatorKey.currentState;

    if (messenger == null || navigator == null) {
      if (!mounted) return;
      setState(() => isLoggingOut = false);
      return;
    }

    await ref.read(authControllerProvider.notifier).logout();
    resetUserSessionCache(ref);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Logout Successful',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have been securely logged out.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SignInScreen(showLogoutMessage: true),
      ),
      (route) => false,
    );
  }

  // ── build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F2)),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? Center(
              child: Text(
                state.error ?? 'No Data',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── HEADER ──────────────────────────
                    _buildHeader(profile),

                    const SizedBox(height: 32),

                    // ── SECTION LABEL ────────────────────
                    _SectionLabel(label: 'Account Information'),

                    const SizedBox(height: 10),

                    // ── INFO CARD ────────────────────────
                    _buildInfoCard(profile),

                    const SizedBox(height: 32),

                    // ── LOGOUT ───────────────────────────
                    _buildLogoutButton(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ── header widget ─────────────────────────────
  Widget _buildHeader(ProfileModel profile) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _C.accentBg,
            shape: BoxShape.circle,
            border: Border.all(color: _C.accentBorder, width: 2),
          ),
          child: Center(
            child: Text(
              _initials(profile.fullName),
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: _C.accent,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Full name
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
            height: 1.25,
          ),
        ),

        const SizedBox(height: 5),

        // Email
        Text(
          profile.email,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 13, color: _C.textMuted),
        ),

        const SizedBox(height: 14),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _C.badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            profile.role,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.badgeText,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ── info card ─────────────────────────────────
  Widget _buildInfoCard(ProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: profile.username,
          ),
          _InfoRow(
            icon: Icons.work_outline_rounded,
            label: 'Role',
            value: profile.role,
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Employee ID',
            value: _or(profile.employeeId, 'Not Available'),
          ),
          _InfoRow(
            icon: Icons.account_circle_outlined,
            label: 'First Name',
            value: _or(profile.firstName, 'Not Available'),
          ),
          _InfoRow(
            icon: Icons.account_circle_outlined,
            label: 'Last Name',
            value: _or(profile.lastName, 'Not Available'),
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phone ?? 'Not Available',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── logout button ─────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoggingOut ? null : _handleLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.redText,
          side: const BorderSide(color: _C.redBorder, width: 1.2),
          backgroundColor: isLoggingOut ? _C.badgeBg : _C.redBg,
          disabledForegroundColor: _C.textLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.textLabel,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

/// Section heading — small all-caps label
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _C.textLabel,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Single row inside the info card
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _C.textLabel),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _C.textLabel,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _C.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, indent: 48, color: _C.divider),
      ],
    );
  }
}
