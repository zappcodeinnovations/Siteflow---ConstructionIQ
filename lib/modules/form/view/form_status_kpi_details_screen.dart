import 'package:euroside/services/form_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class FormStatusKpiDetailsScreen extends StatefulWidget {
  const FormStatusKpiDetailsScreen({super.key});

  @override
  State<FormStatusKpiDetailsScreen> createState() =>
      _FormStatusKpiDetailsScreenState();
}

class _FormStatusKpiDetailsScreenState
    extends State<FormStatusKpiDetailsScreen> {
  late Future<FormStatusOverview> _future;

  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF111318);
  static const Color _ink2 = Color(0xFF6B7280);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _accentLight = Color(0xFFEFF4FF);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<FormStatusOverview> _loadData() async {
    final response = await FormService.getFormStatusKpi();
    return FormStatusOverview.fromJson(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Form Status Overview',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<FormStatusOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Failed to load form status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: _ink2),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _buildSummaryGrid(data),
                const SizedBox(height: 24),
                _sectionHeader('Projects', Icons.business_center_outlined),
                const SizedBox(height: 12),
                if (data.projects.isEmpty)
                  _buildEmptyState()
                else
                  ...data.projects.map(
                    (project) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildProjectCard(project),
                    ),
                  ),
                if (data.latestSubmission != null) ...[
                  const SizedBox(height: 10),
                  _sectionHeader('Latest Submission', Iconsax.document_text),
                  const SizedBox(height: 12),
                  _buildLatestSubmissionCard(data.latestSubmission!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(FormStatusOverview data) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
          label: 'Total Selected',
          value: data.totalSelectedForms,
          icon: Iconsax.task_square,
          color: const Color(0xFF2563EB),
        ),
        _summaryCard(
          label: 'Submitted',
          value: data.submittedForms,
          icon: Iconsax.tick_circle,
          color: const Color(0xFF059669),
        ),
        _summaryCard(
          label: 'Completed',
          value: data.completedForms,
          icon: Iconsax.verify,
          color: const Color(0xFF10B981),
        ),
        _summaryCard(
          label: 'Pending Signature',
          value: data.notSignatureForms,
          icon: Iconsax.warning_2,
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width > 420
          ? (MediaQuery.of(context).size.width - 52) / 2
          : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, color: _ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _ink2),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Iconsax.folder_open, color: _accent, size: 26),
          ),
          const SizedBox(height: 12),
          const Text(
            'No project task data available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selected forms will appear here by project and task when available.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.45, color: _ink2),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(FormStatusProject project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Project ID: ${project.projectId} • ${project.taskCount} task(s)',
                      style: const TextStyle(fontSize: 12, color: _ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...project.tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskCard(task),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(FormStatusTask task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.briefcase,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.taskName.isEmpty ? 'Untitled task' : task.taskName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.jobDisplayNo.isEmpty ? task.jobNo : task.jobDisplayNo} • ${task.formCount} form(s)',
                      style: const TextStyle(fontSize: 12, color: _ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...task.forms.map(
            (form) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFormRow(form),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(FormStatusForm form) {
    final statusColor = _statusColor(form.statusKey);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.document_text,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.formName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      form.submittedAt == null
                          ? 'Not submitted yet'
                          : 'Submitted on ${DateFormat('dd MMM yyyy, hh:mm a').format(form.submittedAt!.toLocal())}',
                      style: const TextStyle(fontSize: 11.5, color: _ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(form.status, statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                icon: form.operatorSigned
                    ? Iconsax.tick_circle
                    : Iconsax.close_circle,
                label: form.operatorSigned
                    ? 'Operator signed'
                    : 'Operator pending',
                color: form.operatorSigned
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
              _infoChip(
                icon: form.clientSigned
                    ? Iconsax.tick_circle
                    : Iconsax.close_circle,
                label: form.clientSigned ? 'Client signed' : 'Client pending',
                color: form.clientSigned
                    ? const Color(0xFF059669)
                    : const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestSubmissionCard(LatestSubmissionData item) {
    final statusColor = _statusColor(item.statusKey);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Iconsax.document_text, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.formName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.submittedAt == null
                      ? 'No submission date available'
                      : DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(item.submittedAt!.toLocal()),
                  style: const TextStyle(fontSize: 11.5, color: _ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String statusKey) {
    switch (statusKey.toLowerCase()) {
      case 'submitted':
        return const Color(0xFF059669);
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF97316);
      case 'attention_required':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class FormStatusOverview {
  final int totalSelectedForms;
  final int submittedForms;
  final int completedForms;
  final int notSignatureForms;
  final int totalForms;
  final int projectCount;
  final List<FormStatusProject> projects;
  final List<FormStatusMetric> kpis;
  final LatestSubmissionData? latestSubmission;

  const FormStatusOverview({
    required this.totalSelectedForms,
    required this.submittedForms,
    required this.completedForms,
    required this.notSignatureForms,
    required this.totalForms,
    required this.projectCount,
    required this.projects,
    required this.kpis,
    required this.latestSubmission,
  });

  factory FormStatusOverview.fromJson(Map<String, dynamic> json) {
    return FormStatusOverview(
      totalSelectedForms: _toInt(json['total_selected_forms']) ?? 0,
      submittedForms: _toInt(json['submitted_forms']) ?? 0,
      completedForms: _toInt(json['completed_forms']) ?? 0,
      notSignatureForms: _toInt(json['not_signature_forms']) ?? 0,
      totalForms: _toInt(json['total_forms']) ?? 0,
      projectCount: _toInt(json['project_count']) ?? 0,
      projects: (json['projects'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => FormStatusProject.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      kpis: (json['kpis'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => FormStatusMetric.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      latestSubmission: json['latest_submission'] is Map
          ? LatestSubmissionData.fromJson(
              (json['latest_submission'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class FormStatusMetric {
  final String key;
  final String label;
  final int count;
  final String color;
  final String status;

  const FormStatusMetric({
    required this.key,
    required this.label,
    required this.count,
    required this.color,
    required this.status,
  });

  factory FormStatusMetric.fromJson(Map<String, dynamic> json) {
    return FormStatusMetric(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: FormStatusOverview._toInt(json['count']) ?? 0,
      color: (json['color'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class FormStatusProject {
  final int projectId;
  final String projectName;
  final int taskCount;
  final List<FormStatusTask> tasks;

  const FormStatusProject({
    required this.projectId,
    required this.projectName,
    required this.taskCount,
    required this.tasks,
  });

  factory FormStatusProject.fromJson(Map<String, dynamic> json) {
    return FormStatusProject(
      projectId: FormStatusOverview._toInt(json['project_id']) ?? 0,
      projectName: (json['project_name'] ?? '').toString(),
      taskCount: FormStatusOverview._toInt(json['task_count']) ?? 0,
      tasks: (json['tasks'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FormStatusTask.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FormStatusTask {
  final int taskId;
  final String taskName;
  final String jobNo;
  final String jobDisplayNo;
  final int formCount;
  final List<FormStatusForm> forms;

  const FormStatusTask({
    required this.taskId,
    required this.taskName,
    required this.jobNo,
    required this.jobDisplayNo,
    required this.formCount,
    required this.forms,
  });

  factory FormStatusTask.fromJson(Map<String, dynamic> json) {
    return FormStatusTask(
      taskId: FormStatusOverview._toInt(json['task_id']) ?? 0,
      taskName: (json['task_name'] ?? '').toString(),
      jobNo: (json['job_no'] ?? '').toString(),
      jobDisplayNo: (json['job_display_no'] ?? '').toString(),
      formCount: FormStatusOverview._toInt(json['form_count']) ?? 0,
      forms: (json['forms'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FormStatusForm.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FormStatusForm {
  final int formId;
  final String formName;
  final String status;
  final String statusKey;
  final DateTime? submittedAt;
  final bool operatorSigned;
  final bool clientSigned;

  const FormStatusForm({
    required this.formId,
    required this.formName,
    required this.status,
    required this.statusKey,
    required this.submittedAt,
    required this.operatorSigned,
    required this.clientSigned,
  });

  factory FormStatusForm.fromJson(Map<String, dynamic> json) {
    return FormStatusForm(
      formId: FormStatusOverview._toInt(json['form_id']) ?? 0,
      formName: (json['form_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusKey: (json['status_key'] ?? '').toString(),
      submittedAt: DateTime.tryParse((json['submitted_at'] ?? '').toString()),
      operatorSigned: json['operator_signed'] == true,
      clientSigned: json['client_signed'] == true,
    );
  }
}

class LatestSubmissionData {
  final int id;
  final int formId;
  final String formName;
  final String status;
  final String statusKey;
  final bool hasSignature;
  final bool operatorSigned;
  final bool clientSigned;
  final DateTime? submittedAt;

  const LatestSubmissionData({
    required this.id,
    required this.formId,
    required this.formName,
    required this.status,
    required this.statusKey,
    required this.hasSignature,
    required this.operatorSigned,
    required this.clientSigned,
    required this.submittedAt,
  });

  factory LatestSubmissionData.fromJson(Map<String, dynamic> json) {
    return LatestSubmissionData(
      id: FormStatusOverview._toInt(json['id']) ?? 0,
      formId: FormStatusOverview._toInt(json['form_id']) ?? 0,
      formName: (json['form_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusKey: (json['status_key'] ?? '').toString(),
      hasSignature: json['has_signature'] == true,
      operatorSigned: json['operator_signed'] == true,
      clientSigned: json['client_signed'] == true,
      submittedAt: DateTime.tryParse((json['submitted_at'] ?? '').toString()),
    );
  }
}
