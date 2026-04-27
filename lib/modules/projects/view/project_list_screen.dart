import 'package:euro_side/modules/clock_in/view/clock_in_screen.dart';
import 'package:euro_side/modules/form/view/form_screen.dart';
import 'package:euro_side/modules/job/view/job_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/project_provider.dart';
import '../model/project_model.dart';

const kBlue = Color(0xFF1B5EF7);
const kBlueSoft = Color(0xFFEEF3FF);
const kBg = Color(0xFFF7F9FC);
const kTextDark = Color(0xFF0D1B2A);
const kTextMid = Color(0xFF4B5A6E);
const kTextLight = Color(0xFF9AA8BA);
const kDivider = Color(0xFFE8EDF5);
const kWhite = Color(0xFFFFFFFF);

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  void _showFabModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔥 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Create item",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  Row(
                    children: [
                      // _iconButton(Icons.tune),
                      const SizedBox(width: 8),
                      _iconButton(
                        Icons.close,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔥 LIST ITEMS
              // _itemTile(
              //   icon: Icons.remove_red_eye_outlined,
              //   title: "Observation",
              //   onTap: () {},
              // ),

              // _divider(),

              // _itemTile(
              //   icon: Icons.checklist_rounded,
              //   title: "Inspection",
              //   onTap: () {},
              // ),

              _divider(),

              _itemTile(
                icon: Icons.description_outlined,
                title: "Forms",
                onTap: () {
                  Navigator.pop(context);
                  // Navigator.pushNamed(context, '/forms');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormsScreen()
                    ),
                  );
                },
              ),

              _divider(),

              // _itemTile(
              //   icon: Icons.note_alt_outlined,
              //   title: "Notes log",
              //   onTap: () {},
              // ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _itemTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Icon(Icons.add, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 0.8);
  }

  Widget _iconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  String _selectedStatus = 'all';
  String _selectedPriority = 'all';

  List<ProjectModel> _applyFilters(List<ProjectModel> projects) {
    return projects.where((project) {
      final status = project.status.toLowerCase().trim();
      final priority = project.priority.toLowerCase().trim();

      final statusMatches =
          _selectedStatus == 'all' || status == _selectedStatus;
      final priorityMatches =
          _selectedPriority == 'all' || priority == _selectedPriority;

      return statusMatches && priorityMatches;
    }).toList();
  }

  Future<void> _openMoreFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'More Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextMid,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(
                    label: 'All Priority',
                    selected: _selectedPriority == 'all',
                    onTap: () {
                      setState(() => _selectedPriority = 'all');
                      Navigator.pop(sheetContext);
                    },
                  ),
                  _filterChip(
                    label: 'High',
                    selected: _selectedPriority == 'high',
                    onTap: () {
                      setState(() => _selectedPriority = 'high');
                      Navigator.pop(sheetContext);
                    },
                  ),
                  _filterChip(
                    label: 'Medium',
                    selected: _selectedPriority == 'medium',
                    onTap: () {
                      setState(() => _selectedPriority = 'medium');
                      Navigator.pop(sheetContext);
                    },
                  ),
                  _filterChip(
                    label: 'Low',
                    selected: _selectedPriority == 'low',
                    onTap: () {
                      setState(() => _selectedPriority = 'low');
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _selectedPriority = 'all';
                      Navigator.pop(sheetContext);
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kBlue : kBlueSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kBlue : kDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? kWhite : kTextMid,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectListProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: kDivider,
        title: const Text(
          'Projects',
          style: TextStyle(
            color: kTextDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
      ),
      body: projectAsync.when(
        data: (projects) {
          final filteredProjects = _applyFilters(projects);

          if (projects.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    _filterChip(
                      label: 'All',
                      selected: _selectedStatus == 'all',
                      onTap: () => setState(() => _selectedStatus = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Pending',
                      selected: _selectedStatus == 'pending',
                      onTap: () => setState(() => _selectedStatus = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Active',
                      selected: _selectedStatus == 'active',
                      onTap: () => setState(() => _selectedStatus = 'active'),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Completed',
                      selected: _selectedStatus == 'completed',
                      onTap: () =>
                          setState(() => _selectedStatus = 'completed'),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Incomplete',
                      selected: _selectedStatus == 'incomplete',
                      onTap: () =>
                          setState(() => _selectedStatus = 'incomplete'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('More'),
                      labelStyle: const TextStyle(
                        color: kTextMid,
                        fontWeight: FontWeight.w600,
                      ),
                      avatar: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: kTextMid,
                      ),
                      backgroundColor: kBlueSoft,
                      side: const BorderSide(color: kDivider),
                      onPressed: _openMoreFilters,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredProjects.isEmpty
                    ? const Center(
                        child: Text(
                          'No projects match current filters.',
                          style: TextStyle(color: kTextMid),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: filteredProjects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _ProjectCard(project: filteredProjects[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: kBlue, strokeWidth: 2.5),
        ),
        error: (e, _) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: kTextLight, size: 40),
              SizedBox(height: 12),
              Text(
                'Failed to load projects',
                style: TextStyle(
                  color: kTextMid,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabModal,
        backgroundColor: kBlue,
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ✅ CHANGED: Stateless → ConsumerWidget
class _ProjectCard extends ConsumerWidget {
  static const String _clockedInKey = "isClockedIn";
  static const String _clockedInProjectIdKey = "clockedInProjectId";

  final ProjectModel project;
  const _ProjectCard({required this.project});

  Future<void> openMap(BuildContext context, double lat, double lng) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map app.')),
        );
      }
    } on PlatformException catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map feature is not ready. Restart app once.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open location.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: kBlueSoft,
          highlightColor: Colors.transparent,

          // ✅ MAIN LOGIC ADDED HERE
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            final isClockedIn = prefs.getBool(_clockedInKey) ?? false;
            final clockedInProjectId = prefs.getInt(_clockedInProjectIdKey);

            if (isClockedIn && clockedInProjectId == project.id) {
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobListScreen(projectId: project.id),
                ),
              );
              return;
            }

            if (isClockedIn &&
                clockedInProjectId != null &&
                clockedInProjectId != project.id) {
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                  title: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF5A623),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Active Clock-In',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF0D1B2A),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'You already have an active clock-in on another project. Please clock out first.',
                    style: TextStyle(
                      fontSize: 15.5,
                      color: Color(0xFF4B5A6E),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1B5EF7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return;
            }

            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClockInScreen(
                  projectId: project.id,
                  projectName: project.name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PriorityDot(priority: project.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.clientName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: kDivider, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${project.city}, ${project.country}',
                        style: const TextStyle(fontSize: 12.5, color: kTextMid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusChip(status: project.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project.siteAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextLight,
                    height: 1.45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final lat = double.tryParse(project.latitude);
                    final lng = double.tryParse(project.longitude);

                    if (lat == null || lng == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invalid project location coordinates.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    await openMap(context, lat, lng);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 13, color: kBlue),
                      SizedBox(width: 5),
                      Text(
                        'View on Map',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: kBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

// باقي code same (no change)
class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot({required this.priority});

  Color get _color {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE8344A);
      case 'medium':
        return const Color(0xFFF5A623);
      case 'low':
        return const Color(0xFF0FC47A);
      default:
        return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          priority,
          style: TextStyle(
            fontSize: 12,
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF0FC47A);
      case 'completed':
        return kBlue;
      case 'on hold':
        return const Color(0xFFF5A623);
      default:
        return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: kTextLight),
          SizedBox(height: 14),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextMid,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Projects will appear here once added.',
            style: TextStyle(fontSize: 13, color: kTextLight),
          ),
        ],
      ),
    );
  }
}
