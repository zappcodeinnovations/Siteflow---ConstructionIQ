class ClockOutModel {
  final int projectId;
  final double latitude;
  final double longitude;
  final String? notes;

  ClockOutModel({
    required this.projectId,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  /// 🔥 Convert to JSON (for API)
  Map<String, dynamic> toJson() {
    return {
      "project_id": projectId,
      "latitude": latitude,
      "longitude": longitude,
      if (notes != null) "notes": notes,
    };
  }
}