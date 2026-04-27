class ProjectTemplateModel {
  final int projectId;
  final String projectCode;
  final String projectName;
  final String projectStatus;
  final int templateId;
  final String templateName;
  final String? templateSlug;
  final String clientName;
  final String templateStatus;
  final String? description;
  final String? templateCreatedAt;
  final String? templateUpdatedAt;
  final List<TemplateFieldModel> fields;

  ProjectTemplateModel({
    required this.projectId,
    required this.projectCode,
    required this.projectName,
    required this.projectStatus,
    required this.templateId,
    required this.templateName,
    required this.templateSlug,
    required this.clientName,
    required this.templateStatus,
    required this.description,
    required this.templateCreatedAt,
    required this.templateUpdatedAt,
    required this.fields,
  });

  factory ProjectTemplateModel.fromJson(Map<String, dynamic> json) {
    return ProjectTemplateModel(
      projectId: json['project_id'] ?? 0,
      projectCode: json['project_code'] ?? "",
      projectName: json['project_name'] ?? "",
      projectStatus: json['project_status'] ?? "",
      templateId: json['template_id'] ?? 0,
      templateName: json['template_name'] ?? "",
      templateSlug: json['template_slug'],
      clientName: json['client_name'] ?? "",
      templateStatus: json['template_status'] ?? "",
      description: json['description'],
      templateCreatedAt: json['template_created_at'],
      templateUpdatedAt: json['template_updated_at'],
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((e) => TemplateFieldModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TemplateFieldModel {
  final int fieldId;
  final String key;
  final String scope;
  final String label;
  final String name;
  final String fieldType;
  final String placeholder;
  final String defaultValue;
  final bool requiredField;
  final int order;
  final String helpText;
  final bool isActive;
  final List<dynamic> options;
  final Map<String, dynamic> extraConfig;

  TemplateFieldModel({
    required this.fieldId,
    required this.key,
    required this.scope,
    required this.label,
    required this.name,
    required this.fieldType,
    required this.placeholder,
    required this.defaultValue,
    required this.requiredField,
    required this.order,
    required this.helpText,
    required this.isActive,
    required this.options,
    required this.extraConfig,
  });

  factory TemplateFieldModel.fromJson(Map<String, dynamic> json) {
    return TemplateFieldModel(
      fieldId: json['field_id'] ?? 0,
      key: json['key'] ?? '',
      scope: json['scope'] ?? '',
      label: json['label'] ?? '',
      name: json['name'] ?? '',
      fieldType: json['field_type'] ?? '',
      placeholder: json['placeholder'] ?? '',
      defaultValue: json['default_value'] ?? '',
      requiredField: json['required'] ?? false,
      order: json['order'] ?? 0,
      helpText: json['help_text'] ?? '',
      isActive: json['is_active'] ?? false,
      options: json['options'] ?? [],
      extraConfig: json['extra_config'] ?? {},
    );
  }
}
