import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:euro_side/modules/Auth/provider/auth_provider.dart';
import 'package:euro_side/modules/Auth/view/auth_view.dart';
import '../provider/profile_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).getProfile(),
    );
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
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (!mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
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
