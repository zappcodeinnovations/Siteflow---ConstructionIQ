import 'dart:io';
import 'dart:ui';

import 'package:euro_side/modules/form/model/form_model.dart';
import 'package:euro_side/modules/form/provider/form_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ─── Design Tokens ───────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFFF5F6FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE4E7EF);
  static const borderFocus = Color(0xFF3B7DFF);
  static const accent = Color(0xFF3B7DFF);
  static const accentLight = Color(0xFFEBF1FF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFFB0B7C3);
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFECFDF5);
  static const required = Color(0xFFEF4444);
  static const chipSelected = Color(0xFFEBF1FF);
  static const chipBorderSelected = Color(0xFF3B7DFF);
  static const switchActive = Color(0xFF3B7DFF);
  static const sectionDivider = Color(0xFFF0F1F5);
}

class AppTextStyles {
  static const appBarTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  static const sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
    letterSpacing: 0.6,
  );
  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
  static const inputText = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  static const hintText = TextStyle(
    fontSize: 14,
    color: AppColors.textHint,
  );
  static const listTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const listSubtitle = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}

// ─── Shared Input Decoration ─────────────────────────────────────
InputDecoration _fieldDecoration({
  required String label,
  bool isRequired = false,
  Widget? suffixIcon,
  String? hint,
}) {
  final labelWidget = RichText(
    text: TextSpan(
      text: label,
      style: AppTextStyles.fieldLabel,
      children: isRequired
          ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.required, fontSize: 12),
              )
            ]
          : [],
    ),
  );

  return InputDecoration(
    label: labelWidget,
    hintText: hint,
    hintStyle: AppTextStyles.hintText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
    ),
  );
}

// ─── Forms List Screen ──────────────────────────────────────────
class FormsScreen extends ConsumerWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(formsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text("Forms", style: AppTextStyles.appBarTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: formsAsync.when(
        data: (forms) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: forms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final form = forms[index];
            return _FormCard(form: form);
          },
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final FormItem form;
  const _FormCard({required this.form});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FormDetailScreen(form: form)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(form.name, style: AppTextStyles.listTitle),
                    if (form.description != null &&
                        form.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(form.description!,
                          style: AppTextStyles.listSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form Detail Screen ─────────────────────────────────────────
class FormDetailScreen extends StatefulWidget {
  final FormItem form;
  const FormDetailScreen({super.key, required this.form});

  @override
  State<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends State<FormDetailScreen> {
  final Map<String, dynamic> formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(widget.form.name, style: AppTextStyles.appBarTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: _buildSectionedFields(widget.form),
            ),
          ),
          _SubmitBar(onSubmit: _handleSubmit),
        ],
      ),
    );
  }

  void _handleSubmit() {
    debugPrint("FORM DATA: $formData");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 18),
            SizedBox(width: 10),
            Text("Form submitted successfully",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Widget> _buildSectionedFields(FormItem form) {
    final fieldsBySection = <String, List<FormFieldItem>>{};
    for (var field in form.fields) {
      fieldsBySection.putIfAbsent(field.sectionTitle, () => []).add(field);
    }

    final widgets = <Widget>[];
    fieldsBySection.forEach((section, fields) {
      widgets.add(_SectionHeader(title: section));
      fields.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (var field in fields) {
        widgets.add(_buildFieldWidget(field));
      }
      widgets.add(const SizedBox(height: 8));
    });
    return widgets;
  }

  Widget _buildFieldWidget(FormFieldItem field) {
    final key = field.id.toString();
    final label = field.title;
    final isReq = field.isRequired;

    switch (field.fieldType) {
      case 'text':
        return _FieldWrapper(
          child: TextField(
            style: AppTextStyles.inputText,
            cursorColor: AppColors.accent,
            decoration: _fieldDecoration(label: label, isRequired: isReq),
            onChanged: (val) => formData[key] = val,
          ),
        );

      case 'number':
        return _FieldWrapper(
          child: TextField(
            keyboardType: TextInputType.number,
            style: AppTextStyles.inputText,
            cursorColor: AppColors.accent,
            decoration: _fieldDecoration(label: label, isRequired: isReq),
            onChanged: (val) => formData[key] = val,
          ),
        );

      case 'select':
        return _FieldWrapper(
          child: DropdownButtonFormField<String>(
            style: AppTextStyles.inputText,
            dropdownColor: AppColors.surface,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
            items: field.options.map((opt) {
              return DropdownMenuItem(
                value: opt.value,
                child: Text(opt.label),
              );
            }).toList(),
            onChanged: (val) => formData[key] = val,
            decoration: _fieldDecoration(label: label, isRequired: isReq),
          ),
        );

      case 'multiselect':
        return _MultiSelectField(
          field: field,
          label: label,
          isRequired: isReq,
          selectedValues: formData[key] ?? [],
          onChanged: (vals) => setState(() => formData[key] = vals),
        );

      case 'date_time':
        return _DateField(
          label: label,
          isRequired: isReq,
          value: formData[key],
          onPicked: (val) => setState(() => formData[key] = val),
        );

      case 'yes_no':
        return _YesNoField(
          label: label,
          isRequired: isReq,
          value: formData[key] ?? false,
          onChanged: (val) => setState(() => formData[key] = val),
        );

      case 'photos':
        return _PhotoField(
          label: label,
          isRequired: isReq,
          value: (formData[key] as List<XFile>?) ?? const [],
          onChanged: (files) => setState(() => formData[key] = files),
        );

      case 'signature':
        return _SignatureField(
          label: label,
          isRequired: isReq,
          value: formData[key] is _SignatureValue
              ? formData[key] as _SignatureValue
              : null,
          onChanged: (signature) => setState(() => formData[key] = signature),
        );

      default:
        return _FieldWrapper(
          child: Text("Unsupported: ${field.fieldType}",
              style: const TextStyle(color: AppColors.textSecondary)),
        );
    }
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: AppTextStyles.sectionTitle),
        ],
      ),
    );
  }
}

