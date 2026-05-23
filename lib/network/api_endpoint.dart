class ApiEndpoints {
  // static const String baseUrl = "http://168.144.78.224/api/";
  static const String baseUrl = "https://euroside.zappcode.in/api/";

  /// FORMS
  static String userFormHtml(int formId) => "userform/$formId/html/";

  // Auth
  static const String login = "token/";
  static const String refreshToken = "token/refresh/";
  static const String operativeLogin = "operative/login/";

  // Profile
  static const String profile = "profile/";

  // Password
  static const String setPassword = "set-password/";
  // static const String projects = "operative/projects/";
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
  static String projectDetails(int id) => "operative/projects/$id/";
  static const String announcements = "operative/announcements/";
  static String projectTeammates(int projectId) =>
      "projects/$projectId/teammates";
  static const String formStatusKpi = "operative/forms/status-kpi/";
}
