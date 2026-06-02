import 'package:flutter/material.dart';

import '../../model/block_model.dart';
import '../../model/level_model.dart';
import '../../model/project_model.dart';
import '../../utils/drawing_constants.dart';

class DrawingFilterBar extends StatelessWidget {
  final List<ProjectModel> projects;
  final List<LevelModel> levels;
  final String? selectedStatus;
  final int? selectedProjectId;
  final int? selectedLevelId;
  final ValueChanged<int?> onProjectChanged;
  final ValueChanged<int?> onLevelChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;

  const DrawingFilterBar({
    super.key,
    required this.projects,
    required this.levels,
    required this.selectedStatus,
    required this.selectedProjectId,
    required this.selectedLevelId,
    required this.onProjectChanged,
    required this.onLevelChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              final filterFields = [
                _DropdownField<int?>(
                  label: 'Project',
                  value: selectedProjectId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Projects'),
                    ),
                    ...projects.map(
                      (project) => DropdownMenuItem<int?>(
                        value: project.id,
                        child: Text(project.name),
                      ),
                    ),
                  ],
                  onChanged: onProjectChanged,
                ),
                _DropdownField<int?>(
                  label: 'Level',
                  value: selectedLevelId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Levels'),
                    ),
                    ...levels.map(
                      (level) => DropdownMenuItem<int?>(
                        value: level.id,
                        child: Text(level.name),
                      ),
                    ),
                  ],
                  onChanged: onLevelChanged,
                ),
                _DropdownField<String?>(
                  label: 'Status',
                  value: selectedStatus,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...DrawingConstants.statusOptions.map(
                      (status) => DropdownMenuItem<String?>(
                        value: status,
                        child: Text(DrawingConstants.titleCase(status)),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ];

              if (isCompact) {
                return Column(
                  children: [
                    filterFields[0],
                    const SizedBox(height: 10),
                    filterFields[1],
                    const SizedBox(height: 10),
                    filterFields[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: filterFields[0]),
                  const SizedBox(width: 10),
                  Expanded(child: filterFields[1]),
                  const SizedBox(width: 10),
                  Expanded(child: filterFields[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  T? _effectiveValue() {
    for (final item in items) {
      if (item.value == value) {
        return value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        value: _effectiveValue(),
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
