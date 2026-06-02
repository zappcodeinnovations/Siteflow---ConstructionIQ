import 'package:euroside/services/job_services.dart';
import 'package:flutter/material.dart';

import '../model/job_model.dart';

class JobController {
  /// ✅ FETCH JOBS
  Future<List<JobModel>> fetchJobs({int? projectId}) async {
    try {
      final response = projectId == null
          ? await JobService.getJobs()
          : await JobService.getJobsByProject(projectId);

      final List list = response["jobs"] ?? [];

      List<JobModel> jobs = list.map((item) {
        return JobModel.fromJson(item);
      }).toList();

      debugPrint("📡 TOTAL JOBS => ${jobs.length}");

      return jobs;
    } catch (e, stackTrace) {
      debugPrint("❌ JOB CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }

  /// ✅ CREATE JOB
  Future<JobModel> createJob({
    required int projectId,
    required List<int> formIds,

    required String reference,
    required String siteContact,
    required String instructions,
  }) async {
    try {
      debugPrint("📤 PROJECT ID => $projectId");
      debugPrint("📤 FORM IDS => $formIds");

      final response = await JobService.createJob(
        projectId: projectId,

        formIds: formIds,

        reference: reference,
        siteContact: siteContact,
        instructions: instructions,
      );

      debugPrint("📡 CREATE JOB RESPONSE => $response");

      return JobModel.fromJson(response["job"]);
    } catch (e, stackTrace) {
      debugPrint("❌ CREATE JOB CONTROLLER ERROR: $e");
      debugPrint("📍 STACKTRACE: $stackTrace");
      rethrow;
    }
  }
}
