import 'package:euroside/modules/Project_photos/model/photos_model.dart';
import 'package:euroside/services/project_photos_services.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class WorkspaceDashboardPage extends StatefulWidget {
  const WorkspaceDashboardPage({super.key});

  @override
  State<WorkspaceDashboardPage> createState() => _WorkspaceDashboardPageState();
}

class _WorkspaceDashboardPageState extends State<WorkspaceDashboardPage> {
  late Future<List<ProjectPhotoModel>> _photosFuture;
  bool isSelectionMode = false;
  Set<int> selectedPhotoIds = {};
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();

    _photosFuture = ProjectImageService.getUploadedImages();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _refreshPhotos() async {
    setState(() {
      _photosFuture = ProjectImageService.getUploadedImages();
    });

    await _photosFuture;
  }

  Future<void> _deleteSelectedPhotos() async {
    try {
      if (selectedPhotoIds.isEmpty) {
        return;
      }

      showDialog(
        context: context,

        barrierDismissible: false,

        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      for (final id in selectedPhotoIds) {
        await ProjectImageService.deleteImage(id);
      }

      selectedPhotoIds.clear();

      isSelectionMode = false;

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photos deleted successfully"),

            backgroundColor: Colors.green,
          ),
        );

        _refreshPhotos();
      }
    } catch (e) {
      debugPrint("❌ DELETE SELECTED ERROR: $e");

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatPhotoTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return "Time unavailable";
    }

    final localTimestamp = timestamp.toLocal();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final photoDay = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );
    final dayDifference = startOfToday.difference(photoDay).inDays;

    final dayLabel = dayDifference == 0
        ? "Today"
        : dayDifference == 1
        ? "Yesterday"
        : DateFormat('dd MMM yyyy').format(localTimestamp);

    return "$dayLabel • ${DateFormat('hh:mm a').format(localTimestamp)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xffF4F7FB),

        elevation: 0,

        title: Text(
          isSelectionMode ? "${selectedPhotoIds.length} Selected" : "Dashboard",

          style: const TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          if (isSelectionMode)
            IconButton(
              onPressed: _deleteSelectedPhotos,

              icon: const Icon(Icons.delete, color: Colors.red),
            ),

          if (isSelectionMode)
            IconButton(
              onPressed: () {
                setState(() {
                  isSelectionMode = false;

                  selectedPhotoIds.clear();
                });
              },

              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPhotos,

        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),

                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "My Open Items",

                      style: TextStyle(
                        fontSize: 24,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// LEGEND
                    Wrap(
                      spacing: 18,
                      runSpacing: 12,

                      children: [
                        _legendItem(Colors.red, "Overdue"),

                        _legendItem(Colors.orange, "Next 7 days"),

                        _legendItem(Colors.green, "> 7 Days"),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _overviewRow(
                      title: "Submittals",
                      total: "12 total",
                      overdue: "2",
                      upcoming: "4",
                      safe: "6",
                    ),

                    const SizedBox(height: 24),

                    _overviewRow(
                      title: "Observations",
                      total: "8 total",
                      overdue: "1",
                      upcoming: "2",
                      safe: "5",
                    ),

                    const SizedBox(height: 24),

                    _overviewRow(
                      title: "Inspections",
                      total: "14 total",
                      overdue: "3",
                      upcoming: "5",
                      safe: "6",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /// ====================================
              /// PROJECT OVERVIEW
              /// ====================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),

                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Project Overview",

                      style: TextStyle(
                        fontSize: 24,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 18,
                      runSpacing: 12,

                      children: [
                        _legendItem(Colors.red, "Overdue"),

                        _legendItem(Colors.orange, "Next 7 days"),

                        _legendItem(Colors.green, "> 7 Days"),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _progressTile(
                      title: "Submittals",
                      total: "12 items",
                      progress: .75,
                      progressColor: Colors.green,
                    ),

                    const SizedBox(height: 22),

                    _progressTile(
                      title: "Observations",
                      total: "8 items",
                      progress: .60,
                      progressColor: Colors.orange,
                    ),

                    const SizedBox(height: 22),

                    _progressTile(
                      title: "Inspections",
                      total: "14 items",
                      progress: .85,
                      progressColor: Colors.green,
                    ),

                    const SizedBox(height: 22),

                    _progressTile(
                      title: "Material Request",
                      total: "10 items",
                      progress: .40,
                      progressColor: Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// ====================================
              /// HEADER
              /// ====================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Uploaded Photos",

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),

                  GestureDetector(
                    onTap: _refreshPhotos,

                    child: Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// ====================================
              /// PHOTOS
              /// ====================================
              FutureBuilder<List<ProjectPhotoModel>>(
                future: _photosFuture,

                builder: (context, snapshot) {
                  /// LOADING
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),

                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  /// ERROR
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            snapshot.error.toString(),

                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final photos = snapshot.data ?? [];

                  /// EMPTY
                  if (photos.isEmpty) {
                    return Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(28),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: Column(
                        children: [
                          Icon(
                            Iconsax.gallery,
                            size: 44,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            "No uploaded photos found",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  /// GRID
                  return GridView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: photos.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,

                          crossAxisSpacing: 14,

                          mainAxisSpacing: 14,

                          childAspectRatio: .72,
                        ),

                    itemBuilder: (context, index) {
                      final photo = photos[index];

                      return GestureDetector(
                        /// LONG PRESS → ENABLE SELECTION
                        onLongPress: () {
                          setState(() {
                            isSelectionMode = true;

                            selectedPhotoIds.add(photo.id);
                          });
                        },

                        /// TAP
                        onTap: () {
                          /// IF SELECTION MODE
                          if (isSelectionMode) {
                            setState(() {
                              if (selectedPhotoIds.contains(photo.id)) {
                                selectedPhotoIds.remove(photo.id);

                                if (selectedPhotoIds.isEmpty) {
                                  isSelectionMode = false;
                                }
                              } else {
                                selectedPhotoIds.add(photo.id);
                              }
                            });

                            return;
                          }

                          /// NORMAL PREVIEW
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) => FullImagePreviewPage(
                                imageUrl: photo.imageUrl,
                              ),
                            ),
                          );
                        },

                        child: Stack(
                          children: [
                            /// CARD
                            Hero(
                              tag: photo.imageUrl,

                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius: BorderRadius.circular(24),

                                  border: selectedPhotoIds.contains(photo.id)
                                      ? Border.all(color: Colors.blue, width: 3)
                                      : null,

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.05),

                                      blurRadius: 10,

                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    /// IMAGE
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),

                                        child: Image.network(
                                          photo.imageUrl,

                                          width: double.infinity,

                                          fit: BoxFit.cover,

                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,

                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),

                                    /// DETAILS
                                    Padding(
                                      padding: const EdgeInsets.all(14),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          Text(
                                            photo.fileName,

                                            maxLines: 2,

                                            overflow: TextOverflow.ellipsis,

                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Colors.grey.shade500,
                                              ),

                                              const SizedBox(width: 6),

                                              Expanded(
                                                child: Text(
                                                  _formatPhotoTimestamp(
                                                    photo.createdAt,
                                                  ),

                                                  maxLines: 1,

                                                  overflow:
                                                      TextOverflow.ellipsis,

                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 11,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// CHECK ICON
                            if (selectedPhotoIds.contains(photo.id))
                              Positioned(
                                top: 10,
                                right: 10,

                                child: Container(
                                  padding: const EdgeInsets.all(6),

                                  decoration: const BoxDecoration(
                                    color: Colors.blue,

                                    shape: BoxShape.circle,
                                  ),

                                  child: const Icon(
                                    Icons.check,

                                    color: Colors.white,

                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String title) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Text(
          title,

          style: TextStyle(
            color: Colors.grey.shade700,

            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _overviewRow({
    required String title,

    required String total,

    required String overdue,

    required String upcoming,

    required String safe,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "$title  $total",

                style: const TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            _countItem(Colors.red, overdue),

            _countItem(Colors.orange, upcoming),

            _countItem(Colors.green, safe),
          ],
        ),
      ],
    );
  }

  Widget _countItem(Color color, String count) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Text(
          count,

          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _progressTile({
    required String title,

    required String total,

    required double progress,

    required Color progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          "$title  $total",

          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 14),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),

          child: LinearProgressIndicator(
            value: progress,

            minHeight: 14,

            backgroundColor: Colors.grey.shade200,

            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: color.withOpacity(.1),

              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 20),

          Text(
            value,

            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 6),

          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class FullImagePreviewPage extends StatelessWidget {
  final String imageUrl;

  const FullImagePreviewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(backgroundColor: Colors.black),

      body: Hero(
        tag: imageUrl,

        child: PhotoView(imageProvider: NetworkImage(imageUrl)),
      ),
    );
  }
}
