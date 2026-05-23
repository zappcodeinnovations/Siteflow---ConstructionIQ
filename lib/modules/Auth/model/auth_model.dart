class AuthResponse {
  final String access;
  final String refresh;
  final User user;

  AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json["tokens"]["access"],
      refresh: json["tokens"]["refresh"],
      user: User.fromJson(json["user"]),
    );
  }
}

class User {
  final int id;
  final String email;
  final String username;
  final String displayName;
  final String role;
  final String? profileImage;
  final String? phone;
  final bool isActive;
  final bool isPasswordSet;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.role,
    this.profileImage,
    this.phone,
    required this.isActive,
    required this.isPasswordSet,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      email: json["email"],
      username: json["username"],
      displayName: json["display_name"],
      role: json["effective_role"],
      profileImage: json["profile_image"],
      phone: json["phone"],
      isActive: json["is_active"],
      isPasswordSet: json["is_password_set"] ?? false,
    );
  }
}
