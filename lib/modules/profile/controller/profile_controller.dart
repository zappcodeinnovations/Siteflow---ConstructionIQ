import 'package:euroside/services/profile_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/profile_model.dart';

class ProfileState {
  final bool isLoading;
  final ProfileModel? profile;
  final String? error;

  final bool isLocationEnabled;
  final bool isLocationPermissionGranted;

  ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
    this.isLocationEnabled = false,
    this.isLocationPermissionGranted = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    ProfileModel? profile,
    String? error,

    bool? isLocationEnabled,
    bool? isLocationPermissionGranted,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      isLocationPermissionGranted:
          isLocationPermissionGranted ?? this.isLocationPermissionGranted,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState());

  Future<void> getProfile({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (!forceRefresh && state.profile != null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ProfileService.getProfile();
      final userData = response["user"];

      debugPrint("API RESPONSE: $response");

      state = state.copyWith(
        isLoading: false,
        profile: ProfileModel.fromJson(userData),
      );
    } catch (e, stackTrace) {
      debugPrint("ERROR: $e");
      debugPrint("STACKTRACE: $stackTrace");

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// ✅ CHECK LOCATION STATUS
  Future<void> checkLocationStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    final permission = await Permission.location.status;

    state = state.copyWith(
      isLocationEnabled: serviceEnabled,
      isLocationPermissionGranted: permission.isGranted,
    );
  }

  /// ✅ ENABLE LOCATION
  Future<void> enableLocationPermission() async {
    final permission = await Permission.location.request();

    if (permission.isGranted) {
      await Geolocator.openLocationSettings();
    }

    await checkLocationStatus();
  }
}
