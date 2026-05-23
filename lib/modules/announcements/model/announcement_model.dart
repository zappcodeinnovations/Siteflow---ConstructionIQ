class AnnouncementModel {
  final int id;
  final int projectId;
  final String projectName;
  final String projectCode;
  final String clientName;
  final String title;
  final String message;
  final bool isActive;

  final String createdByName;

  final String createdAt;

  AnnouncementModel({
    required this.id,

    required this.projectId,

    required this.projectName,

    required this.projectCode,

    required this.clientName,

    required this.title,

    required this.message,

    required this.isActive,

    required this.createdByName,

    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json["id"] ?? 0,

      projectId: json["project_id"] ?? 0,

      projectName: json["project_name"] ?? "",

      projectCode: json["project_code"] ?? "",

      clientName: json["client_name"] ?? "",

      title: json["title"] ?? "",

      message: json["message"] ?? "",

      isActive: json["is_active"] ?? false,

      createdByName: json["created_by_name"] ?? "",

      createdAt: json["created_at"] ?? "",
    );
  }
}
