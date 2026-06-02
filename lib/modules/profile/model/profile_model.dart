class ProfileModel {
  final int id;
  final String employeeId;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String displayName;
  final String role;
  final String? profileImage;
  final String? phone;
  final bool isActive;

  ProfileModel({
    required this.id,
    required this.employeeId,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.role,
    this.profileImage,
    this.phone,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json["id"],
      employeeId: (json["employee_id"] ?? '').toString(),
      email: json["email"],
      username: json["username"],
      firstName: (json["first_name"] ?? '').toString(),
      lastName: (json["last_name"] ?? '').toString(),
      displayName: json["display_name"],
      role: json["effective_role"],
      profileImage: json["profile_image"],
      phone: json["phone"],
      isActive: json["is_active"],
    );
  }

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) {
      return combined;
    }

    return displayName.trim().isNotEmpty ? displayName : username;
  }
}
