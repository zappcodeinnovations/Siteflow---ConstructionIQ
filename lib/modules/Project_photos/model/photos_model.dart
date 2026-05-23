class ProjectPhotoModel {

  final int id;
  final int operativeId;

  final String image;
  final String imageUrl;

  final String fileName;

  final int fileSize;

  final String createdAt;
  final String updatedAt;

  ProjectPhotoModel({
    required this.id,
    required this.operativeId,
    required this.image,
    required this.imageUrl,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectPhotoModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return ProjectPhotoModel(

      id: json["id"] ?? 0,

      operativeId:
          json["operative_id"] ?? 0,

      image:
          json["image"] ?? "",

      imageUrl:
          json["image_url"] ?? "",

      fileName:
          json["file_name"] ?? "",

      fileSize:
          json["file_size"] ?? 0,

      createdAt:
          json["created_at"] ?? "",

      updatedAt:
          json["updated_at"] ?? "",
    );
  }
}