// ─── Field Wrapper (spacing) ──────────────────────────────────────
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
  final FormFieldItem field;
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
              style: AppTextStyles.fieldLabel,
              children: isRequired
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(
                              color: AppColors.required, fontSize: 12))
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.chipSelected : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.chipBorderSelected
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
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
                    primary: AppColors.accent,
                    onSurface: AppColors.textPrimary),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: value != null
                    ? Text(value!, style: AppTextStyles.inputText)
                    : RichText(
                        text: TextSpan(
                          text: label,
                          style: AppTextStyles.fieldLabel,
                          children: isRequired
                              ? const [
                                  TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                          color: AppColors.required,
                                          fontSize: 12))
                                ]
                              : [],
                        ),
                      ),
              ),
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.textSecondary),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: AppTextStyles.inputText,
                  children: isRequired
                      ? const [
                          TextSpan(
                              text: ' *',
                              style: TextStyle(
                                  color: AppColors.required, fontSize: 12))
                        ]
                      : [],
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: AppColors.switchActive,
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
  final List<XFile> value;
  final ValueChanged<List<XFile>> onChanged;
  static final ImagePicker _picker = ImagePicker();

  const _PhotoField({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pickImages(BuildContext context) async {
    try {
      final images = await _picker.pickMultiImage();
      if (!context.mounted || images.isEmpty) return;

      final merged = [...value];
      for (final image in images) {
        if (!merged.any((item) => item.path == image.path)) {
          merged.add(image);
        }
      }
      onChanged(merged);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${merged.length} photo${merged.length == 1 ? '' : 's'} selected',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open image picker')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FieldWrapper(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImages(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.accent, size: 20),
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
                              color: AppColors.textPrimary),
                          children: isRequired
                              ? const [
                                  TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                          color: AppColors.required,
                                          fontSize: 12))
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value.isEmpty
                            ? "Tap to upload photos"
                            : "${value.length} photo${value.length == 1 ? '' : 's'} selected",
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: value.map((image) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(image.path),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            final updated = value
                                .where((item) => item.path != image.path)
                                .toList();
                            onChanged(updated);
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Signature Field ──────────────────────────────────────────────
class _SignatureField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final _SignatureValue? value;
  final ValueChanged<_SignatureValue?> onChanged;

  const _SignatureField({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.onChanged,
  });

  Future<void> _openSignatureDialog(BuildContext context) async {
    final savedSignature = await showDialog<_SignatureValue>(
      context: context,
      builder: (dialogContext) {
        var draftPoints = List<Offset?>.from(value?.points ?? const []);
        Size canvasSize = const Size(320, 200);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final hasSignature = draftPoints.any((point) => point != null);

              Offset _normalize(Offset point, Size size) {
                final safeWidth = size.width <= 0 ? 1.0 : size.width;
                final safeHeight = size.height <= 0 ? 1.0 : size.height;
                return Offset(point.dx / safeWidth, point.dy / safeHeight);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign below. You can clear and redraw before saving.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setDialogState(() {
                                  draftPoints = [
                                    ...draftPoints,
                                    _normalize(details.localPosition, canvasSize),
                                  ];
                                });
                              },
                              onPanUpdate: (details) {
                                setDialogState(() {
                                  draftPoints = [
                                    ...draftPoints,
                                    _normalize(details.localPosition, canvasSize),
                                  ];
                                });
                              },
                              onPanEnd: (_) {
                                setDialogState(() {
                                  draftPoints = [...draftPoints, null];
                                });
                              },
                              child: CustomPaint(
                                painter: _SignaturePainter(points: draftPoints),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        TextButton(
                          onPressed: hasSignature
                              ? () => setDialogState(() => draftPoints = [])
                              : null,
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: hasSignature
                              ? () => Navigator.pop(
                                    dialogContext,
                                    _SignatureValue(points: draftPoints),
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Signature'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (savedSignature != null) {
      onChanged(savedSignature);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = value?.hasSignature ?? false;

    return _FieldWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: AppTextStyles.fieldLabel,
              children: isRequired
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(
                              color: AppColors.required, fontSize: 12))
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openSignatureDialog(context),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  if (hasSignature)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CustomPaint(
                          painter: _SignaturePainter(points: value!.points),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gesture_rounded,
                              color: AppColors.textHint.withOpacity(0.5),
                              size: 28),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap to add signature",
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hasSignature ? 'Tap to edit' : 'Open pad',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
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

class _SignatureValue {
  final List<Offset?> points;

  const _SignatureValue({required this.points});

  bool get hasSignature => points.any((point) => point != null);
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  const _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(
          Offset(current.dx * size.width, current.dy * size.height),
          Offset(next.dx * size.width, next.dy * size.height),
          paint,
        );
      }
    }

    if (points.isNotEmpty && points.last != null) {
      canvas.drawPoints(
        PointMode.points,
        [
          Offset(
            points.last!.dx * size.width,
            points.last!.dy * size.height,
          )
        ],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

// ─── Submit Bar ───────────────────────────────────────────────────
class _SubmitBar extends StatelessWidget {
  final VoidCallback onSubmit;
  const _SubmitBar({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
          onPressed: onSubmit,
          child: const Row(
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
