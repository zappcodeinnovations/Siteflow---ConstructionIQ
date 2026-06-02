import 'package:flutter/material.dart';

import '../../model/drawing_location_model.dart';
import '../../utils/drawing_constants.dart';

class DrawingInfoSheet extends StatelessWidget {
  final DrawingLocationModel location;

  const DrawingInfoSheet({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final statusColor = DrawingConstants.statusColor(location.status);
    final statusTint = DrawingConstants.statusTint(location.status);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              location.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              label: 'Status',
              value: DrawingConstants.titleCase(location.status),
              valueColor: statusColor,
              tint: statusTint,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Description',
              value: location.description.isEmpty
                  ? 'No description available'
                  : location.description,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Assigned Worker',
              value: location.assignedWorker.isEmpty
                  ? 'Not assigned'
                  : location.assignedWorker,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? tint;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint ?? const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
