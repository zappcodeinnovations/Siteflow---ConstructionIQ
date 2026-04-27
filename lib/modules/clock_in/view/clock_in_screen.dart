import 'package:euro_side/modules/clock_out/model/clock_out_model.dart';
import 'package:euro_side/modules/clock_out/provider/clock_provider.dart';
import 'package:euro_side/modules/job/view/job_screen.dart';
import 'package:flutter/material.dart';
import 'package:euro_side/modules/projects/provider/project_provider.dart';
import 'package:euro_side/modules/projects/model/project_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/clock_in_provider.dart';
import 'dart:convert';

class ClockInScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;

  const ClockInScreen({
    super.key,
    required this.projectId,
    required this.projectName,
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
  bool get isClockedIn => clockedInProjectId != null;

  @override
  void initState() {
    super.initState();
    _checkClockedInState();
  }

  Future<void> _checkClockedInState() async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool(_clockedInKey) ?? false;
    final projectId = prefs.getInt(_clockedInProjectIdKey);
    if (isClockedIn && projectId != null) {
      // Print log to console
      // ignore: avoid_print
      print('[ClockIn] Currently clocked in to project ID: $projectId');
    } else {
      print('[ClockIn] Not clocked in to any project.');
    }
    if (!mounted) return;
    setState(() {
      isClockedInForThisProject = isClockedIn && projectId == widget.projectId;
      clockedInProjectId = isClockedIn ? projectId : null;
    });
    // Optionally, you can still redirect if you want, or just show the button
  }

  String _cleanErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }

  Future<void> handleClockIn() async {
    setState(() {
      isLoading = true;
      statusMessage = "📍 Fetching location...";
      statusColor = Colors.blue;
    });

    try {
      final controller = ref.read(clockControllerProvider);
      final result = await controller.clockIn(widget.projectId);
      if (result == null) {
        setState(() {
          statusMessage = "❌ Clock-in failed";
          statusColor = Colors.red;
        });
      } else if (result.withinRadius) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_clockedInKey, true);
        await prefs.setInt(_clockedInProjectIdKey, widget.projectId);
        await prefs.setInt(
          "clockInStartMillis",
          DateTime.now().millisecondsSinceEpoch,
        );
        setState(() {
          statusMessage = "✅ ${result.message}";
          statusColor = Colors.green;
          isClockedInForThisProject = true;
        });
        // 🔥 Navigate to Job List after success
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => JobListScreen(projectId: widget.projectId),
            ),
          );
        });
      } else {
        setState(() {
          statusMessage =
              "❌ You are ${result.distance.toStringAsFixed(1)}m away\nAllowed: ${result.allowedRadius}m";
          statusColor = Colors.orange;
        });
      }
    } catch (e) {
      final message = _cleanErrorMessage(e);
      if (message.toLowerCase().contains('active clock-in session')) {
        // Try to parse backend response for active session project
        try {
          // e may be a DioError, Exception, or String. Try to extract response body.
          final errorStr = e.toString();
          // Debug print full error string
          // ignore: avoid_print
          print('[ClockIn][DEBUG] Error string: ' + errorStr);
          final jsonStart = errorStr.indexOf('{');
          if (jsonStart != -1) {
            final jsonStr = errorStr.substring(jsonStart);
            // ignore: avoid_print
            print('[ClockIn][DEBUG] JSON string: ' + jsonStr);
            final Map<String, dynamic> data = jsonDecode(jsonStr);
            // ignore: avoid_print
            print('[ClockIn][DEBUG] Parsed JSON: ' + data.toString());
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
      setState(() {
        statusMessage = "❌ $message";
        statusColor = Colors.red;
      });
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
      final projectsAsync = ref.read(projectListProvider);
      List<ProjectModel> projects = [];
      if (projectsAsync is AsyncData<List<ProjectModel>>) {
        projects = projectsAsync.value;
      } else if (projectsAsync is AsyncValue<List<ProjectModel>>) {
        projects = projectsAsync.value ?? [];
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_clockedInKey, false);
        await prefs.remove(_clockedInProjectIdKey);
        await prefs.remove("clockInStartMillis");
        setState(() {
          statusMessage = "✅ Successfully clocked out.";
          statusColor = Colors.green;
          isClockedInForThisProject = false;
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Currently clocked in to project ID: $clockedInProjectId",
                              style: const TextStyle(
                                color: Color(0xFF1B5EF7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
