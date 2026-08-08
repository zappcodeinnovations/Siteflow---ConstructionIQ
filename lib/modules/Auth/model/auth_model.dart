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
    final userJson = Map<String, dynamic>.from(json["user"] ?? {});
    for (final entry in json.entries) {
      if (entry.key == "tokens" || entry.key == "user") {
        continue;
      }

      userJson[entry.key] = entry.value;
    }

    return AuthResponse(
      access: json["tokens"]["access"],
      refresh: json["tokens"]["refresh"],
      user: User.fromJson(userJson),
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
    final explicitPasswordSet = _firstBool(json, const [
      "is_password_set",
      "password_set",
      "isPasswordSet",
      "has_set_password",
      "hasSetPassword",
      "is_set_password",
      "set_password",
      "password_changed",
    ]);

    bool? requiresPasswordSetup = _firstBool(json, const [
      "is_first_login",
      "first_login",
      "isFirstLogin",
      "first_time_login",
      "is_first_time_login",
      "isFirstTimeLogin",
      "is_new_user",
      "new_user",
      "isNewUser",
      "force_password_change",
      "forcePasswordChange",
      "must_change_password",
      "mustChangePassword",
      "requires_password_change",
      "requiresPasswordChange",
      "change_password_required",
      "changePasswordRequired",
      "password_change_required",
      "passwordChangeRequired",
      "password_reset_required",
      "passwordResetRequired",
      "is_default_password",
      "isDefaultPassword",
      "temporary_password",
      "temporaryPassword",
      "is_temporary_password",
      "isTemporaryPassword",
      "needs_password_reset",
      "require_password_reset",
      "password_reset_needed",
      "force_password_reset",
      "is_temporary",
    ]);

    if (requiresPasswordSetup != true) {
      if (json.containsKey("last_login")) {
        final ll = json["last_login"];
        if (ll == null || (ll is String && ll.isEmpty)) {
          requiresPasswordSetup = true;
        }
      }
    }

    return User(
      id: json["id"],
      email: json["email"],
      username: json["username"],
      displayName: json["display_name"],
      role: json["effective_role"],
      profileImage: json["profile_image"],
      phone: json["phone"],
      isActive: json["is_active"],
      isPasswordSet: requiresPasswordSetup == true
          ? false
          : explicitPasswordSet ?? !(requiresPasswordSetup ?? true),
    );
  }

  static bool? _firstBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;

      final parsed = _parseBool(json[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (['true', '1', 'yes', 'y'].contains(normalized)) return true;
      if (['false', '0', 'no', 'n'].contains(normalized)) return false;
    }

    return null;
  }
}
