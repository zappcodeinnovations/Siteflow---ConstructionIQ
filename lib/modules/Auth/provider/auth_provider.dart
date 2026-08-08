import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});