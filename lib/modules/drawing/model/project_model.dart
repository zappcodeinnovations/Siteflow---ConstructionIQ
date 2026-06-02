class ProjectModel {
  final int id;
  final String name;
  final String code;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      code: _toString(json['code']),
    );
  }

  static ProjectModel? fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ProjectModel.fromJson(value);
    }

    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}
