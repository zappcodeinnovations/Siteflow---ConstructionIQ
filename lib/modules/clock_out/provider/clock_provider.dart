import 'package:euro_side/modules/clock_out/controller/clock_out_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/clock_out_model.dart';

/// ✅ CONTROLLER PROVIDER
final clockOutControllerProvider = Provider<ClockOutController>((ref) {
  return ClockOutController();
});

/// ✅ CLOCK OUT PROVIDER
final clockOutProvider =
    FutureProvider.family<bool, ClockOutModel>((ref, model) async {
  final controller = ref.read(clockOutControllerProvider);

  return controller.clockOut(model: model);
});