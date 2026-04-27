// Helper to navigate to login if session expired

import 'dart:async';
import 'package:euro_side/modules/Auth/view/auth_view.dart';
import 'package:euro_side/modules/clock_in/view/clock_in_screen.dart';
import 'package:euro_side/modules/job/view/job_screen.dart';
import 'package:euro_side/modules/profile/provider/profile_provider.dart';
import 'package:euro_side/modules/projects/provider/project_provider.dart';
import 'package:euro_side/modules/projects/view/project_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  static const String _clockedInKey = "isClockedIn";
  static const String _clockedInProjectIdKey = "clockedInProjectId";
  static const String _clockInStartMillisKey = "clockInStartMillis";

  Duration _shiftDuration = Duration.zero;
  Timer? _timer;
  bool _isClockedIn = false;
  static const Color _ink = Color(0xFF111318);
  static const Color _ink2 = Color(0xFF6B7280);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _accentLight = Color(0xFFEFF4FF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShiftState();
    _startTimer();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).getProfile(),
    );
  }

  void handleSessionExpired(BuildContext context, Object error) {
    final msg = error.toString();
    if (msg.contains('Session expired')) {
      // Remove all routes and go to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadShiftState();
    }
  }

  Future<void> _loadShiftState() async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool(_clockedInKey) ?? false;
    final startMillis = prefs.getInt(_clockInStartMillisKey);

    Duration duration = Duration.zero;
    if (isClockedIn && startMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - startMillis;
      duration = Duration(milliseconds: diff > 0 ? diff : 0);
    }

    if (!mounted) return;
    setState(() {
      _isClockedIn = isClockedIn;
      _shiftDuration = duration;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn) {
        setState(() {
          _shiftDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final h = _shiftDuration.inHours.toString().padLeft(2, '0');
    final m = (_shiftDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_shiftDuration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final userEmail = profileState.profile?.email ?? "User";
    final projectAsync = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: projectAsync.when(
          data: (projects) {
            int assigned = projects.length;
            int pending = projects.where((p) => p.status == "pending").length;
            int incomplete = projects
                .where((p) => p.status == "incomplete")
                .length;
            int completed = projects
                .where((p) => p.status == "completed")
                .length;
            final previewProjects = projects.take(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset("assets/logo/Euroside_Logo.png", height: 32),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.user,
                              size: 14,
                              color: _accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _ink2,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── TIMER CARD ───────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: _isClockedIn ? _accent : _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isClockedIn ? Colors.transparent : _border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isClockedIn
                              ? _accent.withOpacity(0.18)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isClockedIn
                                ? Colors.white.withOpacity(0.15)
                                : _bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isClockedIn ? Iconsax.clock : Iconsax.timer,
                            color: _isClockedIn ? Colors.white : _ink2,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isClockedIn
                                  ? "Shift Duration"
                                  : "Not Clocked In",
                              style: TextStyle(
                                fontSize: 12,
                                color: _isClockedIn
                                    ? Colors.white.withOpacity(0.75)
                                    : _ink2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isClockedIn ? _formattedTime : "--:--:--",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: _isClockedIn ? Colors.white : _ink,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── STATS SECTION TITLE ──────────────────────────────────
                  _sectionTitle("Project Stats", Iconsax.chart_1),

                  const SizedBox(height: 12),

                  // ── STATS GRID ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _statCard("Assigned", assigned, _StatStyle.blue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard("Pending", pending, _StatStyle.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          "Incomplete",
                          incomplete,
                          _StatStyle.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          "Completed",
                          completed,
                          _StatStyle.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── PROJECTS SECTION TITLE + SEE MORE ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle("Your Projects", Iconsax.briefcase),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProjectListScreen(),
                            ),
                          );
                          await _loadShiftState();
                        },
                        child: Row(
                          children: const [
                            Text(
                              "See all",
                              style: TextStyle(
                                fontSize: 13,
                                color: _accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Iconsax.arrow_right_1,
                              size: 14,
                              color: _accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── PROJECT LIST ─────────────────────────────────────────
                  if (previewProjects.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.folder_open,
                            size: 40,
                            color: _ink2.withOpacity(0.3),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "No projects assigned yet",
                            style: TextStyle(color: _ink2, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...previewProjects.map((p) {
                      final _StatusMeta meta = _statusMeta(p.status);

                      return GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final isClockedIn =
                              prefs.getBool(_clockedInKey) ?? false;
                          final clockedInProjectId = prefs.getInt(
                            _clockedInProjectIdKey,
                          );

                          if (isClockedIn && clockedInProjectId == p.id) {
                            if (!context.mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobListScreen(projectId: p.id),
                              ),
                            );
                          } else if (isClockedIn &&
                              clockedInProjectId != null &&
                              clockedInProjectId != p.id) {
                            if (!context.mounted) return;
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text(
                            //       'You already have an active clock-in on another project. Please clock out first.',
                            //     ),
                            //   ),
                            // );
                            Fluttertoast.showToast(
                              msg:
                                  'You already have an active clock-in on another project. Please clock out first.',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: Colors.redAccent,
                              textColor: Colors.white,
                              
                            );
                          } else {
                            if (!context.mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClockInScreen(
                                  projectId: p.id,
                                  projectName: p.name,
                                ),
                              ),
                            );
                          }
                          await _loadShiftState();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: meta.bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Iconsax.briefcase,
                                  size: 18,
                                  color: meta.fg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: meta.bg,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            p.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: meta.fg,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Iconsax.arrow_right,
                                size: 16,
                                color: _ink2,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          error: (e, _) {
            // Check for session expired and navigate
            handleSessionExpired(context, e);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.warning_2,
                      size: 40,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Something went wrong",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$e",
                      style: const TextStyle(fontSize: 12, color: _ink2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _ink2),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, int count, _StatStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(style.icon, size: 16, color: style.fg),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: style.fg,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _ink2,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case "completed":
        return _StatusMeta(
          bg: const Color(0xFFECFDF5),
          fg: const Color(0xFF059669),
        );
      case "pending":
        return _StatusMeta(
          bg: const Color(0xFFFFFBEB),
          fg: const Color(0xFFD97706),
        );
      case "incomplete":
        return _StatusMeta(
          bg: const Color(0xFFFEF2F2),
          fg: const Color(0xFFDC2626),
        );
      default:
        return _StatusMeta(bg: _accentLight, fg: _accent);
    }
  }
}

class _StatusMeta {
  final Color bg;
  final Color fg;
  const _StatusMeta({required this.bg, required this.fg});
}

class _StatStyle {
  final Color bg;
  final Color fg;
  final IconData icon;
  const _StatStyle({required this.bg, required this.fg, required this.icon});

  static final blue = _StatStyle(
    bg: const Color(0xFFEFF4FF),
    fg: const Color(0xFF2563EB),
    icon: Iconsax.briefcase,
  );
  static final amber = _StatStyle(
    bg: const Color(0xFFFFFBEB),
    fg: const Color(0xFFD97706),
    icon: Iconsax.clock,
  );
  static final red = _StatStyle(
    bg: const Color(0xFFFEF2F2),
    fg: const Color(0xFFDC2626),
    icon: Iconsax.close_circle,
  );
  static final green = _StatStyle(
    bg: const Color(0xFFECFDF5),
    fg: const Color(0xFF059669),
    icon: Iconsax.verify,
  );
}
