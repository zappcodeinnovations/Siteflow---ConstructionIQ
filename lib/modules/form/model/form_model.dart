class FormItem {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final List<FormFieldItem> fields;

  FormItem({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.fields = const [],
  });

  factory FormItem.fromJson(Map<String, dynamic> json) {
    return FormItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? "",
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      sectionId: int.tryParse(json['section_id']?.toString() ?? '') ?? 0,
      sectionTitle: json['section_title']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isRequired: json['is_required'] == true,
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      settings: (json['settings'] as Map?)?.cast<String, dynamic>() ?? {},
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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
    );
  }
}
