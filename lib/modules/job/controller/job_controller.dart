import 'package:euro_side/services/job_services.dart';
import 'package:flutter/material.dart';
import '../model/job_model.dart';

class JobController {
  Future<List<JobModel>> fetchJobs() async {
    try {
      final response = await JobService.getJobs();

      final List list = response["jobs"];

      List<JobModel> jobs = list.map((item) {
        return JobModel.fromJson(item);
      }).toList();

      return jobs;
    } catch (e) {
      debugPrint("❌ JOB CONTROLLER ERROR: $e");
      rethrow;
    }
  }
}