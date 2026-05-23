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

    /// ✅ ADD THIS
    required int formId,

    required String reference,
    required String formName,
    required String siteContact,
    required String instructions,
  }) async {
    try {
      debugPrint("📤 PROJECT ID => $projectId");
      debugPrint("📤 FORM ID => $formId");
      debugPrint("📤 FORM NAME => $formName");

      final response = await JobService.createJob(
        projectId: projectId,

        /// ✅ PASS HERE
        formId: formId,

        reference: reference,
        formName: formName,
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