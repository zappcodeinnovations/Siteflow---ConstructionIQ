import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrawingFilterState {
  final int? projectId;
  final int? levelId;
  final String? status;

  const DrawingFilterState({this.projectId, this.levelId, this.status});

  bool get hasFilters =>
      projectId != null || levelId != null || (status ?? '').isNotEmpty;

  DrawingFilterState copyWith({
    int? projectId,
    int? levelId,
    String? status,
    bool clearProjectId = false,
    bool clearLevelId = false,
    bool clearStatus = false,
  }) {
    return DrawingFilterState(
      projectId: clearProjectId ? null : projectId ?? this.projectId,
      levelId: clearLevelId ? null : levelId ?? this.levelId,
      status: clearStatus ? null : status ?? this.status,
    );
  }
}

class DrawingController extends StateNotifier<DrawingFilterState> {
  DrawingController() : super(const DrawingFilterState());

  void setProjectId(int? projectId) {
    state = state.copyWith(
      projectId: projectId,
      clearProjectId: projectId == null,
    );
  }

  void setLevelId(int? levelId) {
    state = state.copyWith(levelId: levelId, clearLevelId: levelId == null);
  }

  void setStatus(String? status) {
    final normalized = status?.trim();
    state = state.copyWith(
      status: normalized,
      clearStatus: normalized == null || normalized.isEmpty,
    );
  }

  void clearFilters() {
    state = const DrawingFilterState();
  }
}
