import 'block_model.dart';
import 'drawing_location_model.dart';
import 'level_model.dart';
import 'project_model.dart';
import '../utils/drawing_constants.dart';

class DrawingModel {
  final int id;
  final String name;
  final String fileUrl;

  // NEW
  final int imageWidthPx;
  final int imageHeightPx;

  final int sortOrder;
  final ProjectModel? project;
  final BlockModel? block;
  final LevelModel? level;
  final List<DrawingLocationModel> locations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DrawingModel({
    required this.id,
    required this.name,
    required this.fileUrl,

    // NEW
    required this.imageWidthPx,
    required this.imageHeightPx,

    required this.sortOrder,
    required this.project,
    required this.block,
    required this.level,
    required this.locations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrawingModel.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];

    final locationItems = rawLocations is List ? rawLocations : const [];

    return DrawingModel(
      id: _toInt(json['id']),
      name: _toString(json['name']),
      fileUrl: DrawingConstants.normalizeDrawingFileUrl(json['file_url']),

      // NEW
      imageWidthPx: _toInt(json['image_width_px']),

      imageHeightPx: _toInt(json['image_height_px']),

      sortOrder: _toInt(json['sort_order']),

      project: ProjectModel.fromDynamic(json['project']),

      block: BlockModel.fromDynamic(json['block']),

      level: LevelModel.fromDynamic(json['level']),

      locations: locationItems
          .whereType<Map<String, dynamic>>()
          .map(DrawingLocationModel.fromJson)
          .toList(),

      createdAt: _toDateTime(json['created_at']),

      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  bool get isPdf => DrawingConstants.isPdfUrl(fileUrl);

  bool get hasLocations => locations.isNotEmpty;

  String get projectName =>
      project?.name.isNotEmpty == true ? project!.name : '-';

  String get blockName => block?.name.isNotEmpty == true ? block!.name : '-';

  String get levelName => level?.name.isNotEmpty == true ? level!.name : '-';

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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
