import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:euroside/modules/Auth/provider/auth_provider.dart';
import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/profile_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? Center(
              child: Text(
                state.error ?? "No Data",
                style: GoogleFonts.inter(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// 🔷 HEADER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    // decoration: BoxDecoration(
                    //   color: Colors.white,
                    //   borderRadius: BorderRadius.circular(22),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.black.withOpacity(0.05),
                    //       blurRadius: 15,
                    //       offset: const Offset(0, 6),
                    //     ),
                    //   ],
                    // ),
                    child: Column(
                      children: [
                        /// Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.person, size: 40),
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Name
                        Text(
                          profile.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        /// Email
                        Text(
                          profile.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// 🔷 INFO SECTION TITLE
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Account Information",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔷 INFO CARD
                  Container(
                    // decoration: BoxDecoration(
                    //   color: Colors.white,
                    //   borderRadius: BorderRadius.circular(18),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.black.withOpacity(0.04),
                    //       blurRadius: 10,
                    //       offset: const Offset(0, 4),
                    //     ),
                    //   ],
                    // ),
                    child: Column(
                      children: [
                        _tile(
                          Icons.person_outline,
                          "Username",
                          profile.username,
                        ),
                        _divider(),
                        _tile(Icons.work_outline, "Role", profile.role),
                        _divider(),
                        _tile(
                          Icons.phone_outlined,
                          "Phone",
                          profile.phone ?? "Not Available",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔴 LOGOUT BUTTON (OPTIONAL BUT NICE)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoggingOut
                          ? null
                          : () async {
                              final prefs =
                                  await SharedPreferences.getInstance();

                              final isClockedIn =
                                  prefs.getBool("isClockedIn") ?? false;

                              /// 🚫 BLOCK LOGOUT
                              if (isClockedIn) {
                                if (!mounted) return;

                                Fluttertoast.showToast(
                                  msg:
                                      "Please clock out from your current project before logging out.",
                                  gravity: ToastGravity.TOP,
                                  toastLength: Toast.LENGTH_SHORT,
                                  backgroundColor: const Color(0xFF1F2937),
                                  textColor: Colors.white,
                                  fontSize: 14,
                                );

                                return;
                              }

                              /// ✅ ALLOW LOGOUT

                              setState(() {
                                isLoggingOut = true;
                              });

                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 1800),
                                  behavior: SnackBarBehavior.floating,
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  margin: const EdgeInsets.all(16),

                                  content: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),

                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(18),

                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
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
                                            color: Colors.green.withOpacity(
                                              .12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              Text(
                                                "Logout Successful",
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                "You have been securely logged out.",
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  height: 1.4,
                                                  color: Colors.white
                                                      .withOpacity(0.75),
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

                              await Future.delayed(
                                const Duration(milliseconds: 1200),
                              );

                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const SignInScreen(
                                    showLogoutMessage: true,
                                  ),
                                ),
                                (route) => false,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 76, 14, 221),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Logout",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🔹 TILE
  Widget _tile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.grey.shade700),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 🔹 DIVIDER
  Widget _divider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200);
  }
}
