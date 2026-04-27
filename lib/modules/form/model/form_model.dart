class FormItem {
  final int id;
  final String name;
  final String? description;
  final List<FormFieldItem> fields;

  FormItem({
    required this.id,
    required this.name,
    this.description,
    this.fields = const [],
  });

  factory FormItem.fromJson(Map<String, dynamic> json) {
    return FormItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      description: json['description'],
      fields:
          (json['fields'] as List?)
              ?.map((e) => FormFieldItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FormFieldItem {
  final int id;
  final int sectionId;
  final String sectionTitle;
  final String fieldType;
  final String title;
  final bool isRequired;
  final int sortOrder;
  final Map<String, dynamic> settings;
  final List<FormFieldOption> options;

  FormFieldItem({
    required this.id,
    required this.sectionId,
    required this.sectionTitle,
    required this.fieldType,
    required this.title,
    required this.isRequired,
    required this.sortOrder,
    required this.settings,
    required this.options,
  });

  factory FormFieldItem.fromJson(Map<String, dynamic> json) {
    return FormFieldItem(
      id: json['id'] ?? 0,
      sectionId: json['section_id'] ?? 0,
      sectionTitle: json['section_title'] ?? '',
      fieldType: json['field_type'] ?? '',
      title: json['title'] ?? '',
      isRequired: json['is_required'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      settings: json['settings'] ?? {},
      options:
          (json['options'] as List?)
              ?.map((e) => FormFieldOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FormFieldOption {
  final int id;
  final String label;
  final String value;
  final int sortOrder;

  FormFieldOption({
    required this.id,
    required this.label,
    required this.value,
    required this.sortOrder,
  });

  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
