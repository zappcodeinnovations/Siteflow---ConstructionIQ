import 'package:flutter/material.dart';

import '../../model/drawing_location_model.dart';

class DrawingMarker extends StatelessWidget {
  final DrawingLocationModel location;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  const DrawingMarker({
    super.key,
    required this.location,
    required this.size,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _markerColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: isSelected ? 1.14 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isSelected ? 0.42 : 0.18),
                    blurRadius: isSelected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.place_rounded, color: Colors.white, size: 14),
              ),
            ),
            Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _markerColor() {
    switch (location.status.toLowerCase()) {
      case 'completed':
      case 'done':
        return const Color(0xFF22C55E);

      case 'issue':
        return const Color(0xFFEF4444);

      case 'pending':
      case 'todo':
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF3B82F6);
    }
  }
}
