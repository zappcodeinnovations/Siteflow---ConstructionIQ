import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../model/drawing_model.dart';
import '../../utils/drawing_constants.dart';

class DrawingCard extends StatelessWidget {
  final DrawingModel drawing;
  final VoidCallback onTap;

  const DrawingCard({super.key, required this.drawing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewBox(drawing: drawing),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drawing.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(label: 'Project', value: drawing.projectName),
                    _MetaLine(label: 'Level', value: drawing.levelName),
                    _MetaLine(label: 'Block', value: drawing.blockName),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(text: drawing.isPdf ? 'PDF' : 'Image'),
                        _Chip(text: '${drawing.locations.length} Locations'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final DrawingModel drawing;

  const _PreviewBox({required this.drawing});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 92,
        height: 110,
        color: const Color(0xFFF8FAFC),
        child: drawing.isPdf
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DrawingConstants.statusTint('issue'),
                      const Color(0xFFFDF2F2),
                    ],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 36,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              )
            : CachedNetworkImage(
                imageUrl: drawing.fileUrl,
                fit: BoxFit.cover,
                width: 92,
                height: 110,
                placeholder: (context, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, _, __) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
