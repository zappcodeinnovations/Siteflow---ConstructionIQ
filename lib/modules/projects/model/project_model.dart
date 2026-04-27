class ProjectModel {
  final int id;
  final String name;
  final String code;
  final String description;
  final String status;
  final String priority;
  final String siteAddress;
  final String city;
  final String country;
  final String latitude;
  final String longitude;
  final String clientName;

  ProjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.status,
    required this.priority,
    required this.siteAddress,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.clientName,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      code: json["code"] ?? "",
      description: json["description"] ?? "",
      status: json["status"] ?? "",
      priority: json["priority"] ?? "",
      siteAddress: json["site_address"] ?? "",
      city: json["city"] ?? "",
      country: json["country"] ?? "",
      latitude: json["latitude"] ?? "",
      longitude: json["longitude"] ?? "",
      clientName: json["client_name"] ?? "",
    );
  }
}