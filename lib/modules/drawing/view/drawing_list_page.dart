import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/drawing_model.dart';
import '../model/level_model.dart';
import '../model/project_model.dart';
import '../provider/drawing_provider.dart';
import 'drawing_viewer_page.dart';
import 'widgets/drawing_card.dart';
import 'widgets/drawing_filter_bar.dart';

class DrawingListPage extends ConsumerStatefulWidget {
  const DrawingListPage({super.key});

  @override
  ConsumerState<DrawingListPage> createState() => _DrawingListPageState();
}

class _DrawingListPageState extends ConsumerState<DrawingListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(drawingFilterControllerProvider.notifier).clearFilters();
    });
  }

  Future<void> _refresh() async {
    final filterState = ref.read(drawingFilterControllerProvider);
    final queryParams = DrawingQueryParams(
      projectId: filterState.projectId,
      levelId: filterState.levelId,
      status: filterState.status,
    );

    ref.invalidate(drawingCatalogProvider);
    ref.invalidate(drawingDrawingsProvider(queryParams));

    await Future.wait([
      ref.read(drawingCatalogProvider.future),
      ref.read(drawingDrawingsProvider(queryParams).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(drawingFilterControllerProvider);
    final catalogAsync = ref.watch(drawingCatalogProvider);
    final queryParams = DrawingQueryParams(
      projectId: filterState.projectId,
      levelId: filterState.levelId,
      status: filterState.status,
    );
    final drawingsAsync = ref.watch(drawingDrawingsProvider(queryParams));

    final projects = _uniqueProjects(catalogAsync.valueOrNull ?? const []);
    final levels = _uniqueLevels(catalogAsync.valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text('Drawing Management'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            const SizedBox(height: 2),
            const Text(
              'Project drawings, plans, and location markers in one place.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            DrawingFilterBar(
              projects: projects,
              levels: levels,
              selectedStatus: filterState.status,
              selectedProjectId: filterState.projectId,
              selectedLevelId: filterState.levelId,
              onProjectChanged: (value) {
                ref
                    .read(drawingFilterControllerProvider.notifier)
                    .setProjectId(value);
              },
              onLevelChanged: (value) {
                ref
                    .read(drawingFilterControllerProvider.notifier)
                    .setLevelId(value);
              },
              onStatusChanged: (value) {
                ref
                    .read(drawingFilterControllerProvider.notifier)
                    .setStatus(value);
              },
              onClear: () {
                ref
                    .read(drawingFilterControllerProvider.notifier)
                    .clearFilters();
              },
            ),
            const SizedBox(height: 12),
            if (catalogAsync.isLoading) ...[
              const _FilterSkeleton(),
              const SizedBox(height: 12),
            ] else if (catalogAsync.hasError) ...[
              _InlineErrorCard(
                message: catalogAsync.error.toString(),
                onRetry: _refresh,
              ),
              const SizedBox(height: 12),
            ],
            drawingsAsync.when(
              loading: () => const _DrawingListShimmer(),
              error: (error, _) => _InlineErrorCard(
                message: error.toString(),
                onRetry: _refresh,
              ),
              data: (drawings) {
                if (drawings.isEmpty) {
                  return const _EmptyState();
                }

                return Column(
                  children: [
                    for (final drawing in drawings) ...[
                      DrawingCard(
                        drawing: drawing,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DrawingViewerPage(drawing: drawing),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ProjectModel> _uniqueProjects(List<DrawingModel> drawings) {
    final byId = <int, ProjectModel>{};
    for (final drawing in drawings) {
      final project = drawing.project;
      if (project != null && project.id != 0) {
        byId[project.id] = project;
      }
    }

    final items = byId.values.toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  List<LevelModel> _uniqueLevels(List<DrawingModel> drawings) {
    final byId = <int, LevelModel>{};
    for (final drawing in drawings) {
      final level = drawing.level;
      if (level != null && level.id != 0) {
        byId[level.id] = level;
      }
    }

    final items = byId.values.toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 42,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'No drawings found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different project, level, or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _FilterSkeleton extends StatelessWidget {
  const _FilterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _PulseBlock(width: double.infinity, height: 18),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _PulseBlock(height: 52)),
              SizedBox(width: 10),
              Expanded(child: _PulseBlock(height: 52)),
              SizedBox(width: 10),
              Expanded(child: _PulseBlock(height: 52)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawingListShimmer extends StatelessWidget {
  const _DrawingListShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: Container(
            height: 136,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: const [
                _PulseBlock(width: 92, height: 110),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PulseBlock(width: 180, height: 16),
                      SizedBox(height: 10),
                      _PulseBlock(width: double.infinity, height: 12),
                      SizedBox(height: 6),
                      _PulseBlock(width: double.infinity, height: 12),
                      SizedBox(height: 6),
                      _PulseBlock(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseBlock extends StatefulWidget {
  final double? width;
  final double height;

  const _PulseBlock({this.width, required this.height});

  @override
  State<_PulseBlock> createState() => _PulseBlockState();
}

class _PulseBlockState extends State<_PulseBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.45 + (_controller.value * 0.25);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
