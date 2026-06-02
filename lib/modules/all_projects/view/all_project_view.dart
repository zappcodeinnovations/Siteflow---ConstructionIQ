import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:euroside/modules/all_projects/provider/all_project_provider.dart';
import 'package:euroside/modules/all_projects/view/project_details_view.dart';
import 'package:euroside/modules/clock_in/view/clock_in_screen.dart';
import 'package:euroside/services/current_clock_session_service.dart';
import 'package:euroside/screens/nav_bar/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Design Tokens (shared with forms_screen.dart) ───────────────
class _C {
  static const background = Color(0xFFF4F5F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFEAECF0);
  static const borderInner = Color(0xFFF3F4F6);
  static const accent = Color(0xFF2563EB);
  static const accentLight = Color(0xFFEFF6FF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFC0C4CF);

  // Status
  static const statusActive = Color(0xFF16A34A);
  static const statusActiveBg = Color(0xFFF0FDF4);
  static const statusActiveBdr = Color(0xFFBBF7D0);

  static const statusCompleted = Color(0xFF2563EB);
  static const statusCompletedBg = Color(0xFFEFF6FF);
  static const statusCompletedBdr = Color(0xFFBFDBFE);

  static const statusPending = Color(0xFFEA580C);
  static const statusPendingBg = Color(0xFFFFF7ED);
  static const statusPendingBdr = Color(0xFFFED7AA);

  static const statusCritical = Color(0xFFDC2626);
  static const statusCriticalBg = Color(0xFFFEF2F2);
  static const statusCriticalBdr = Color(0xFFFECACA);

  static const statusDefault = Color(0xFF6B7280);
  static const statusDefaultBg = Color(0xFFF3F4F6);
  static const statusDefaultBdr = Color(0xFFE5E7EB);

  // Priority
  static const priorityCritical = Color(0xFFDC2626);
  static const priorityCriticalBg = Color(0xFFFEF2F2);
  static const priorityCriticalBdr = Color(0xFFFECACA);

  static const priorityHigh = Color(0xFFF97316);
  static const priorityHighBg = Color(0xFFFFF7ED);
  static const priorityHighBdr = Color(0xFFFED7AA);

  static const priorityMedium = Color(0xFFD97706);
  static const priorityMediumBg = Color(0xFFFFFBEB);
  static const priorityMediumBdr = Color(0xFFFDE68A);

  static const priorityLow = Color(0xFF16A34A);
  static const priorityLowBg = Color(0xFFF0FDF4);
  static const priorityLowBdr = Color(0xFFBBF7D0);

  // Snackbar error
  static const errorBg = Color(0xFFFEF2F2);
  static const errorBdr = Color(0xFFFECACA);
  static const errorFg = Color(0xFF991B1B);
  static const errorSub = Color(0xFF7F1D1D);
  static const errorIcon = Color(0xFFDC2626);
}

// ─── Chip config ────────────────────────────────────────────────
class _ChipConfig {
  final Color text, bg, border;
  const _ChipConfig({
    required this.text,
    required this.bg,
    required this.border,
  });
}

_ChipConfig _statusChip(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return const _ChipConfig(
        text: _C.statusActive,
        bg: _C.statusActiveBg,
        border: _C.statusActiveBdr,
      );
    case 'completed':
      return const _ChipConfig(
        text: _C.statusCompleted,
        bg: _C.statusCompletedBg,
        border: _C.statusCompletedBdr,
      );
    case 'pending':
      return const _ChipConfig(
        text: _C.statusPending,
        bg: _C.statusPendingBg,
        border: _C.statusPendingBdr,
      );
    case 'critical':
      return const _ChipConfig(
        text: _C.statusCritical,
        bg: _C.statusCriticalBg,
        border: _C.statusCriticalBdr,
      );
    default:
      return const _ChipConfig(
        text: _C.statusDefault,
        bg: _C.statusDefaultBg,
        border: _C.statusDefaultBdr,
      );
  }
}

_ChipConfig _priorityChip(String priority) {
  switch (priority.toLowerCase()) {
    case 'critical':
      return const _ChipConfig(
        text: _C.priorityCritical,
        bg: _C.priorityCriticalBg,
        border: _C.priorityCriticalBdr,
      );
    case 'high':
      return const _ChipConfig(
        text: _C.priorityHigh,
        bg: _C.priorityHighBg,
        border: _C.priorityHighBdr,
      );
    case 'medium':
      return const _ChipConfig(
        text: _C.priorityMedium,
        bg: _C.priorityMediumBg,
        border: _C.priorityMediumBdr,
      );
    case 'low':
      return const _ChipConfig(
        text: _C.priorityLow,
        bg: _C.priorityLowBg,
        border: _C.priorityLowBdr,
      );
    default:
      return const _ChipConfig(
        text: _C.statusDefault,
        bg: _C.statusDefaultBg,
        border: _C.statusDefaultBdr,
      );
  }
}

// ─── Page ────────────────────────────────────────────────────────
class AllProjectListPage extends ConsumerStatefulWidget {
  const AllProjectListPage({super.key});

  @override
  ConsumerState<AllProjectListPage> createState() => _AllProjectListPageState();
}

