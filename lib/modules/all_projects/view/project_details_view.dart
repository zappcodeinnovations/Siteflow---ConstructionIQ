import 'package:euroside/modules/Project_photos/view/project_camera_page.dart';
import 'package:euroside/modules/Team/view/team.dart';
import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/modules/all_projects/view/all_project_view.dart';
import 'package:euroside/modules/all_projects/view/project_location_view.dart';
import 'package:euroside/modules/announcements/view/announcement.dart';
import 'package:euroside/modules/clock_out/model/clock_out_model.dart';
import 'package:euroside/modules/clock_out/provider/clock_provider.dart';
import 'package:euroside/modules/form/view/form_screen.dart';
import 'package:euroside/modules/job/view/job_screen.dart';
import 'package:euroside/modules/project_dashboard/view/project_dashboard.dart';
import 'package:euroside/services/all_project_service.dart';
import 'package:euroside/services/token_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllProjectDetailsPage extends ConsumerStatefulWidget {
  final int projectId;
  final AllprojectModel initialProject;

  const AllProjectDetailsPage({
    super.key,
    required this.projectId,
    required this.initialProject,
  });

  @override
  @override
  ConsumerState<AllProjectDetailsPage> createState() =>
      _AllProjectDetailsPageState();
}

class _AllProjectDetailsPageState extends ConsumerState<AllProjectDetailsPage> {
  late final Future<AllprojectModel> _projectFuture;

  static const Color _bg = Color(0xffF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xff2563EB);
  static const Color _text = Color(0xff0F172A);
  static const Color _subText = Color(0xff64748B);
  bool _isClockingOut = false;

  @override
  void initState() {
    super.initState();
    _projectFuture = _loadProject();
  }

