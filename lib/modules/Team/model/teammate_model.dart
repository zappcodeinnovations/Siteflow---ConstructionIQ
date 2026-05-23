class TeammateModel {

  final int id;

  final String email;

  final String username;

  final String firstName;

  final String lastName;

  final String displayName;

  final String effectiveRole;

  final String? phone;

  final String? profileImage;

  TeammateModel({

    required this.id,

    required this.email,

    required this.username,

    required this.firstName,

    required this.lastName,

    required this.displayName,

    required this.effectiveRole,

    this.phone,

    this.profileImage,
  });

  factory TeammateModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return TeammateModel(

      id: json["id"] ?? 0,

      email: json["email"] ?? "",

      username:
          json["username"] ?? "",

      firstName:
          json["first_name"] ?? "",

      lastName:
          json["last_name"] ?? "",

      displayName:
          json["display_name"] ?? "",

      effectiveRole:
          json["effective_role"] ?? "",

      phone: json["phone"],

      profileImage:
          json["profile_image"],
    );
  }
}