class JobModel {
  final int id;
  final String jobNo;
  final String reference;
  final String status;
  final String scheduledDate;
  final int formId;
  final List<int> formIds;
  final List<SelectedFormModel> selectedForms;
  final String formName;
  final String projectName;
  final String projectCode;
  final String clientName;
  final String operativeName;

  JobModel({
    required this.id,
    required this.jobNo,
    required this.reference,
    required this.status,
    required this.scheduledDate,
    required this.formId,
    this.formIds = const [],
    this.selectedForms = const [],
    required this.formName,
    required this.projectName,
    required this.projectCode,
    required this.clientName,
    required this.operativeName,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json["id"] ?? 0,
      jobNo: json["job_no"] ?? "",
      reference: json["reference"] ?? "",
      status: json["status"] ?? "",
      scheduledDate: json["scheduled_date"] ?? "",
      formId: json["form_id"] ?? 0,
      formIds:
          (json["form_ids"] as List?)
              ?.map((value) => int.tryParse(value.toString()) ?? 0)
              .where((value) => value > 0)
              .toList() ??
          [],
      selectedForms:
          (json["selected_forms"] as List?)
              ?.map((value) => SelectedFormModel.fromJson(value))
              .toList() ??
          [],
      formName: json["form_name"] ?? "",
      projectName: json["project_name"] ?? "",
      projectCode: json["project_code"] ?? "",
      clientName: json["client_name"] ?? "",
      operativeName: json["operative_name"] ?? "",
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }
}

class SelectedFormModel {
  final int id;
  final String name;
  final String slug;

  const SelectedFormModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory SelectedFormModel.fromJson(Map<String, dynamic> json) {
    return SelectedFormModel(
      id: JobModel._toInt(json['id']),
      name: JobModel._toString(json['name']),
      slug: JobModel._toString(json['slug']),
    );
  }
}
