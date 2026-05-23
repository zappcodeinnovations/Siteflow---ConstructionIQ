import 'package:euroside/modules/clock_in/controller/clock_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockControllerProvider = Provider<ClockController>((ref) {
  return ClockController();
});