import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/profile_controller.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController();
});