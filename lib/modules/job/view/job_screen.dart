import 'package:euro_side/modules/templates/view/template_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../provider/job_provider.dart';
import '../model/job_model.dart';

const kBlue = Color(0xFF1B5EF7);
const kBlueSoft = Color(0xFFEEF3FF);
const kBg = Color(0xFFF7F9FC);
const kTextDark = Color(0xFF0D1B2A);
const kTextMid = Color(0xFF4B5A6E);
const kTextLight = Color(0xFF9AA8BA);
const kDivider = Color(0xFFE8EDF5);
const kWhite = Color(0xFFFFFFFF);

class JobListScreen extends ConsumerWidget {
  void _showClockOutSuccessToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF0FC47A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have successfully clocked out.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<bool> _isClockedInForThisProject(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool("isClockedIn") ?? false;
    final clockedInProjectId = prefs.getInt("clockedInProjectId");
    return isClockedIn && clockedInProjectId == projectId;
  }

  Future<void> _handleClockOut(BuildContext context) async {
    // Require template fill before clock out
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectTemplateScreen(projectId: projectId),
      ),
    );
    if (result == true) {
      // Only clock out if template was filled and submitted
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isClockedIn", false);
      await prefs.remove("clockedInProjectId");
      await prefs.remove("clockInStartMillis");
      if (context.mounted) {
        _showClockOutSuccessToast(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must fill the template to clock out.'),
          ),
        );
      }
    }
  }

  final int projectId; // ✅ ADD THIS

  const JobListScreen({
    super.key,
    required this.projectId, // ✅ ADD THIS
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobListProvider);

    return FutureBuilder<bool>(
      future: _isClockedInForThisProject(projectId),
      builder: (context, snapshot) {
        final showClockOut = snapshot.data == true;
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kWhite,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: kDivider,
            title: const Text(
              'Jobs',
              style: TextStyle(
                color: kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            centerTitle: false,
            actions: [
              if (showClockOut)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ElevatedButton(
                    onPressed: () => _handleClockOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Clock Out",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: jobAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _JobCard(job: jobs[index]),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: kBlue, strokeWidth: 2.5),
            ),
            error: (e, _) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: kTextLight,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Failed to load jobs',
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
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
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

          // ✅ OPTIONAL: Navigate to Job Detail (no UI change)
          onTap: () {
            debugPrint("Selected Job: ${job.id}");
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
                        'Job #${job.jobNo}',
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
                    _StatusChip(status: job.status),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  job.projectName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextMid,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  job.clientName,
                  style: const TextStyle(fontSize: 12.5, color: kTextLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                const Divider(color: kDivider, height: 1),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        job.formName,
                        style: const TextStyle(fontSize: 12.5, color: kTextMid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      job.scheduledDate,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 13, color: kTextLight),
                    const SizedBox(width: 4),
                    Text(
                      job.reference,
                      style: const TextStyle(fontSize: 12, color: kTextLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// باقي code unchanged
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return const Color(0xFF0FC47A);
      case 'completed':
      case 'closed':
        return kBlue;
      case 'pending':
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
          Icon(Icons.work_outline_rounded, size: 48, color: kTextLight),
          SizedBox(height: 14),
          Text(
            'No jobs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextMid,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Jobs will appear here once assigned.',
            style: TextStyle(fontSize: 13, color: kTextLight),
          ),
        ],
      ),
    );
  }
}
