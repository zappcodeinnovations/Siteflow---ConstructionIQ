import 'dart:io';
import 'package:camera/camera.dart';
import 'package:euroside/services/project_photos_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:photo_view/photo_view.dart';

class ProjectCameraPage extends StatefulWidget {
  const ProjectCameraPage({super.key});

  @override
  State<ProjectCameraPage> createState() => _ProjectCameraPageState();
}

class _ProjectCameraPageState extends State<ProjectCameraPage> {
  CameraController? _cameraController;

  List<XFile> capturedPhotos = [];
  bool isLoading = true;
  bool isRearCamera = true;
  double currentZoom = 1.0;
  double maxZoom = 1.0;
  double minZoom = 1.0;
  FlashMode currentFlash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _checkAndInitCamera();
  }

  Future<void> _checkAndInitCamera() async {
    setState(() {
      isLoading = true;
    });

    final status = await Permission.camera.status;

    /// Permission already granted
    if (status.isGranted) {
      await _initializeCamera();
      return;
    }

    /// Ask permission every time if not granted
    final result = await Permission.camera.request();

    /// User allowed permission
    if (result.isGranted) {
      await _initializeCamera();
      return;
    }

    /// Permanently denied
    if (result.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }

      /// Close camera page instantly
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });

      return;
    }

    /// Normal denied
    /// Directly close page
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Please allow camera permission from settings to use camera.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint("📸 INITIALIZING CAMERA");

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("❌ NO CAMERA FOUND");

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      final selectedCamera = isRearCamera
          ? cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
            )
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
            );

      /// DISPOSE OLD CONTROLLER
      await _cameraController?.dispose();

      _cameraController = CameraController(
        selectedCamera,

        ResolutionPreset.high,

        enableAudio: false,
      );

      /// INITIALIZE CAMERA
      await _cameraController!.initialize();

      /// ZOOM LEVELS
      minZoom = await _cameraController!.getMinZoomLevel();

      maxZoom = await _cameraController!.getMaxZoomLevel();

      /// FLASH
      await _cameraController!.setFlashMode(currentFlash);

      debugPrint("✅ CAMERA INITIALIZED");

      debugPrint(
        "📸 CAMERA READY: "
        "${_cameraController!.value.isInitialized}",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("❌ CAMERA ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      final image = await _cameraController!.takePicture();

      setState(() {
        capturedPhotos.insert(0, image);
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("CAPTURE ERROR: $e");
    }
  }

  Future<void> _switchCamera() async {
    try {
      setState(() {
        isLoading = true;
        isRearCamera = !isRearCamera;
      });

      await _initializeCamera();
    } catch (e) {
      debugPrint("❌ SWITCH CAMERA ERROR: $e");
    }
  }

  Future<void> _uploadPhotos() async {
    try {
      if (capturedPhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please capture at least one photo")),
        );

        return;
      }

      debugPrint("📸 TOTAL PHOTOS: ${capturedPhotos.length}");

      /// LOADING
      showDialog(
        context: context,

        barrierDismissible: false,

        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      /// CONVERT XFILE TO FILE
      final files = capturedPhotos.map((e) => File(e.path)).toList();

      /// PRINT ALL FILES
      for (final file in files) {
        debugPrint("🖼️ IMAGE PATH: ${file.path}");

        debugPrint(
          "📦 FILE SIZE: "
          "${await file.length()} bytes",
        );
      }

      /// API CALL
      final response = await ProjectImageService.uploadMultipleImages(
        images: files,
      );

      debugPrint("✅ UPLOAD RESPONSE: $response");

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Photos uploaded successfully"),

            backgroundColor: Colors.green,
          ),
        );

        /// CLOSE CAMERA PAGE
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint("❌ PHOTO UPLOAD ERROR: $e");

      debugPrint("📍 STACKTRACE: $stackTrace");

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    if (currentFlash == FlashMode.off) {
      currentFlash = FlashMode.torch;
    } else {
      currentFlash = FlashMode.off;
    }

    await _cameraController!.setFlashMode(currentFlash);

    setState(() {});
  }

  void _openPreview(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPreviewPage(
          images: capturedPhotos,
          initialIndex: initialIndex,
          onDelete: (index) {
            setState(() {
              capturedPhotos.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body:
          isLoading ||
              _cameraController == null ||
              !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                /// CAMERA PREVIEW
                Positioned.fill(child: CameraPreview(_cameraController!)),

                /// TOP BAR
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,

                  left: 18,
                  right: 18,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      _topButton(Icons.arrow_back, () {
                        Navigator.pop(context);
                      }),

                      Row(
                        children: [
                          _topButton(
                            currentFlash == FlashMode.torch
                                ? Icons.flash_on
                                : Icons.flash_off,

                            _toggleFlash,
                          ),

                          const SizedBox(width: 12),

                          _topButton(Icons.flip_camera_ios, _switchCamera),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ZOOM SLIDER
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).size.height * .25,

                  child: RotatedBox(
                    quarterTurns: 3,

                    child: SizedBox(
                      width: 160,

                      child: Slider(
                        value: currentZoom,

                        min: minZoom,
                        max: maxZoom,

                        onChanged: (value) async {
                          currentZoom = value;

                          await _cameraController!.setZoomLevel(value);

                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),

                /// BOTTOM SECTION
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,

                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 18,
                      right: 18,
                      top: 18,
                      bottom: 28,
                    ),

                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,

                        end: Alignment.bottomCenter,

                        colors: [
                          Colors.black.withOpacity(0),

                          Colors.black.withOpacity(.9),
                        ],
                      ),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        /// GALLERY PREVIEW
                        if (capturedPhotos.isNotEmpty)
                          SizedBox(
                            height: 95,

                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,

                              itemBuilder: (context, index) {
                                final image = capturedPhotos[index];

                                return GestureDetector(
                                  onTap: () => _openPreview(index),

                                  child: Hero(
                                    tag: image.path,

                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),

                                      child: Stack(
                                        children: [
                                          Image.file(
                                            File(image.path),

                                            width: 90,

                                            height: 90,

                                            fit: BoxFit.cover,
                                          ),

                                          Positioned(
                                            top: 6,

                                            right: 6,

                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  capturedPhotos.removeAt(
                                                    index,
                                                  );
                                                });
                                              },

                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  5,
                                                ),

                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,

                                                  shape: BoxShape.circle,
                                                ),

                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,

                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fade(
                                  delay: Duration(milliseconds: index * 80),
                                );
                              },

                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),

                              itemCount: capturedPhotos.length,
                            ),
                          ),

                        const SizedBox(height: 22),

                        /// CAMERA BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            /// IMAGE COUNT
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white10,

                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.gallery,
                                    color: Colors.white,

                                    size: 18,
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    "${capturedPhotos.length} Photos",

                                    style: const TextStyle(
                                      color: Colors.white,

                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// CAPTURE BUTTON
                            GestureDetector(
                              onTap: _capturePhoto,

                              child: Container(
                                width: 84,
                                height: 84,

                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: Colors.white,

                                    width: 5,
                                  ),
                                ),

                                child: Center(
                                  child: Container(
                                    width: 68,

                                    height: 68,

                                    decoration: const BoxDecoration(
                                      color: Colors.white,

                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// DONE BUTTON
                            GestureDetector(
                              onTap: _uploadPhotos,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xff2563EB),

                                  borderRadius: BorderRadius.circular(18),
                                ),

                                child: const Text(
                                  "Done",

                                  style: TextStyle(
                                    color: Colors.white,

                                    fontWeight: FontWeight.w700,
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
              ],
            ),
    );
  }

  Widget _topButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 48,
        height: 48,

        decoration: BoxDecoration(
          color: Colors.black45,

          borderRadius: BorderRadius.circular(18),
        ),

        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class GalleryPreviewPage extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;
  final Function(int) onDelete;

  const GalleryPreviewPage({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<GalleryPreviewPage> createState() => _GalleryPreviewPageState();
}

class _GalleryPreviewPageState extends State<GalleryPreviewPage> {
  late PageController _pageController;

  late int currentIndex;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,

        elevation: 0,

        title: Text("${currentIndex + 1}/${widget.images.length}"),

        actions: [
          IconButton(
            onPressed: () {
              widget.onDelete(currentIndex);

              Navigator.pop(context);
            },

            icon: const Icon(Icons.delete),
          ),
        ],
      ),

      body: PageView.builder(
        controller: _pageController,

        itemCount: widget.images.length,

        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        itemBuilder: (context, index) {
          final image = widget.images[index];

          return Hero(
            tag: image.path,

            child: PhotoView(
              imageProvider: FileImage(File(image.path)),

              minScale: PhotoViewComputedScale.contained,

              maxScale: PhotoViewComputedScale.covered * 3,
            ),
          );
        },
      ),
    );
  }
}
