import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/job_controller.dart';
import '../model/job_model.dart';

final jobControllerProvider = Provider<JobController>((ref) {
  return JobController();
});

final jobListProvider = FutureProvider<List<JobModel>>((ref) async {
  final controller = ref.read(jobControllerProvider);
  return controller.fetchJobs();
});