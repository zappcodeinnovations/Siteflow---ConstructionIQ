class ProfileModel {
  final int id;
  final String email;
  final String username;
  final String displayName;
  final String role;
  final String? profileImage;
  final String? phone;
  final bool isActive;

  ProfileModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.role,
    this.profileImage,
    this.phone,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json["id"],
      email: json["email"],
      username: json["username"],
      displayName: json["display_name"],
      role: json["effective_role"],
      profileImage: json["profile_image"],
      phone: json["phone"],
      isActive: json["is_active"],
    );
  }
}