import 'package:flutter/material.dart';
import '../model/template_model.dart';
import '../../../services/template_services.dart';

// ─── Design Tokens (mirrored from forms screen) ───────────────────
class _AppColors {
  static const background = Color(0xFFF5F6FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE4E7EF);
  static const borderFocus = Color(0xFF3B7DFF);
  static const accent = Color(0xFF3B7DFF);
  static const accentLight = Color(0xFFEBF1FF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFB0B7C3);
  static const required = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFCA5A5);
  static const chipSelected = Color(0xFFEBF1FF);
  static const chipBorderSelected = Color(0xFF3B7DFF);
  static const switchActive = Color(0xFF3B7DFF);
}

class _AppTextStyles {
  static const appBarTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  static const sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _AppColors.accent,
    letterSpacing: 0.6,
  );
  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _AppColors.textSecondary,
    letterSpacing: 0.2,
  );
  static const inputText = TextStyle(
    fontSize: 14,
    color: _AppColors.textPrimary,
    height: 1.4,
  );
  static const hintText = TextStyle(fontSize: 14, color: _AppColors.textHint);
}

// ─── Shared Input Decoration ──────────────────────────────────────
InputDecoration _fieldDecoration({
  required String label,
  bool isRequired = false,
  String? hint,
  String? helper,
  Widget? suffixIcon,
}) {
  final labelWidget = RichText(
    text: TextSpan(
      text: label,
      style: _AppTextStyles.fieldLabel,
      children: isRequired
          ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: _AppColors.required, fontSize: 12),
              ),
            ]
          : [],
    ),
  );

  return InputDecoration(
    label: labelWidget,
    hintText: hint,
    helperText: helper,
    hintStyle: _AppTextStyles.hintText,
    helperStyle: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: _AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _AppColors.borderFocus, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _AppColors.required),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _AppColors.required, width: 1.5),
    ),
  );
}

// ─── Template Form Screen ─────────────────────────────────────────
class TemplateFormScreen extends StatefulWidget {
  final ProjectTemplateModel template;
  const TemplateFormScreen({super.key, required this.template});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _formData = {
      for (var field in widget.template.fields)
        field.key: field.defaultValue ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    // Group fields by section (sectionTitle or a fallback)
    final fieldsBySection = <String, List<TemplateFieldModel>>{};
    for (var field in widget.template.fields) {
      final section =
          (field.label != null && field.label!.isNotEmpty)
          ? field.label!
          : 'Details';
      fieldsBySection.putIfAbsent(section, () => []).add(field);
    }

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _AppColors.textPrimary),
        title: Text(
          widget.template.templateName,
          style: _AppTextStyles.appBarTitle,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  // ── Error Banner ─────────────────────────────────
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  // ── Sectioned Fields ──────────────────────────────
                  ...fieldsBySection.entries.expand((entry) {
                    return [
                      _SectionHeader(title: entry.key),
                      ...entry.value.map((f) => _buildField(f)),
                      const SizedBox(height: 8),
                    ];
                  }),
                ],
              ),
            ),
          ),
          // ── Submit Bar ────────────────────────────────────────────
          _SubmitBar(isSubmitting: _isSubmitting, onSubmit: _handleSubmit),
        ],
      ),
    );
  }

  Widget _buildField(TemplateFieldModel field) {
    final label = field.label;
    final isReq = field.requiredField;
    final hint = field.placeholder.isNotEmpty ? field.placeholder : null;
    final helper = field.helpText.isNotEmpty ? field.helpText : null;
    final key = field.key;

    switch (field.fieldType) {
      case 'text':
        return _FieldWrapper(
          child: TextFormField(
            initialValue: field.defaultValue,
            style: _AppTextStyles.inputText,
            cursorColor: _AppColors.accent,
            decoration: _fieldDecoration(
              label: label,
              isRequired: isReq,
              hint: hint,
              helper: helper,
            ),
            validator: isReq
                ? (val) =>
                      (val == null || val.isEmpty) ? '$label is required' : null
                : null,
            onSaved: (val) => _formData[key] = val ?? '',
          ),
        );

      case 'number':
        return _FieldWrapper(
          child: TextFormField(
            initialValue: field.defaultValue,
            keyboardType: TextInputType.number,
            style: _AppTextStyles.inputText,
            cursorColor: _AppColors.accent,
            decoration: _fieldDecoration(
              label: label,
              isRequired: isReq,
              hint: hint,
              helper: helper,
            ),
            validator: isReq
                ? (val) =>
                      (val == null || val.isEmpty) ? '$label is required' : null
                : null,
            onSaved: (val) => _formData[key] = val ?? '',
          ),
        );

      case 'textarea':
        return _FieldWrapper(
          child: TextFormField(
            initialValue: field.defaultValue,
            minLines: 3,
            maxLines: 5,
            style: _AppTextStyles.inputText,
            cursorColor: _AppColors.accent,
            decoration: _fieldDecoration(
              label: label,
              isRequired: isReq,
              hint: hint,
              helper: helper,
            ),
            validator: isReq
                ? (val) =>
                      (val == null || val.isEmpty) ? '$label is required' : null
                : null,
            onSaved: (val) => _formData[key] = val ?? '',
          ),
        );

      case 'select':
      case 'dropdown':
        return _FieldWrapper(
          child: DropdownButtonFormField<String>(
            value: (_formData[key] as String?)?.isNotEmpty == true
                ? _formData[key] as String
                : null,
            style: _AppTextStyles.inputText,
            dropdownColor: _AppColors.surface,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _AppColors.textSecondary,
            ),
            items: field.options
                .map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt.value?.toString() ?? '',
                    child: Text(opt.label),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _formData[key] = val ?? ''),
            decoration: _fieldDecoration(label: label, isRequired: isReq),
            validator: isReq
                ? (val) =>
                      (val == null || val.isEmpty) ? '$label is required' : null
                : null,
          ),
        );

      case 'multiselect':
        return _MultiSelectField(
          field: field,
          label: label,
          isRequired: isReq,
          selectedValues: (_formData[key] is List) ? _formData[key] : [],
          onChanged: (vals) => setState(() => _formData[key] = vals),
        );

      case 'date':
      case 'date_time':
        return _DateField(
          label: label,
          isRequired: isReq,
          value: _formData[key]?.toString().isNotEmpty == true
              ? _formData[key].toString()
              : null,
          onPicked: (val) => setState(() => _formData[key] = val),
        );

      case 'yes_no':
      case 'boolean':
        return _YesNoField(
          label: label,
          isRequired: isReq,
          value: _formData[key] == true || _formData[key] == 'true',
          onChanged: (val) => setState(() => _formData[key] = val),
        );

      case 'photos':
        return _PhotoField(label: label, isRequired: isReq);

      case 'signature':
        return _SignatureField(label: label, isRequired: isReq);

      default:
        return _FieldWrapper(
          child: Text(
            "Unsupported field type: ${field.fieldType}",
            style: const TextStyle(color: _AppColors.textSecondary),
          ),
        );
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final submissions = widget.template.fields
          .map(
            (field) => {
              'field_id': field.fieldId,
              'value': _formData[field.key],
            },
          )
          .toList();

      final response = await ProjectTemplateService.submitTemplate(
        projectId: widget.template.projectId,
        templateId: widget.template.templateId,
        submissions: submissions,
      );

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Form submitted successfully",
                    style: TextStyle(
                      color: _AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: _AppColors.surface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Submission failed.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ─── Error Banner ─────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _AppColors.required,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: _AppColors.required,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: _AppTextStyles.sectionTitle),
        ],
      ),
    );
  }
}

