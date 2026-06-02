import 'package:euroside/modules/drawing/controller/drawing_controller.dart';
import 'package:euroside/modules/drawing/model/drawing_model.dart';
import 'package:euroside/services/drawing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrawingQueryParams {
  final int? projectId;
  final int? levelId;
  final String? status;

  const DrawingQueryParams({this.projectId, this.levelId, this.status});

  @override
  bool operator ==(Object other) {
    return other is DrawingQueryParams &&
        other.projectId == projectId &&
        other.levelId == levelId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(projectId, levelId, status);
}

final drawingServiceProvider = Provider<DrawingService>((ref) {
  return DrawingService();
});

final drawingFilterControllerProvider =
    StateNotifierProvider<DrawingController, DrawingFilterState>((ref) {
      return DrawingController();
    });

final drawingCatalogProvider = FutureProvider.autoDispose<List<DrawingModel>>((
  ref,
) async {
  final service = ref.read(drawingServiceProvider);
  return service.fetchDrawingLocations();
});

final drawingDrawingsProvider = FutureProvider.autoDispose
    .family<List<DrawingModel>, DrawingQueryParams>((ref, params) async {
      final service = ref.read(drawingServiceProvider);
      return service.fetchDrawingLocations(
        projectId: params.projectId,
        levelId: params.levelId,
        status: params.status,
      );
    });