  Future<void> _clockOut(AllprojectModel project) async {
    try {
      setState(() {
        _isClockingOut = true;
      });

      /// LOCATION PERMISSION
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        setState(() {
          _isClockingOut = false;
        });
        return;
      }

      /// GET CURRENT LOCATION
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      /// CREATE MODEL
      final model = ClockOutModel(
        projectId: project.id,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: "Clocked out from project",
      );

      /// API CALL
      final result = await ref.read(clockOutProvider(model).future);

      if (result) {
        await TokenManager.removeClockedInProjectId(project.id);

        debugPrint("✅ PROJECT REMOVED FROM SESSION");

        /// STOP LOADER
        if (mounted) {
          setState(() {
            _isClockingOut = false;
          });
        }

        /// SUCCESS MESSAGE
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Successfully Clocked Out"),

              backgroundColor: Colors.green,
            ),
          );
        }

        /// VERY IMPORTANT
        /// REMOVE ALL PREVIOUS PAGES
        await Future.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AllProjectListPage()),
          (_) => false,
        );

        return;
      } else {
        /// FAILED
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Clock Out Failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isClockingOut = false;
        });
      }
      debugPrint("❌ CLOCK OUT ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      final error = e.toString();

      final lowerError = error.toLowerCase();

      debugPrint("🔥 BACKEND ERROR MESSAGE: $error");

      if (lowerError.contains("task") ||
          lowerError.contains("sheet") ||
          lowerError.contains("form") ||
          lowerError.contains("submit") ||
          lowerError.contains("required") ||
          lowerError.contains("fill")) {
        debugPrint("📋 TASK SHEET REQUIRED");

        _showFormRequiredDialog();

        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $error")));
    }
  }

  void _showFormRequiredDialog() {
    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                /// ICON
                Container(
                  width: 68,
                  height: 68,

                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7ED),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.assignment_rounded,

                    color: Color(0xffF97316),

                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                /// TITLE
                const Text(
                  "Task Sheet Required",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.w700,

                    color: Color(0xff0F172A),
                  ),
                ),

                const SizedBox(height: 10),

                /// MESSAGE
                const Text(
                  "Please fill and submit the task sheet before clocking out from this project.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 13,

                    height: 1.5,

                    color: Color(0xff64748B),
                  ),
                ),

                const SizedBox(height: 22),

                /// BUTTONS
                Row(
                  children: [
                    /// CANCEL
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,

                          side: BorderSide(color: Colors.grey.shade300),

                          padding: const EdgeInsets.symmetric(vertical: 13),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        onPressed: () {
                          Navigator.of(context).pop();
                        },

                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// FORM BUTTON
                    Expanded(
                      flex: 2,

                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          padding: const EdgeInsets.symmetric(vertical: 13),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        onPressed: () async {
                          Navigator.pop(context);

                          await Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) => const FormsScreen(),
                            ),
                          );
                        },

                        icon: const Icon(Icons.open_in_new, size: 18),

                        label: const Text(
                          "Fill Form",

                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<AllprojectModel> _loadProject() async {
    try {
      final response = await AllProjectService.getProjectDetails(
        widget.projectId,
      );

      final data = response['data'];

      if (data is Map<String, dynamic>) {
        return AllprojectModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("PROJECT DETAILS ERROR: $e");
    }

    return widget.initialProject;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        scrolledUnderElevation: 0,
        titleSpacing: 0,

        title: const Text(
          "Project Workspace",
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _isClockingOut
                  ? null
                  : () => _clockOut(widget.initialProject),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Row(
                  children: [
                    _isClockingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 18,
                          ),

                    const SizedBox(width: 8),

                    Text(
                      _isClockingOut ? "Clocking..." : "Clock Out",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<AllprojectModel>(
        future: _projectFuture,
        initialData: widget.initialProject,
        builder: (context, snapshot) {
          final project = snapshot.data ?? widget.initialProject;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),

                /// TOP PROJECT CARD
                _projectOverviewCard(project),

                const SizedBox(height: 24),

                _sectionTitle("Workspace", Iconsax.category),

                const SizedBox(height: 14),

                /// QUICK ACTIONS
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .95,
                  children: [
                    _actionCard(
                      icon: Iconsax.element_4,
                      title: "Dashboard",
                      color: const Color(0xff2563EB),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkspaceDashboardPage(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      icon: Iconsax.notification,
                      title: "Announcement",
                      color: const Color(0xffEA580C),

                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => AnnouncementPage(
                              projectId: project.id,

                              projectName: project.name,
                            ),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      icon: Iconsax.camera,
                      title: "Camera",
                      color: const Color(0xff7C3AED),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProjectCameraPage(),
                          ),
                        );
                      },
                    ),
                    // _actionCard(
                    //   icon: Iconsax.document_text,
                    //   title: "Worksheet",
                    //   color: const Color(0xff16A34A),

                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const WorksheetPage(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    _actionCard(
                      icon: Iconsax.briefcase,
                      title: "Jobs",
                      color: const Color(0xffDC2626),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                JobListScreen(projectId: project.id),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      icon: Iconsax.people,

                      title: "Team",

                      color: const Color(0xff2563EB),

                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => TeammatesPage(
                              projectId: project.id,

                              projectName: project.name,
                            ),
                          ),
                        );
                      },
                    ),
                    // _actionCard(
                    //   icon: Iconsax.note_1,
                    //   title: "Diary",
                    //   color: const Color(0xffDB2777),

                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (_) => const DiaryPage()),
                    //     );
                    //   },
                    // ),
                    _actionCard(
                      icon: Iconsax.clipboard_text,
                      title: "Forms",
                      color: const Color(0xff9333EA),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormsScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      icon: Iconsax.location,
                      title: "Location",
                      color: const Color(0xff059669),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectLocationPage(project: project),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _sectionTitle("Project Statistics", Iconsax.chart_21),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _statCard(
                      "Project Code",
                      project.code.isEmpty ? "-" : project.code,
                      Iconsax.code,
                    ),
                    _statCard(
                      "Progress",
                      "${project.progress}%",
                      Iconsax.activity,
                    ),
                    _statCard(
                      "Workers",
                      project.assignedWorkerCount.toString(),
                      Iconsax.profile_2user,
                    ),
                    _statCard(
                      "Jobs",
                      project.jobCount.toString(),
                      Iconsax.task,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _sectionTitle("Project Details", Iconsax.info_circle),

                const SizedBox(height: 14),

                _detailsCard(project),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _projectOverviewCard(AllprojectModel project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2563EB), Color(0xff1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            project.description.isEmpty
                ? "No project summary available"
                : project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(.85), height: 1.5),
          ),

          // const SizedBox(height: 20),

          // ClipRRect(
          //   borderRadius: BorderRadius.circular(30),
          //   child: LinearProgressIndicator(
          //     value: project.progress / 100,
          //     minHeight: 8,
          //     backgroundColor: Colors.white24,
          //     valueColor: const AlwaysStoppedAnimation(Colors.white),
          //   ),
          // ),

          // const SizedBox(height: 18),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     _topStat("Progress", "${project.progress}%"),
          //     _topStat("Workers", project.assignedWorkerCount.toString()),
          //     _topStat("Jobs", project.jobCount.toString()),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _topStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _subText),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _subText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _detailsCard(AllprojectModel project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _detailRow(Iconsax.user, "Client", _orDash(project.client?.name)),
          _detailRow(
            Iconsax.building,
            "Contractor",
            _orDash(project.contractor?.name),
          ),
          _detailRow(
            Iconsax.calendar,
            "Start Date",
            _orDash(project.startDate),
          ),
          _detailRow(Iconsax.calendar_1, "End Date", _orDash(project.endDate)),
          _detailRow(Iconsax.money, "Budget", _orDash(project.budget)),
          _detailRow(Iconsax.location, "Location", project.locationLabel),
          _detailRow(Iconsax.map, "Address", _orDash(project.siteAddress)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orDash(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }
}
