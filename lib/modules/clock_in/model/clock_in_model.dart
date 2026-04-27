class ClockInResponse {
  final String message;
  final double distance;
  final double allowedRadius;
  final bool withinRadius;

  ClockInResponse({
    required this.message,
    required this.distance,
    required this.allowedRadius,
    required this.withinRadius,
  });

  factory ClockInResponse.fromJson(Map<String, dynamic> json) {
    return ClockInResponse(
      message: json["message"] ?? "",
      distance: (json["distance_meters"] ?? 0).toDouble(),
      allowedRadius:
          (json["allowed_radius_meters"] ?? 0).toDouble(),
      withinRadius: json["within_allowed_radius"] ?? false,
    );
  }
}