// ─── Field Wrapper ────────────────────────────────────────────────
class _FieldWrapper extends StatelessWidget {
  final Widget child;
  const _FieldWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }
}

// ─── Multi-select Field ───────────────────────────────────────────
class _MultiSelectField extends StatelessWidget {
  final TemplateFieldModel field;
  final String label;
  final bool isRequired;
  final List selectedValues;
  final ValueChanged<List> onChanged;

  const _MultiSelectField({
    required this.field,
    required this.label,
    required this.isRequired,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: _AppTextStyles.fieldLabel,
              children: isRequired
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: _AppColors.required,
                          fontSize: 12,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: field.options.map((opt) {
              final isSelected = selectedValues.contains(opt.value);
              return GestureDetector(
                onTap: () {
                  final updated = List.from(selectedValues);
                  if (isSelected) {
                    updated.remove(opt.value);
                  } else {
                    updated.add(opt.value);
                  }
                  onChanged(updated);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _AppColors.chipSelected
                        : _AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _AppColors.chipBorderSelected
                          : _AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? _AppColors.accent
                          : _AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Date Field ───────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? value;
  final ValueChanged<String> onPicked;

  const _DateField({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: _AppColors.accent,
                  onSurface: _AppColors.textPrimary,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            onPicked(picked.toString().split(" ")[0]);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: value != null
                    ? Text(value!, style: _AppTextStyles.inputText)
                    : RichText(
                        text: TextSpan(
                          text: label,
                          style: _AppTextStyles.fieldLabel,
                          children: isRequired
                              ? const [
                                  TextSpan(
                                    text: ' *',
                                    style: TextStyle(
                                      color: _AppColors.required,
                                      fontSize: 12,
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                      ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: _AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Yes/No Toggle ────────────────────────────────────────────────
class _YesNoField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _YesNoField({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: _AppTextStyles.inputText,
                  children: isRequired
                      ? const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: _AppColors.required,
                              fontSize: 12,
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: _AppColors.switchActive,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Upload Field ───────────────────────────────────────────
class _PhotoField extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _PhotoField({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: GestureDetector(
        onTap: () {
          // TODO: integrate image_picker
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: _AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.textPrimary,
                      ),
                      children: isRequired
                          ? const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: _AppColors.required,
                                  fontSize: 12,
                                ),
                              ),
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Tap to upload photos",
                    style: TextStyle(
                      fontSize: 12,
                      color: _AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Signature Field ──────────────────────────────────────────────
class _SignatureField extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _SignatureField({required this.label, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: _AppTextStyles.fieldLabel,
              children: isRequired
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: _AppColors.required,
                          fontSize: 12,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gesture_rounded,
                    color: _AppColors.textHint.withOpacity(0.5),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sign here",
                    style: TextStyle(fontSize: 13, color: _AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Submit Bar ───────────────────────────────────────────────────
class _SubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.isSubmitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        border: Border(top: BorderSide(color: _AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _AppColors.accent.withOpacity(0.6),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Submit Form"),
                  ],
                ),
        ),
      ),
    );
  }
}
