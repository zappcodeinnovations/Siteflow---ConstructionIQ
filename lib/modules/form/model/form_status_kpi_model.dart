class FormStatusKpiModel {
  final int totalForms;
  final int notSignature;
  final int submitted;
  final int pendingSignature;
  final int completed;
  final List<FormStatusKpiItem> kpis;
  final LatestSubmission? latestSubmission;

  const FormStatusKpiModel({
    required this.totalForms,
    required this.notSignature,
    required this.submitted,
    required this.pendingSignature,
    required this.completed,
    required this.kpis,
    required this.latestSubmission,
  });

  factory FormStatusKpiModel.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final kpiItems = (json['kpis'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => FormStatusKpiItem.fromJson(item.cast<String, dynamic>()))
        .toList();

    return FormStatusKpiModel(
      totalForms:
          _toInt(json['total_forms']) ??
          _toInt(json['totalForms']) ??
          _toInt(summary['completed']) ??
          _toInt(json['submitted']) ??
          0,
      notSignature:
          _toInt(summary['not_signature']) ??
          _toInt(json['not_signature']) ??
          _findCount(kpiItems, 'not_signature') ??
          0,
      submitted:
          _toInt(summary['submitted']) ??
          _toInt(json['submitted']) ??
          _findCount(kpiItems, 'submitted') ??
          0,
      pendingSignature:
          _toInt(summary['pending_signature']) ??
          _toInt(json['pending_signature']) ??
          _findCount(kpiItems, 'pending_signature') ??
          0,
      completed:
          _toInt(summary['completed']) ??
          _toInt(json['completed']) ??
          _findCount(kpiItems, 'completed') ??
          0,
      kpis: kpiItems,
      latestSubmission: json['latest_submission'] is Map
          ? LatestSubmission.fromJson(
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

  static int? _findCount(List<FormStatusKpiItem> items, String key) {
    for (final item in items) {
      if (item.key == key) return item.count;
    }
    return null;
  }
}

class FormStatusKpiItem {
  final String key;
  final String label;
  final int count;
  final String? color;
  final String? status;

  const FormStatusKpiItem({
    required this.key,
    required this.label,
    required this.count,
    this.color,
    this.status,
  });

  factory FormStatusKpiItem.fromJson(Map<String, dynamic> json) {
    return FormStatusKpiItem(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: FormStatusKpiModel._toInt(json['count']) ?? 0,
      color: json['color']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class LatestSubmission {
  final int id;
  final int formId;
  final String formName;
  final String status;
  final bool hasSignature;
  final DateTime? submittedAt;

  const LatestSubmission({
    required this.id,
    required this.formId,
    required this.formName,
    required this.status,
    required this.hasSignature,
    required this.submittedAt,
  });

  factory LatestSubmission.fromJson(Map<String, dynamic> json) {
    return LatestSubmission(
      id: FormStatusKpiModel._toInt(json['id']) ?? 0,
      formId: FormStatusKpiModel._toInt(json['form_id']) ?? 0,
      formName: (json['form_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      hasSignature: json['has_signature'] == true,
      submittedAt: DateTime.tryParse((json['submitted_at'] ?? '').toString()),
    );
  }
}
