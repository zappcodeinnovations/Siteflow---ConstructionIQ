class DrawingLocationModel {
  final int id;

  final String name;
  final String title;

  // Coordinates
  final double xPercent;
  final double yPercent;

  final int xPixel;
  final int yPixel;

  // Status
  final String status;
  final String statusLabel;

  // Variation
  final String variation;
  final String variationLabel;

  // Details
  final String description;
  final String assignedWorker;
  final String qrCode;

  // Location info
  final String blockName;
  final String levelName;

  // Optional fields
  final String? zone;
  final String? specification;
  final String? relatedJobSheet;

  // Dates
  final DateTime? droppedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DrawingLocationModel({
    required this.id,
    required this.name,
    required this.title,

    required this.xPercent,
    required this.yPercent,

    required this.xPixel,
    required this.yPixel,

    required this.status,
    required this.statusLabel,

    required this.variation,
    required this.variationLabel,

    required this.description,
    required this.assignedWorker,
    required this.qrCode,

    required this.blockName,
    required this.levelName,

    this.zone,
    this.specification,
    this.relatedJobSheet,

    this.droppedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory DrawingLocationModel.fromJson(Map<String, dynamic> json) {
    return DrawingLocationModel(
      id: _toInt(json['id']),

      // Names
      name: _toString(json['label']),

      title: _toString(json['title']),

      // Coordinates
      xPercent: _toDouble(json['x_coordinate']),

      yPercent: _toDouble(json['y_coordinate']),

      xPixel: _toInt(json['x_pixel']),

      yPixel: _toInt(json['y_pixel']),

      // Status
      status: _toString(json['status']),

      statusLabel: _toString(json['status_label']),

      // Variation
      variation: _toString(json['variation']),

      variationLabel: _toString(json['variation_label']),

      // Details
      description: _toString(json['description']),

      assignedWorker: _toString(json['assigned_worker']),

      qrCode: _toString(json['qr_code']),

      // Location
      blockName: _toString(json['block_name']),

      levelName: _toString(json['level_name']),

      // Optional
      zone: json['zone']?.toString(),

      specification: json['specification']?.toString(),

      relatedJobSheet: json['related_job_sheet']?.toString(),

      // Dates
      droppedAt: _toDateTime(json['dropped_at']),

      createdAt: _toDateTime(json['created_at']),

      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  // Status helpers
  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';

  bool get isPending =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'todo';

  bool get hasIssue => status.toLowerCase() == 'issue';

  bool get isDraft => status.toLowerCase() == 'draft';

  // Utils
  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _toDateTime(dynamic value) {
    final text = value?.toString();

    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
