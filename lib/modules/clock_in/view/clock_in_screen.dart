import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/modules/all_projects/provider/all_project_provider.dart';
import 'package:euroside/modules/clock_out/model/clock_out_model.dart';
import 'package:euroside/modules/clock_out/provider/clock_provider.dart';
import 'package:euroside/services/current_clock_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/clock_in_provider.dart';
import 'dart:convert';
import 'dart:ui';

class ClockInScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;
  final bool returnOnSuccess;

  const ClockInScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.returnOnSuccess = false,
  });

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen> {
  static const String _clockedInKey = "isClockedIn";
  static const String _clockedInProjectIdKey = "clockedInProjectId";

  bool isLoading = false;
  String statusMessage = "Tap below to clock in";
  Color statusColor = Colors.grey;
  bool isClockedInForThisProject = false;
  int? clockedInProjectId;
  bool get isClockedIn => isClockedInForThisProject;
  @override
  void initState() {
    super.initState();
    _checkClockedInState();
  }

  Future<void> _checkClockedInState() async {
    try {
      final session = await CurrentClockSessionService.fetchCurrentSession();

      if (!mounted) return;

      /// ACTIVE SESSION
      if (session.isClockedIn && session.data != null) {
        final activeProjectId = session.data!.projectId;

        setState(() {
          clockedInProjectId = activeProjectId;

          isClockedInForThisProject = activeProjectId == widget.projectId;
        });
      } else {
        /// NO ACTIVE SESSION
        setState(() {
          clockedInProjectId = null;

          isClockedInForThisProject = false;
        });
      }
    } catch (e) {
      debugPrint("CLOCK SESSION ERROR => $e");

      setState(() {
        clockedInProjectId = null;

        isClockedInForThisProject = false;
      });
    }
  }

  void _showTooFarDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo/not_match.png',
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: 180,
                      color: Colors.red.shade50,
                      child: const Icon(Icons.warning_rounded, color: Colors.red, size: 80),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Location Out of Range",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "You are too far from the authorized operative location. Please move closer to the site boundary before attempting to clock in.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Got it",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Prevent blur when animation is 0 to avoid crash
        final sigma = (8 * animation.value).clamp(0.001, 8.0);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  String _cleanErrorMessage(Object error) {
    try {
      String raw = error.toString();

      // Remove Exception prefix
      if (raw.startsWith('Exception: ')) {
        raw = raw.replaceFirst('Exception: ', '');
      }

      // Find JSON part
      final jsonStart = raw.indexOf('{');

      if (jsonStart != -1) {
        final jsonString = raw.substring(jsonStart);

        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Return only detail message
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
      }

      return raw;
    } catch (e) {
      return "Something went wrong";
    }
  }

  void _logAdminAssignedProjectLocation() {
    final projects = ref.read(AllprojectControllerProvider).projects;
    final project = projects
        .where((item) => item.id == widget.projectId)
        .cast<AllprojectModel?>()
        .firstOrNull;

    if (project == null) {
      debugPrint(
        '[ClockIn][DEBUG] Admin project location not found in cache for projectId=${widget.projectId}',
      );
      return;
    }

    final hasLatLng =
        project.latitude.trim().isNotEmpty &&
        project.longitude.trim().isNotEmpty;

    debugPrint(
      '[ClockIn][DEBUG] Admin assigned project location => projectId=${project.id}, name=${project.name}, lat=${project.latitude}, lng=${project.longitude}, hasCoordinates=$hasLatLng',
    );
  }

  Future<void> handleClockIn() async {
    setState(() {
      isLoading = true;
      statusMessage = "📍 Fetching location...";
      statusColor = Colors.blue;
    });

    try {
      _logAdminAssignedProjectLocation();

      final controller = ref.read(clockControllerProvider);
      final result = await controller.clockIn(widget.projectId);
      if (result == null) {
        setState(() {
          statusMessage = "❌ Clock-in failed";
          statusColor = Colors.red;
        });
      } else if (result.withinRadius) {
        await CurrentClockSessionService.syncCurrentSession();
        setState(() {
          statusMessage = "✅ ${result.message}";
          statusColor = Colors.green;
          isClockedInForThisProject = true;
        });
        // 🔥 Navigate to Job List after success
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          Navigator.pop(context, true);
        });
      } else {
        setState(() {
          statusMessage = "❌ You are not at the site location";
          statusColor = Colors.orange;
        });
        _showTooFarDialog();
      }
    } catch (e) {
      final message = _cleanErrorMessage(e);
      if (message.toLowerCase().contains('active clock-in session')) {
        try {
          final errorStr = e.toString();

          final jsonStart = errorStr.indexOf('{');
          if (jsonStart != -1) {
            final jsonStr = errorStr.substring(jsonStart);
            // ignore: avoid_print
            final Map<String, dynamic> data = jsonDecode(jsonStr);
            // ignore: avoid_print
            if (data.containsKey('active_session')) {
              final activeSession = data['active_session'];
              final int? backendProjectId = activeSession['project'] is int
                  ? activeSession['project']
                  : int.tryParse(activeSession['project'].toString());
              // ignore: avoid_print
              print(
                '[ClockIn][DEBUG] Backend active projectId: ' +
                    backendProjectId.toString(),
              );
              if (backendProjectId != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_clockedInKey, true);
                await prefs.setInt(_clockedInProjectIdKey, backendProjectId);
                // ignore: avoid_print
                print(
                  '[ClockIn][DEBUG] Updated local state: isClockedIn=true, projectId=$backendProjectId',
                );
                await _checkClockedInState();
                setState(() {
                  statusMessage =
                      "❌ Active clock-in is for another project. Please open that project or clock out first.";
                  statusColor = Colors.orange;
                });
                return;
              }
            }
          }
        } catch (err) {
          // ignore: avoid_print
          print(
            '[ClockIn][DEBUG] Error parsing backend response: ' +
                err.toString(),
          );
        }
        // fallback: just refresh state
        await _checkClockedInState();
        setState(() {
          statusMessage =
              "❌ Active clock-in is for another project. Please open that project or clock out first.";
          statusColor = Colors.orange;
        });
        return;
      }
      if (message.toLowerCase().contains('too far') || e.toString().contains('"within_allowed_radius":false')) {
        setState(() {
          statusMessage = "❌ You are not at the site location";
          statusColor = Colors.orange;
        });
        _showTooFarDialog();
      } else {
        setState(() {
          statusMessage = "❌ $message";
          statusColor = Colors.red;
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> handleClockOut() async {
    setState(() {
      isLoading = true;
      statusMessage = "⏳ Clocking out...";
      statusColor = Colors.blue;
    });
    // Debug print
    // ignore: avoid_print
    print('[ClockOut] Attempting to clock out...');
    try {
      // Fetch project details from provider
      final projectsAsync = ref.read(AllprojectControllerProvider);
      List<AllprojectModel> projects = [];
      if (projectsAsync is AsyncData<List<AllprojectModel>>) {
        final projectsState = ref.read(AllprojectControllerProvider);
        projects = projectsState.projects;
      } else if (projectsAsync is AsyncValue<List<AllprojectModel>>) {
        projects = projectsAsync.projects;
      }
      // Debug print project list and clockedInProjectId
      // ignore: avoid_print
      print(
        '[ClockOut] Project list IDs: ' +
            projects.map((p) => p.id).toList().toString(),
      );
      print('[ClockOut] clockedInProjectId: $clockedInProjectId');
      // Always clock out from the active project
      final project = projects.firstWhere(
        (p) => p.id == clockedInProjectId,
        orElse: () => throw Exception('Active clocked-in project not found'),
      );
      final latitude = double.tryParse(project.latitude) ?? 0.0;
      final longitude = double.tryParse(project.longitude) ?? 0.0;

      // Debug print
      // ignore: avoid_print
      print(
        '[ClockOut] Project: id=${project.id}, name=${project.name}, lat=$latitude, lng=$longitude',
      );

      final clockOutController = ref.read(clockOutControllerProvider);
      final model = ClockOutModel(
        projectId: project.id,
        latitude: latitude,
        longitude: longitude,
      );
      final result = await clockOutController.clockOut(model: model);
      // Debug print
      // ignore: avoid_print
      print('[ClockOut] API result: $result');
      if (result) {
        await CurrentClockSessionService.clearCachedSession();

        await _checkClockedInState();
        setState(() {
          statusMessage = "✅ Successfully clocked out.";
          statusColor = Colors.green;
          isClockedInForThisProject = false;
          clockedInProjectId = null;
        });
      } else {
        setState(() {
          statusMessage = "❌ Clock out failed.";
          statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ Failed to clock out.";
        statusColor = Colors.red;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF6F8FC),
        titleSpacing: 0,
        title: const Text(
          "Project Clock In",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F1B3D),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7ECF6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show currently clocked-in project info
                  if (clockedInProjectId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF1B5EF7),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0x1A1B5EF7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF1B5EF7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selected Project",
                              style: TextStyle(
                                color: Color(0xFF7C8AA5),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.projectName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F1B3D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7FB)),
                    ),
                    child: Text(
                      statusMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isClockedIn)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleClockOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          disabledBackgroundColor: const Color(0xFFEF9A9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Clock Out",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleClockIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5EF7),
                          disabledBackgroundColor: const Color(0xFF9DBAF8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Clock In",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
