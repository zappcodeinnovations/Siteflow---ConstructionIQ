import 'package:euro_side/services/profile_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/profile_model.dart';

class ProfileState {
  final bool isLoading;
  final ProfileModel? profile;
  final String? error;

  ProfileState({this.isLoading = false, this.profile, this.error});

  ProfileState copyWith({
    bool? isLoading,
    ProfileModel? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState());

  Future<void> getProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ProfileService.getProfile();

      /// ✅ PRINT FULL RESPONSE
      print("🔥 API RESPONSE: $response");

      final userData = response["user"];

      state = state.copyWith(
        isLoading: false,
        profile: ProfileModel.fromJson(userData),
      );
    } catch (e, stackTrace) {
      /// ✅ PRINT ERROR
      print("❌ ERROR: $e");
      print("📍 STACKTRACE: $stackTrace");

      state = state.copyWith(
        isLoading: false,
        error: e.toString(), // show real error
      );
    }
  }
}
