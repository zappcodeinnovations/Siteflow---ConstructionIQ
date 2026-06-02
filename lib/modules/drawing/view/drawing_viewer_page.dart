import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../model/drawing_location_model.dart';
import '../model/drawing_model.dart';
import '../utils/drawing_constants.dart';
import 'widgets/drawing_marker.dart';

class DrawingViewerPage extends StatefulWidget {
  final DrawingModel drawing;

  const DrawingViewerPage({super.key, required this.drawing});

  @override
  State<DrawingViewerPage> createState() => _DrawingViewerPageState();
}

class _DrawingViewerPageState extends State<DrawingViewerPage> {
  DrawingLocationModel? selectedLocation;

  void _handleMarkerTap(DrawingLocationModel location) {
    setState(() {
      selectedLocation = location;
    });
  }

  void _closePopup() {
    if (selectedLocation == null) {
      return;
    }

    setState(() {
      selectedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ??
            theme.appBarTheme.iconTheme?.color ??
            const Color(0xFF0F172A),
        elevation: 0,
        title: Text(widget.drawing.name),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.drawing.isPdf
                ? _PdfCanvas(
                    drawing: widget.drawing,
                    selectedLocation: selectedLocation,
                    onMarkerTap: _handleMarkerTap,
                  )
                : _ImageCanvas(
                    drawing: widget.drawing,
                    selectedLocation: selectedLocation,
                    onMarkerTap: _handleMarkerTap,
                  ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: _ViewerHeader(drawing: widget.drawing),
          ),
          if (selectedLocation != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePopup,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: selectedLocation == null ? 0 : 1,
                  ),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 14 * value,
                        sigmaY: 14 * value,
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(0.35 * value),
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: selectedLocation == null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  );
                  final scale = Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  );

                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
                child: selectedLocation == null
                    ? const SizedBox.shrink()
                    : Center(
                        key: ValueKey<int>(selectedLocation!.id),
                        child: _LocationPopupCard(
                          location: selectedLocation!,
                          onClose: _closePopup,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCanvas extends StatefulWidget {
  final DrawingModel drawing;
  final DrawingLocationModel? selectedLocation;
  final ValueChanged<DrawingLocationModel> onMarkerTap;

  const _ImageCanvas({
    required this.drawing,
    required this.selectedLocation,
    required this.onMarkerTap,
  });

  @override
  State<_ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends State<_ImageCanvas> {
  double? _imageAspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _ImageCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.drawing.fileUrl != widget.drawing.fileUrl) {
      _resolveImageAspectRatio();
    }
  }

  Future<void> _resolveImageAspectRatio() async {
    final provider = CachedNetworkImageProvider(widget.drawing.fileUrl);
    final stream = provider.resolve(const ImageConfiguration());

    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final ratio = info.image.width / info.image.height;

        if (mounted) {
          setState(() {
            _imageAspectRatio = ratio > 0 ? ratio : null;
          });
        }

        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (mounted) {
          setState(() {
            _imageAspectRatio = null;
          });
        }

        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fittedRect = _computeFittedRect(
          containerWidth: constraints.maxWidth,
          containerHeight: constraints.maxHeight,
          imageAspectRatio: _imageAspectRatio,
        );

        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(120),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                Positioned(
                  left: fittedRect.left,
                  top: fittedRect.top,
                  width: fittedRect.width,
                  height: fittedRect.height,
                  child: CachedNetworkImage(
                    imageUrl: widget.drawing.fileUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, _) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, _, __) => const _ErrorCanvas(
                      message: 'Could not load the drawing image',
                    ),
                  ),
                ),
                Positioned(
                  left: fittedRect.left,
                  top: fittedRect.top,
                  width: fittedRect.width,
                  height: fittedRect.height,
                  child: _MarkerLayer(
                    drawing: widget.drawing,
                    selectedLocation: widget.selectedLocation,
                    onMarkerTap: widget.onMarkerTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Rect _computeFittedRect({
    required double containerWidth,
    required double containerHeight,
    required double? imageAspectRatio,
  }) {
    final ratio = imageAspectRatio;

    if (ratio == null || ratio <= 0) {
      return Rect.fromLTWH(0, 0, containerWidth, containerHeight);
    }

    var width = containerWidth;
    var height = width / ratio;

    if (height > containerHeight) {
      height = containerHeight;
      width = height * ratio;
    }

    final left = (containerWidth - width) / 2;
    final top = (containerHeight - height) / 2;

    return Rect.fromLTWH(left, top, width, height);
  }
}

class _PdfCanvas extends StatelessWidget {
  final DrawingModel drawing;
  final DrawingLocationModel? selectedLocation;
  final ValueChanged<DrawingLocationModel> onMarkerTap;

  const _PdfCanvas({
    required this.drawing,
    required this.selectedLocation,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            SfPdfViewer.network(drawing.fileUrl, canShowPaginationDialog: true),
            Positioned.fill(
              child: _MarkerLayer(
                drawing: drawing,
                selectedLocation: selectedLocation,
                onMarkerTap: onMarkerTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MarkerLayer extends StatelessWidget {
  final DrawingModel drawing;
  final DrawingLocationModel? selectedLocation;
  final ValueChanged<DrawingLocationModel> onMarkerTap;
  static const double _markerSize = 20;
  const _MarkerLayer({
    required this.drawing,
    required this.selectedLocation,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (drawing.locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final location in drawing.locations)
              Positioned(
                left: _position(
                  containerSize: constraints.maxWidth,
                  pixel: location.xPixel.toDouble(),
                  originalSize: drawing.imageWidthPx.toDouble(),
                ),

                top: _position(
                  containerSize: constraints.maxHeight,
                  pixel: location.yPixel.toDouble(),
                  originalSize: drawing.imageHeightPx.toDouble(),
                ),
                child: DrawingMarker(
                  location: location,
                  size: _markerSize,
                  isSelected: selectedLocation?.id == location.id,
                  onTap: () => onMarkerTap(location),
                ),
              ),
          ],
        );
      },
    );
  }

  double _position({
    required double containerSize,
    required double pixel,
    required double originalSize,
  }) {
    if (originalSize <= 0) {
      return 0;
    }

    // Convert pixel coordinate into normalized value
    final normalized = pixel / originalSize;

    // Keep marker inside visible image bounds
    final position = (containerSize - _markerSize) * normalized;

    return position.clamp(0.0, containerSize - _markerSize);
  }
}

class _ViewerHeader extends StatelessWidget {
  final DrawingModel drawing;

  const _ViewerHeader({required this.drawing});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(0.8, 1.0);
        final titleStyle = TextStyle(
          color: Colors.white,
          fontSize: 15 * scale,
          fontWeight: FontWeight.w700,
        );
        final subtitleStyle = TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 11 * scale,
        );
        final markerStyle = TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF92400E),
        );
        final iconSize = 40.0 * scale;
        final gap = 12.0 * scale;
        final pad = 12.0 * scale;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: DrawingConstants.statusTint('completed'),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Icon(
                  drawing.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  color: drawing.isPdf
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drawing.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      '${drawing.projectName} • ${drawing.levelName} • ${drawing.blockName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: DrawingConstants.statusTint('pending'),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${drawing.locations.length} markers',
                  style: markerStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorCanvas extends StatelessWidget {
  final String message;

  const _ErrorCanvas({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _LocationPopupCard extends StatelessWidget {
  final DrawingLocationModel location;
  final VoidCallback onClose;

  const _LocationPopupCard({required this.location, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final statusColor = DrawingConstants.statusColor(location.status);

    final statusTint = DrawingConstants.statusTint(location.status);

    final mediaSize = MediaQuery.sizeOf(context);

    final isMobile = mediaSize.width < 700;

    final maxCardWidth = isMobile ? mediaSize.width : 500.0;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxCardWidth,
          maxHeight: mediaSize.height * 0.82,
        ),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: isMobile ? 18 : 0,
          top: isMobile ? 80 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // HEADER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'marker_${location.id}',
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.title.isEmpty
                                  ? location.name
                                  : location.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Drawing Inspection Point",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      _CloseButton(onClose: onClose),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // STATUS + CHIPS
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatusBadge(
                        label: location.statusLabel,
                        tint: statusTint,
                        color: statusColor,
                      ),

                      _ModernChip(
                        icon: Icons.layers_rounded,
                        label: location.blockName,
                      ),

                      _ModernChip(
                        icon: Icons.apartment_rounded,
                        label: location.levelName,
                      ),

                      _ModernChip(
                        icon: Icons.category_rounded,
                        label: location.variationLabel,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // DETAILS SECTION
                  _ModernSection(
                    title: "Location Details",
                    child: _ModernDetailsGrid(location: location),
                  ),

                  // DESCRIPTION
                  if (location.description.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    _ModernSection(
                      title: "Description",
                      child: Text(
                        location.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // COORDINATES
                  _ModernSection(
                    title: "Coordinates",
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModernInfoCard(
                            icon: Icons.gps_fixed_rounded,
                            label: "Position",
                            value:
                                "x: ${location.xPixel}, y: ${location.yPixel}",
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTION BUTTONS
                  Row(
                    children: [
                     
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text("Close"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ModernSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ModernChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModernChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ModernInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDetailsGrid extends StatelessWidget {
  final DrawingLocationModel location;

  const _ModernDetailsGrid({required this.location});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.layers_rounded,
        'title': 'Block',
        'value': location.blockName,
      },
      {
        'icon': Icons.apartment_rounded,
        'title': 'Level',
        'value': location.levelName,
      },
      {
        'icon': Icons.category_rounded,
        'title': 'Variation',
        'value': location.variationLabel,
      },
      {
        'icon': Icons.gps_fixed_rounded,
        'title': 'Coordinates',
        'value': 'x: ${location.xPixel}, y: ${location.yPixel}',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth > 360;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: isTwoColumn
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFF475569),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      item['value'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
      ),

      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          Text(
            value,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final DrawingLocationModel location;

  const _DetailsGrid({required this.location});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth > 360;

        final items = [
          _DetailTile(label: 'Block', value: location.blockName),
          _DetailTile(label: 'Level', value: location.levelName),
          _DetailTile(label: 'Variation', value: location.variationLabel),
          _DetailTile(
            label: 'Coordinates',
            value: 'x: ${location.xPixel}, y: ${location.yPixel}',
          ),
        ];

        if (!twoColumn) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                items[i],
              ],
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: item),
          ],
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color tint;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.tint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label.isEmpty ? 'No variation' : label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onClose;

  const _CloseButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
        color: const Color(0xFF0F172A),
        tooltip: 'Close',
      ),
    );
  }
}
