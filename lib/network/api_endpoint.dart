class ApiEndpoints {
  // static const String baseUrl = "http://168.144.78.224/api/";
  static const String baseUrl = "https://euroside.zappcode.in/api/";

  /// FORMS
  static String userFormHtml(int formId) => "userform/$formId/html/";
  static String selectedJobForms(int jobId) =>
      'operative/forms/?selected_only=true&job_id=$jobId';
  static String formsQuery({int? jobId, bool selectedOnly = false}) {
    if (selectedOnly && jobId != null) {
      return selectedJobForms(jobId);
    }

    final params = <String, String>{};

    if (selectedOnly) {
      params['selected_only'] = 'true';
    }

    if (jobId != null) {
      params['job_id'] = jobId.toString();
    }

    if (params.isEmpty) {
      return 'operative/forms/';
    }

    return 'operative/forms/?${Uri(queryParameters: params).query}';
  }

  // Auth
  static const String login = "token/";
  static const String refreshToken = "token/refresh/";
  static const String operativeLogin = "operative/login/";
  static const String registrationStatus = "operative/registration-status/";
  static const String operativeRegister = "operative/register/";
  static const String operativeDeleteAccount = "operative/delete-account/";
  static const String logout = "operative/logout/";
  static const String singleDeviceSession = "single/device/";
  static const String logoutOtherDevice = "logout-other-device/";

  // Profile
  static const String profile = "profile/";

  // Password
  static const String setPassword = "set-password/";
  static const String forgotPassword = "auth/forgot-password/";
  static const String verifyOtp = "auth/verify-otp/";
  static const String resetPassword = "auth/reset-password/";
  static const String drawingLocations = "drawing/locations/";
  static const String jobs = "operative/jobs/";
  static const String clockIn = "operative/clock-in/";
  static const String projectTemplates = "operative/project-templates/";
  static const String templateSubmission = "operative/template-submissions/";
  static const String formsList = "operative/forms/list/";
  static const String submitForm = "operative/forms/submit/";
  static const String clockOut = "operative/clock-out/";
  static const String currentClockSession = "current-clock-session/";
  static const String projectPhotos = "operative/images/";
  static String createProjectJob(int projectId) =>
      "operative/projects/$projectId/jobs/create/";
  static const String allProjects = "projects/";

  /// PROJECT DETAILS
  static String projectDetails(int id) => "projects/$id/";
  static const String announcements = "operative/announcements/";
  static const String operativeNotifications = "operative/notifications/";
  static String projectTeammates(int projectId) =>
      "projects/$projectId/teammates";
  static const String formStatusKpi = "operative/forms/status-kpi/";
}