class _AllProjectListPageState extends ConsumerState<AllProjectListPage> {
  String _search = '';

  void _goToNavigationShell() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _refreshProjects() async {
    await ref
        .read(AllprojectControllerProvider.notifier)
        .fetchProjects(force: true);
  }

  Future<void> _handleProjectTap(AllprojectModel project) async {
    final session = await CurrentClockSessionService.fetchCurrentSession();

    if (session.isClockedIn && session.data != null) {
      final activeProjectId = session.data!.projectId;

      if (activeProjectId == project.id) {
        if (!mounted) return;
        _openProjectDetails(project);
        return;
      }

      if (!mounted) return;
      _showClockInActiveSnackbar();
      return;
    }

    if (!mounted) return;

    final canOpenDetails = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClockInScreen(
          projectId: project.id,
          projectName: project.name,
          returnOnSuccess: true,
        ),
      ),
    );

    if (canOpenDetails == true && mounted) {
      _openProjectDetails(project);
    }
  }

  void _showClockInActiveSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _C.errorBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.errorBdr),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.errorIcon.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: _C.errorIcon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Clock-in active",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.errorFg,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "You're clocked in on another project. Please clock out first.",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _C.errorSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProjectDetails(AllprojectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProjectDetailsPage(
          projectId: project.id,
          initialProject: project,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(AllprojectControllerProvider);

    final filtered = _search.trim().isEmpty
        ? state.projects
        : state.projects
              .where(
                (p) => p.name.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();

    return WillPopScope(
      onWillPop: () async {
        _goToNavigationShell();
        return false;
      },
      child: Scaffold(
        backgroundColor: _C.background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _C.surface,
          centerTitle: false,
          leading: IconButton(
            onPressed: _goToNavigationShell,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _C.textPrimary,
          ),
          title: const Text(
            "Projects",
            style: TextStyle(
              color: _C.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _C.border),
          ),
        ),
        body: state.isLoading && state.projects.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: _C.accent,
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                color: _C.accent,
                onRefresh: _refreshProjects,
                child: CustomScrollView(
                  slivers: [
                    // ── Summary + Search header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats row
                            // if (state.projects.isNotEmpty)
                            //   _StatsRow(projects: state.projects),
                            const SizedBox(height: 12),

                            // Search bar
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _C.border),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _C.textPrimary,
                                ),
                                cursorColor: _C.accent,
                                decoration: const InputDecoration(
                                  hintText: "Search projects…",
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: _C.textHint,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: _C.textHint,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),

                    // ── Project list ──
                    state.projects.isEmpty
                        ? SliverFillRemaining(child: _emptyState())
                        : filtered.isEmpty
                        ? SliverFillRemaining(child: _noResultsState(_search))
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final project = filtered[index];
                                final isLast = index == filtered.length - 1;
                                return _ProjectCard(
                                  project: project,
                                  isLast: isLast,
                                  onTap: () => _handleProjectTap(project),
                                );
                              }, childCount: filtered.length),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 34,
                color: _C.textHint,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No projects yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Your projects will appear here once created.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: _C.textHint,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No results",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No projects match \"$query\"",
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<AllprojectModel> projects;
  const _StatsRow({required this.projects});

  @override
  Widget build(BuildContext context) {
    final active = projects
        .where((p) => p.status.toLowerCase() == 'active')
        .length;
    final pending = projects
        .where((p) => p.status.toLowerCase() == 'pending')
        .length;
    final completed = projects
        .where((p) => p.status.toLowerCase() == 'completed')
        .length;

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          _StatCell(label: "Total", value: "${projects.length}", isFirst: true),
          _Divider(),
          _StatCell(label: "Active", value: "$active", accent: _C.statusActive),
          _Divider(),
          _StatCell(
            label: "Pending",
            value: "$pending",
            accent: _C.statusPending,
          ),
          _Divider(),
          _StatCell(
            label: "Done",
            value: "$completed",
            accent: _C.statusCompleted,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  final bool isFirst;
  final bool isLast;

  const _StatCell({
    required this.label,
    required this.value,
    this.accent,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accent ?? _C.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _C.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: _C.borderInner);
  }
}

// ─── Project Card ─────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final AllprojectModel project;
  final bool isLast;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusCfg = _statusChip(project.status);
    final priorityCfg = _priorityChip(project.priority);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_copy_rounded,
                    color: _C.accent,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          _Chip(label: project.status, cfg: statusCfg),
                          const SizedBox(width: 6),
                          _Chip(
                            label: project.priority,
                            cfg: priorityCfg,
                            isPriority: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final _ChipConfig cfg;
  final bool isPriority;

  const _Chip({
    required this.label,
    required this.cfg,
    this.isPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = _formatLabel(label);
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cfg.border),
        boxShadow: [
          BoxShadow(
            color: cfg.text.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cfg.text, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          if (isPriority) ...[
            Container(
              width: 1,
              height: 12,
              decoration: BoxDecoration(
                color: cfg.text.withOpacity(0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: cfg.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return 'Unknown';
    }

    if (text.length == 1) {
      return text.toUpperCase();
    }

    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
