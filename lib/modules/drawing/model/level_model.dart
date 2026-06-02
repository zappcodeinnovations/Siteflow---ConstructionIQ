class LevelModel {
  final int id;
  final String name;
  final int sortOrder;

  const LevelModel({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      sortOrder: _toInt(json['sort_order']),
    );
  }

  static LevelModel? fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LevelModel.fromJson(value);
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
