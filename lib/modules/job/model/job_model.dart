class JobModel {
  final int id;
  final String jobNo;
  final String reference;
  final String status;
  final String scheduledDate;
  final int formId;
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
      formName: json["form_name"] ?? "",
      projectName: json["project_name"] ?? "",
      projectCode: json["project_code"] ?? "",
      clientName: json["client_name"] ?? "",
      operativeName: json["operative_name"] ?? "",
    );
  }
}
