import 'dart:convert';
import 'dart:async';
import 'package:euroside/modules/Auth/view/auth_view.dart';
import 'package:euroside/modules/all_projects/provider/all_project_provider.dart';
import 'package:euroside/modules/all_projects/view/project_details_view.dart';
import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/modules/announcements/model/announcement_model.dart';
import 'package:euroside/modules/announcements/provider/announcement_provider.dart';
import 'package:euroside/modules/announcements/view/announcement.dart';
import 'package:euroside/modules/clock_out/model/clock_out_model.dart';
import 'package:euroside/modules/clock_out/provider/clock_provider.dart';
import 'package:euroside/modules/form/provider/form_provider.dart';
import 'package:euroside/modules/form/view/form_status_kpi_details_screen.dart';
import 'package:euroside/modules/form/view/selected_job_forms_screen.dart';
import 'package:euroside/modules/notifications/model/app_notification_model.dart';
import 'package:euroside/modules/notifications/provider/notification_provider.dart';
import 'package:euroside/modules/profile/provider/profile_provider.dart';
import 'package:euroside/navigation/app_route_observer.dart';
import 'package:euroside/services/current_clock_session_service.dart';
import 'package:euroside/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  static const String _clockedInKey = "isClockedIn";
  static const String _clockedInProjectIdKey = "clockedInProjectId";
  static const String _clockInStartMillisKey = "clockInStartMillis";
  static const String _clockInTimeKey = "clockInTime";
  static const String _lastLocationTextKey = "lastKnownLocationText";

  String _currentLocation = "Fetching location...";
  String _clockedInProjectName = "";
  String _clockInTimeStr = "";

  Duration _shiftDuration = Duration.zero;
  Timer? _timer;
  bool _isClockedIn = false;
  bool _isClockingOut = false;
  static const Color _ink = Color(0xFF111318);
  static const Color _ink2 = Color(0xFF6B7280);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _accentLight = Color(0xFFEFF4FF);
  bool _locationPermissionDenied = false;

  final ScrollController _notificationsScrollController = ScrollController();
  final ScrollController _announcementsScrollController = ScrollController();

  String _formatClockInTime(String timeStr) {
    if (timeStr.isEmpty) return "--:--";
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  String _formatClockInDate(String timeStr) {
    if (timeStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return "";
    }
  }

  Widget _timeUnit(String value, String label, bool isClockedIn) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: isClockedIn ? Colors.white : _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isClockedIn ? Colors.white.withOpacity(0.7) : _ink2,
          ),
        ),
      ],
    );
  }

  Widget _timeColon(bool isClockedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6).copyWith(bottom: 12),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: isClockedIn ? Colors.white.withOpacity(0.7) : _ink2,
        ),
      ),
    );
  }

  Future<void> _refreshKpis() async {
    ref.invalidate(formStatusKpiProvider);
    await ref.read(formStatusKpiProvider.future);
  }

  void _refreshUpdates() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(announcementsProvider);
  }

  void _handlePushRefresh() {
    if (!mounted) return;
    _refreshUpdates();
    unawaited(_refreshKpis());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedLocation();
    unawaited(_requestStartupPermissions());
    _loadShiftState();
    _startTimer();
    Future.microtask(
      () => ref.read(AllprojectControllerProvider.notifier).fetchProjects(),
    );
    Future.microtask(
      () => ref.read(profileControllerProvider.notifier).getProfile(),
    );
    Future.microtask(_refreshKpis);
    Future.microtask(_refreshUpdates);
    FcmService.notificationTick.addListener(_handlePushRefresh);
    // Future.microtask(() async {
    //   await _fetchCurrentLocation();
    //   await _setClockedInProjectName();
    // });
  }

  Future<void> _requestStartupPermissions() async {
    await _fetchCurrentLocation();
    if (!mounted) return;

    // Let iOS finish any location prompt before showing the camera prompt.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return;
      }

      final result = await Permission.camera.request();

      if (!mounted) return;

      if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera permission is required. Please enable it in Settings.',
            ),
          ),
        );
        return;
      }

      if (result.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission was denied.')),
        );
      }
    } catch (e) {
      debugPrint('Camera permission error: $e');
    }
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (!mounted) return;

    final locationDenied =
        !serviceEnabled ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;

    if (locationDenied) {
      setState(() {
        _currentLocation = 'Location permission required';
        _locationPermissionDenied = true;
      });

      return;
    }

    final cachedLocation = prefs.getString(_lastLocationTextKey);

    if (cachedLocation != null && cachedLocation.trim().isNotEmpty) {
      setState(() {
        _currentLocation = cachedLocation;
        _locationPermissionDenied =
            cachedLocation == "Location permission required";
      });
    }
  }

  Future<void> _setCurrentLocationText(String value) async {
    if (!mounted) return;

    setState(() {
      _currentLocation = value;
      _locationPermissionDenied = value == "Location permission required";
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationTextKey, value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
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

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "Location permission required";
          _locationPermissionDenied = true;
        });

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _setCurrentLocationText("Location permission required");

        return;
      }

      final lastKnownPosition = await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null) {
        await _setCurrentLocationText(
          "${lastKnownPosition.latitude.toStringAsFixed(6)}, ${lastKnownPosition.longitude.toStringAsFixed(6)}",
        );
      }

      final position = await Geolocator.getCurrentPosition();

      await _setCurrentLocationText(
        "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}",
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final detailedAddress = _formatDetailedAddress(place);

        if (detailedAddress.isNotEmpty) {
          await _setCurrentLocationText(detailedAddress);
        }
      } else {
        await _setCurrentLocationText(
          "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}",
        );
      }
    } catch (e) {
      await _setCurrentLocationText("Location permission required");
    }
  }

  String _formatDetailedAddress(Placemark place) {
    final parts = <String>[
      place.subThoroughfare?.trim() ?? '',
      place.thoroughfare?.trim() ?? '',
      place.subLocality?.trim() ?? '',
      place.locality?.trim() ?? '',
      place.administrativeArea?.trim() ?? '',
      place.postalCode?.trim() ?? '',
      place.country?.trim() ?? '',
    ];

    final cleaned = parts.where((part) => part.isNotEmpty).toList();

    if (cleaned.isEmpty) {
      return '';
    }

    return cleaned.join(', ');
  }
  // Future<void> _setClockedInProjectName() async {
  //   try {
  //     final session = await CurrentClockSessionService.fetchCurrentSession();

  //     if (!mounted) return;

  //     if (session.isClockedIn && session.data != null) {
  //       setState(() {
  //         _clockedInProjectName = session.data!.projectName;
  //       });
  //     } else {
  //       setState(() {
  //         _clockedInProjectName = "No active project";
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("CLOCK SESSION ERROR => $e");
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadShiftState();
      _refreshKpis();
    }
  }

  @override
  void didPush() {
    _loadShiftState();
    _refreshKpis();
  }

  @override
  void didPopNext() {
    _loadShiftState();
    _refreshKpis();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    FcmService.notificationTick.removeListener(_handlePushRefresh);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _notificationsScrollController.dispose();
    _announcementsScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    await _loadShiftState();
    await ref
        .read(AllprojectControllerProvider.notifier)
        .fetchProjects(force: true);
    await ref.read(profileControllerProvider.notifier).getProfile();
    await _refreshKpis();
    _refreshUpdates();
  }

  Future<void> _openClockedInProjectDetails(int projectId) async {
    AllprojectModel? project;

    for (final item in ref.read(AllprojectControllerProvider).projects) {
      if (item.id == projectId) {
        project = item;
        break;
      }
    }

    if (project == null) {
      await ref
          .read(AllprojectControllerProvider.notifier)
          .fetchProjectDetails(projectId);

      if (!mounted) return;

      project = ref.read(AllprojectControllerProvider).selectedProject;
    }

    if (project == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project details are unavailable')),
      );
      return;
    }

    final resolvedProject = project;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProjectDetailsPage(
          projectId: resolvedProject.id,
          initialProject: resolvedProject,
        ),
      ),
    );
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location service is disabled')),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _clockOutFromDashboard() async {
    if (_isClockingOut) return;

    setState(() {
      _isClockingOut = true;
    });

    try {
      final session = await CurrentClockSessionService.fetchCurrentSession();

      if (!session.isClockedIn || session.data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active clock-in session found')),
        );
        await _loadShiftState();
        return;
      }

      final position = await _getCurrentPosition();
      if (position == null) {
        return;
      }

      final model = ClockOutModel(
        projectId: session.data!.projectId,
        latitude: position.latitude,
        longitude: position.longitude,
        notes: 'Clocked out from dashboard',
      );

      final result = await ref
          .read(clockOutControllerProvider)
          .clockOut(model: model);

      if (!mounted) return;

      if (result) {
        await CurrentClockSessionService.clearCachedSession();
        await _loadShiftState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully clocked out'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock out failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      handleSessionExpired(context, e);

      final errorStr = e.toString();
      final backendMarker = errorStr.indexOf('|BACKEND_JSON|');
      final cleanError = backendMarker != -1
          ? errorStr.substring(0, backendMarker)
          : errorStr;
      final lowerError = cleanError.toLowerCase();

      if (lowerError.contains('site location') ||
          lowerError.contains('site area') ||
          lowerError.contains('location mismatch')) {
        _showLocationMismatchDialog(
          message: cleanError.trim().replaceFirst('Exception: ', ''),
        );
        return;
      }

      if (lowerError.contains('task') ||
          lowerError.contains('sheet') ||
          lowerError.contains('form') ||
          lowerError.contains('submit') ||
          lowerError.contains('required') ||
          lowerError.contains('fill')) {
        _showFormRequiredDialog(jobId: _extractJobIdFromError(errorStr));
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Clock out failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isClockingOut = false;
        });
      }
    }
  }

  int? _extractJobIdFromError(String error) {
    const marker = '|BACKEND_JSON|';
    final markerIndex = error.indexOf(marker);
    final jsonText = markerIndex != -1
        ? error.substring(markerIndex + marker.length).trim()
        : error.contains('{')
        ? error.substring(error.indexOf('{')).trim()
        : '';

    if (jsonText.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) {
        final forms = decoded['missing_required_forms'];
        if (forms is List && forms.isNotEmpty) {
          final counts = <int, int>{};

          for (final item in forms) {
            if (item is! Map<String, dynamic>) continue;

            final rawJobId = item['job_id'];
            final parsedJobId = rawJobId is int
                ? rawJobId
                : int.tryParse(rawJobId?.toString() ?? '');

            if (parsedJobId == null) continue;

            counts[parsedJobId] = (counts[parsedJobId] ?? 0) + 1;
          }

          if (counts.isNotEmpty) {
            final selectedJobId = counts.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key;

            debugPrint(
              '📌 CLOCK OUT POPUP JOB ID => $selectedJobId (from missing_required_forms)',
            );

            return selectedJobId;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  void _showFormRequiredDialog({int? jobId}) {
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
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xffFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xffF97316),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Form Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  jobId != null
                      ? 'Please fill and submit the required form before clocking out. You can open the form page from here.'
                      : 'You have not created a job and no forms were selected for this project.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xff64748B),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
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
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
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

                          if (jobId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You have not created a job and no forms were selected for this project.',
                                ),
                              ),
                            );
                            return;
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SelectedJobFormsScreen(jobId: jobId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(
                          jobId != null ? 'Fill Form' : 'Okay',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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

  void _showLocationMismatchDialog({required String message}) {
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
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xffFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: Color(0xffDC2626),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Location Mismatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xff64748B),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Okay',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _restoreShiftStateFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool(_clockedInKey) ?? false;
    final startMillis = prefs.getInt(_clockInStartMillisKey);
    final clockInTimePref = prefs.getString(_clockInTimeKey) ?? "";

    if (!isClockedIn || startMillis == null) {
      return false;
    }

    final elapsedMillis = DateTime.now().millisecondsSinceEpoch - startMillis;
    final safeElapsedMillis = elapsedMillis > 0 ? elapsedMillis : 0;

    if (!mounted) return true;

    setState(() {
      _isClockedIn = true;
      _shiftDuration = Duration(milliseconds: safeElapsedMillis);
      _clockInTimeStr = clockInTimePref;

      if (_clockedInProjectName.isEmpty ||
          _clockedInProjectName == "No active project") {
        _clockedInProjectName = "Clocked in project";
      }
    });

    _fetchCurrentLocation();
    return true;
  }

  Future<void> _loadShiftState() async {
    try {
      final session = await CurrentClockSessionService.syncCurrentSession();

      if (!mounted) return;

      if (session != null && session.isClockedIn && session.data != null) {
        final data = session.data!;

        setState(() {
          _isClockedIn = true;

          _shiftDuration = Duration(seconds: data.elapsedSeconds);

          _clockedInProjectName = data.projectName;
          _clockInTimeStr = data.clockInTime;

          // _currentLocation = "Fetching location...";
        });

        /// LOAD LOCATION FAST
        _fetchCurrentLocation();
      } else {
        final restoredFromCache = await _restoreShiftStateFromCache();

        if (!restoredFromCache && mounted) {
          setState(() {
            _isClockedIn = false;

            _shiftDuration = Duration.zero;

            _clockedInProjectName = "No active project";
            _clockInTimeStr = "";

            _currentLocation = "Location unavailable";
          });
        }
      }
    } catch (e) {
      debugPrint("Session fetch error: $e");

      final restoredFromCache = await _restoreShiftStateFromCache();

      if (!restoredFromCache && mounted) {
        setState(() {
          _isClockedIn = false;
          _shiftDuration = Duration.zero;
          _clockInTimeStr = "";
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn && !_locationPermissionDenied) {
        setState(() {
          _shiftDuration += const Duration(seconds: 1);
        });
      }
    });
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
    final projectState = ref.watch(AllprojectControllerProvider);
    final kpiState = ref.watch(formStatusKpiProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final announcementsState = ref.watch(announcementsProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: projectState.isLoading && projectState.projects.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                )
              : projectState.error != null
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _isNetworkError(projectState.error)
                          ? _buildNetworkErrorCard(onRetry: _refreshDashboard)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Iconsax.warning_2,
                                  size: 40,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Something went wrong",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  projectState.error ?? "",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _ink2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                )
              : Builder(
                  builder: (_) {
                    final projects = projectState.projects;
                    final kpi = kpiState.valueOrNull;
                    final totalForms = kpi?.totalForms ?? 0;
                    final notSignature = kpi?.notSignature ?? 0;
                    final submitted = kpi?.submitted ?? 0;
                    final completed = kpi?.completed ?? 0;
                    // print("KPI Total Forms: $totalForms");
                    // print("KPI Submitted: $submitted");
                    // print("KPI Completed: $completed");
                    // print("KPI Not Signature: $notSignature");
                    final latestSubmission = kpi?.latestSubmission;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── HEADER ──────────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/logo/2.png",
                                height: 50,
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: _isClockedIn
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF4B8DF8),
                                        Color(0xFF1E5EE6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: !_isClockedIn ? _surface : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isClockedIn
                                    ? Colors.transparent
                                    : _border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isClockedIn
                                      ? _accent.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_isClockedIn)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                "Shift Active",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                "Not Clocked In",
                                                style: TextStyle(
                                                  color: _ink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "SHIFT DURATION",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _isClockedIn
                                          ? Colors.white.withOpacity(0.8)
                                          : _ink2,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (_isClockedIn)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Iconsax.clock,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: _bg,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Iconsax.timer,
                                            color: _ink,
                                            size: 28,
                                          ),
                                        ),
                                      if (_isClockedIn)
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                _timeUnit(
                                                  _shiftDuration.inHours
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  "HOURS",
                                                  _isClockedIn,
                                                ),
                                                _timeColon(_isClockedIn),
                                                _timeUnit(
                                                  (_shiftDuration.inMinutes % 60)
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  "MINUTES",
                                                  _isClockedIn,
                                                ),
                                                _timeColon(_isClockedIn),
                                                _timeUnit(
                                                  (_shiftDuration.inSeconds % 60)
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  "SECONDS",
                                                  _isClockedIn,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "--:--:--",
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w700,
                                                    color: _ink,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  "NOT CLOCKED IN",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _ink2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (_locationPermissionDenied)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isClockedIn
                                            ? Colors.white.withOpacity(0.12)
                                            : _bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isClockedIn
                                              ? Colors.white.withOpacity(0.15)
                                              : _border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Iconsax.location_slash,
                                            color: _isClockedIn
                                                ? Colors.white
                                                : _ink2,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Location permission required",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _isClockedIn
                                                    ? Colors.white.withOpacity(
                                                        0.95,
                                                      )
                                                    : _ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  if (_isClockedIn) ...[
                                    Divider(
                                      color: Colors.white.withOpacity(0.2),
                                      height: 1,
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Iconsax.location,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Operative Location",
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _locationPermissionDenied
                                                          ? "Location Permission Required"
                                                          : _currentLocation,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      ],
                                    ),
                                  ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: Image.asset(
                                        'assets/logo/hero.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── STATS SECTION TITLE ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionTitle("Form Stats", Iconsax.chart_1),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FormStatusKpiDetailsScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _accent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  Iconsax.arrow_right_3,
                                  size: 14,
                                ),
                                label: const Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          kpiState.when(
                            data: (_) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _statCard(
                                          "Total Forms",
                                          totalForms,
                                          _StatStyle.amber,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _statCard(
                                          "Submitted",
                                          submitted,
                                          _StatStyle.blue,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _statCard(
                                          "Completed",
                                          completed,
                                          _StatStyle.green,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _statCard(
                                          "Pending\nSignature",
                                          notSignature,
                                          _StatStyle.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },

                            loading: () => const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            ),

                            error: (e, _) => _isNetworkError(e.toString())
                                ? _buildNetworkErrorCard(
                                    onRetry: _refreshDashboard,
                                  )
                                : Center(child: Text(e.toString())),
                          ),
                          if (latestSubmission != null) ...[
                            _sectionTitle(
                              "Latest Form Submission",
                              Iconsax.chart_1,
                            ),

                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF4FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Iconsax.document_text,
                                      color: _accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Latest Submission",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _ink2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          latestSubmission.formName.isEmpty
                                              ? "No recent submission"
                                              : latestSubmission.formName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Status: ${latestSubmission.status.isEmpty ? 'unknown' : latestSubmission.status}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _ink2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),

                          _buildUpdatesSection(
                            notificationsState,
                            announcementsState,
                          ),

                          const SizedBox(height: 28),

                          _sectionTitle("Clocked In Project", Iconsax.chart_1),
                          const SizedBox(height: 10),

                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isClockedIn
                                ? () async {
                                    final session =
                                        await CurrentClockSessionService.fetchCurrentSession();

                                    if (!mounted) return;

                                    final sessionData = session.data;
                                    if (sessionData == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No active project found',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await _openClockedInProjectDetails(
                                      sessionData.projectId,
                                    );
                                  }
                                : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),

                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF4FF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),

                                        child: const Icon(
                                          Iconsax.briefcase,
                                          color: _accent,
                                          size: 18,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            const Text(
                                              "Clocked In Project",

                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _ink2,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              _clockedInProjectName.isEmpty
                                                  ? "No Clocked In Project"
                                                  : _clockedInProjectName,

                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (_isClockedIn) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Iconsax.arrow_right_3,
                                          size: 18,
                                          color: _ink2,
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  if (_isClockedIn) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.location,
                                                  size: 15,
                                                  color: _ink2,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _currentLocation,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: _ink2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _isClockingOut
                                            ? null
                                            : _clockOutFromDashboard,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFDC2626,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: _isClockingOut
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.logout,
                                                size: 18,
                                              ),
                                        label: Text(
                                          _isClockingOut
                                              ? 'Clocking out...'
                                              : 'Clock Out',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'No active clock-in session',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _ink2.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     _sectionTitle("Your Projects", Iconsax.briefcase),
                          //     GestureDetector(
                          //       onTap: () async {
                          //         final result = await Navigator.push(
                          //           context,
                          //           MaterialPageRoute(
                          //             builder: (_) => const AllProjectListPage(),
                          //           ),
                          //         );

                          //         if (result == true) {
                          //           await _loadShiftState();
                          //         }
                          //       },
                          //       child: Row(
                          //         children: const [
                          //           Text(
                          //             "See all",
                          //             style: TextStyle(
                          //               fontSize: 13,
                          //               color: _accent,
                          //               fontWeight: FontWeight.w500,
                          //             ),
                          //           ),
                          //           SizedBox(width: 3),
                          //           Icon(
                          //             Iconsax.arrow_right_1,
                          //             size: 14,
                          //             color: _accent,
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          // const SizedBox(height: 12),

                          // // ── PROJECT LIST ─────────────────────────────────────────
                          // if (previewProjects.isEmpty)
                          //   Container(
                          //     width: double.infinity,
                          //     padding: const EdgeInsets.symmetric(vertical: 36),
                          //     decoration: BoxDecoration(
                          //       color: _surface,
                          //       borderRadius: BorderRadius.circular(14),
                          //       border: Border.all(color: _border),
                          //     ),
                          //     child: Column(
                          //       children: [
                          //         Icon(
                          //           Iconsax.folder_open,
                          //           size: 40,
                          //           color: _ink2.withOpacity(0.3),
                          //         ),
                          //         const SizedBox(height: 10),
                          //         const Text(
                          //           "No projects assigned yet",
                          //           style: TextStyle(color: _ink2, fontSize: 13),
                          //         ),
                          //       ],
                          //     ),
                          //   )
                          // else
                          //   ...previewProjects.map((p) {
                          //     final _StatusMeta meta = _statusMeta(p.status);

                          //     return GestureDetector(
                          //       onTap: () async {
                          //         final prefs =
                          //             await SharedPreferences.getInstance();
                          //         final isClockedIn =
                          //             prefs.getBool(_clockedInKey) ?? false;
                          //         final clockedInProjectId = prefs.getInt(
                          //           _clockedInProjectIdKey,
                          //         );

                          //         if (isClockedIn && clockedInProjectId == p.id) {
                          //           if (!context.mounted) return;
                          //           final result = await Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (_) => ClockInScreen(
                          //                 projectId: p.id,
                          //                 projectName: p.name,
                          //               ),
                          //             ),
                          //           );

                          //           if (result == true) {
                          //             await _loadShiftState();
                          //           }
                          //         } else if (isClockedIn &&
                          //             clockedInProjectId != null &&
                          //             clockedInProjectId != p.id) {
                          //           if (!context.mounted) return;
                          //           // ScaffoldMessenger.of(context).showSnackBar(
                          //           //   const SnackBar(
                          //           //     content: Text(
                          //           //       'You already have an active clock-in on another project. Please clock out first.',
                          //           //     ),
                          //           //   ),
                          //           // );
                          //           Fluttertoast.showToast(
                          //             msg:
                          //                 'You already have an active clock-in on another project. Please clock out first.',
                          //             toastLength: Toast.LENGTH_SHORT,
                          //             gravity: ToastGravity.CENTER,
                          //             backgroundColor: Colors.redAccent,
                          //             textColor: Colors.white,
                          //           );
                          //         } else {
                          //           if (!context.mounted) return;
                          //           await Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (_) => ClockInScreen(
                          //                 projectId: p.id,
                          //                 projectName: p.name,
                          //               ),
                          //             ),
                          //           );
                          //         }
                          //         await _loadShiftState();
                          //       },
                          //       child: Container(
                          //         margin: const EdgeInsets.only(bottom: 10),
                          //         padding: const EdgeInsets.symmetric(
                          //           horizontal: 16,
                          //           vertical: 14,
                          //         ),
                          //         decoration: BoxDecoration(
                          //           color: _surface,
                          //           borderRadius: BorderRadius.circular(14),
                          //           border: Border.all(color: _border),
                          //           boxShadow: [
                          //             BoxShadow(
                          //               color: Colors.black.withOpacity(0.03),
                          //               blurRadius: 8,
                          //               offset: const Offset(0, 2),
                          //             ),
                          //           ],
                          //         ),
                          //         child: Row(
                          //           children: [
                          //             Container(
                          //               width: 40,
                          //               height: 40,
                          //               decoration: BoxDecoration(
                          //                 color: meta.bg,
                          //                 borderRadius: BorderRadius.circular(10),
                          //               ),
                          //               child: Icon(
                          //                 Iconsax.briefcase,
                          //                 size: 18,
                          //                 color: meta.fg,
                          //               ),
                          //             ),
                          //             const SizedBox(width: 12),
                          //             Expanded(
                          //               child: Column(
                          //                 crossAxisAlignment:
                          //                     CrossAxisAlignment.start,
                          //                 children: [
                          //                   Text(
                          //                     p.name,
                          //                     style: const TextStyle(
                          //                       fontWeight: FontWeight.w600,
                          //                       fontSize: 14,
                          //                       color: _ink,
                          //                     ),
                          //                   ),
                          //                   const SizedBox(height: 4),
                          //                   Row(
                          //                     children: [
                          //                       Container(
                          //                         padding:
                          //                             const EdgeInsets.symmetric(
                          //                               horizontal: 8,
                          //                               vertical: 2,
                          //                             ),
                          //                         decoration: BoxDecoration(
                          //                           color: meta.bg,
                          //                           borderRadius:
                          //                               BorderRadius.circular(6),
                          //                         ),
                          //                         child: Text(
                          //                           p.status.toUpperCase(),
                          //                           style: TextStyle(
                          //                             fontSize: 10,
                          //                             fontWeight: FontWeight.w600,
                          //                             color: meta.fg,
                          //                             letterSpacing: 0.4,
                          //                           ),
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //             const Icon(
                          //               Iconsax.arrow_right,
                          //               size: 16,
                          //               color: _ink2,
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     );
                          //   }),

                          // const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
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

  Widget _buildUpdatesSection(
    AsyncValue<List<AppNotificationModel>> notificationsState,
    AsyncValue<List<AnnouncementModel>> announcementsState,
  ) {
    final notifications = _visibleNotifications(
      notificationsState.valueOrNull ?? const [],
    ).take(4).toList();
    final announcements = _visibleAnnouncements(
      announcementsState.valueOrNull ?? const [],
    ).take(4).toList();

    if (notifications.isEmpty && announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    if (notifications.isNotEmpty && announcements.isEmpty) {
      return _buildSingleUpdatesPanel(
        title: 'Notifications',
        icon: Iconsax.notification,
        child: _buildNotificationsList(notifications),
      );
    }

    if (announcements.isNotEmpty && notifications.isEmpty) {
      return _buildSingleUpdatesPanel(
        title: 'Announcements',
        icon: Icons.campaign_rounded,
        child: _buildAnnouncementsList(announcements),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Updates", Iconsax.notification),
          const SizedBox(height: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: _accent,
              unselectedLabelColor: _ink2,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Notifications'),
                Tab(text: 'Announcements'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 0,
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: TabBarView(
              children: [
                _buildScrollableSection(
                  child: _buildNotificationsList(notifications),
                  isEmpty: notifications.isEmpty,
                ),

                _buildScrollableSection(
                  child: _buildAnnouncementsList(announcements),
                  isEmpty: announcements.isEmpty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableSection({
    required Widget child,
    required bool isEmpty,
  }) {
    if (isEmpty) {
      return const SizedBox.shrink();
    }

    return Scrollbar(
      thumbVisibility: true,
      radius: const Radius.circular(20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }

  Widget _buildSingleUpdatesPanel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, icon),
        const SizedBox(height: 12),
        SizedBox(height: child is ListView ? 160 : 120, child: child),
      ],
    );
  }

  List<AppNotificationModel> _visibleNotifications(
    List<AppNotificationModel> items,
  ) {
    return items.where((item) {
      return item.title.trim().isNotEmpty || item.message.trim().isNotEmpty;
    }).toList();
  }

  List<AnnouncementModel> _visibleAnnouncements(List<AnnouncementModel> items) {
    return items.where((item) {
      return item.isActive &&
          (item.title.trim().isNotEmpty || item.message.trim().isNotEmpty);
    }).toList();
  }

  Widget _buildNotificationsList(List<AppNotificationModel> items) {
    Widget list = ListView.separated(
      controller: _notificationsScrollController,
      padding: EdgeInsets.zero,
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _updateTile(
          icon: Iconsax.notification,
          iconBg: item.isRead
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFEFF4FF),
          iconColor: item.isRead ? _ink2 : _accent,
          title: item.title,
          message: item.message,
          meta: [
            if (item.projectName.isNotEmpty) item.projectName,
            if (item.createdAt != null) _formatShortDate(item.createdAt!),
          ].join(' • '),
        );
      },
    );

    if (items.length > 2) {
      return RawScrollbar(
        controller: _notificationsScrollController,
        thumbColor: Colors.grey.shade400,
        radius: const Radius.circular(8),
        thickness: 4,
        thumbVisibility: true,
        child: list,
      );
    }
    return list;
  }

  Widget _buildAnnouncementsList(List<AnnouncementModel> items) {
    Widget list = ListView.separated(
      controller: _announcementsScrollController,
      padding: const EdgeInsets.only(right: 4),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final createdAt = DateTime.tryParse(item.createdAt);

        return InkWell(
          borderRadius: BorderRadius.circular(14),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnnouncementPage(
                  projectId: item.projectId,
                  projectName: item.projectName,
                ),
              ),
            );
          },

          child: _updateTile(
            icon: Icons.campaign_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            title: item.title,
            message: item.message,
            meta: [
              if (item.projectName.isNotEmpty) item.projectName,
              if (createdAt != null) _formatShortDate(createdAt),
            ].join(' • '),
          ),
        );
      },
    );

    if (items.length > 2) {
      return RawScrollbar(
        controller: _announcementsScrollController,
        thumbColor: Colors.grey.shade400,
        radius: const Radius.circular(8),
        thickness: 4,
        thumbVisibility: true,
        child: list,
      );
    }
    return list;
  }

  Widget _updateTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    required String meta,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.trim().isNotEmpty) ...[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (message.trim().isNotEmpty) const SizedBox(height: 4),
                ],
                if (message.trim().isNotEmpty)
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: _ink2,
                    ),
                  ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _ink2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  bool _isNetworkError(String? message) {
    if (message == null) return false;

    final normalized = message.toLowerCase();
    return normalized.contains('network error') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('unexpected html response from server') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection timed out') ||
        normalized.contains('timeout');
  }

  Widget _buildNetworkErrorCard({required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Network unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We could not load this content because the connection failed. Please check your internet and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.45, color: _ink2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, _StatStyle style) {
    return Container(
      height: 93,
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
            width: 40,
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
                  fontSize: 10,
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
