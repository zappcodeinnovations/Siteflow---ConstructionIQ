class AppNotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String projectName;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.projectName,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _toInt(json['id']) ?? 0,
      title: _readString(json, const ['title', 'heading', 'subject']),
      message: _readString(json, const [
        'message',
        'body',
        'description',
        'content',
        'text',
      ]),
      type: _readString(json, const ['type', 'notification_type', 'category']),
      projectName: _readString(json, const [
        'project_name',
        'projectName',
        'project',
      ]),
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt: DateTime.tryParse(
        _readString(json, const ['created_at', 'createdAt', 'date', 'time']),
      ),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is Map) {
        final nested = value.cast<String, dynamic>();
        final nestedValue = _readString(nested, const [
          'name',
          'title',
          'message',
          'value',
        ]);
        if (nestedValue.isNotEmpty) return nestedValue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }

    return '';
  }
}
