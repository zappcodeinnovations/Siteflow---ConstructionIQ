import 'package:euro_side/network/app_start_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appStartProvider =
    StateNotifierProvider<AppStartController, AppStartStatus>(
  (ref) => AppStartController(),
);