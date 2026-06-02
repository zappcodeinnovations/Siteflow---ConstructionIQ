import 'dart:io';
import 'package:camera/camera.dart';
import 'package:euroside/services/project_photos_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_view/photo_view.dart';

class ProjectCameraPage extends StatefulWidget {
  const ProjectCameraPage({super.key});

  @override
  State<ProjectCameraPage> createState() => _ProjectCameraPageState();
}

class _ProjectCameraPageState extends State<ProjectCameraPage> {
  CameraController? _cameraController;

  List<XFile> capturedPhotos = [];
  final Map<String, DateTime> _capturedPhotoTimes = {};
  bool isLoading = true;
  bool _permissionDenied = false;
  bool isRearCamera = true;
  double currentZoom = 1.0;
  double maxZoom = 1.0;
  double minZoom = 1.0;
  FlashMode currentFlash = FlashMode.off;
  bool _screenFlashEnabled = false;
  bool _showCaptureFlash = false;

  Future<void> _handleCameraPermissionDenied() async {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      _permissionDenied = true;
    });

    _showPermissionDialog();
  }

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
      if (mounted) {
        setState(() {
          _permissionDenied = false;
        });
      }

      await _initializeCamera();
      return;
    }

    /// Ask permission every time if not granted
    final result = await Permission.camera.request();

    /// User allowed permission
    if (result.isGranted) {
      if (mounted) {
        setState(() {
          _permissionDenied = false;
        });
      }

      await _initializeCamera();
      return;
    }

    /// Permanently denied
    if (result.isPermanentlyDenied) {
      await _handleCameraPermissionDenied();

      return;
    }

    /// Normal denied
    await _handleCameraPermissionDenied();
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F172A),
                      const Color(0xFF111827),
                      const Color(0xFF1E293B),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF60A5FA),
                                  const Color(0xFF2563EB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.no_photography_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Camera permission required',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Enable camera access in settings to capture project photos.',
                                  style: TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PermissionStepItem(
                              index: '1',
                              text: 'Tap Open Settings below.',
                            ),
                            SizedBox(height: 10),
                            _PermissionStepItem(
                              index: '2',
                              text: 'Open Permissions for this app.',
                            ),
                            SizedBox(height: 10),
                            _PermissionStepItem(
                              index: '3',
                              text: 'Allow Camera access.',
                            ),
                            SizedBox(height: 10),
                            _PermissionStepItem(
                              index: '4',
                              text: 'Return here and tap Retry.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Not now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await openAppSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Open Settings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _checkAndInitCamera();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF93C5FD),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Retry permission check'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      final flashMode = isRearCamera ? currentFlash : FlashMode.off;
      await _cameraController!.setFlashMode(flashMode);

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

      if (!isRearCamera && _screenFlashEnabled) {
        setState(() {
          _showCaptureFlash = true;
        });

        await Future.delayed(const Duration(milliseconds: 70));
      }

      final image = await _cameraController!.takePicture();
      final capturedAt = DateTime.now();

      setState(() {
        capturedPhotos.insert(0, image);

        _capturedPhotoTimes[image.path] = capturedAt;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("CAPTURE ERROR: $e");
    } finally {
      if (mounted && _showCaptureFlash) {
        setState(() {
          _showCaptureFlash = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      setState(() {
        isLoading = true;
        isRearCamera = !isRearCamera;
        currentFlash = FlashMode.off;
        _screenFlashEnabled = false;
        _showCaptureFlash = false;
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

      final capturedAtByPath = <String, DateTime?>{};

      for (final photo in capturedPhotos) {
        capturedAtByPath[photo.path] = _capturedPhotoTimes[photo.path];
      }

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

        capturedAtByPath: capturedAtByPath,
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

    if (isRearCamera) {
      if (currentFlash == FlashMode.off) {
        currentFlash = FlashMode.torch;
      } else {
        currentFlash = FlashMode.off;
      }

      await _cameraController!.setFlashMode(currentFlash);
    } else {
      _screenFlashEnabled = !_screenFlashEnabled;
    }

    if (mounted) {
      setState(() {});
    }
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

      body: _permissionDenied
          ? SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,

                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(24),
                        ),

                        child: const Icon(
                          Icons.no_photography_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Camera access is turned off',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Open settings, allow Camera permission, then return here and tap Retry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.75),
                          height: 1.4,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _checkAndInitCamera,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(color: Colors.white54),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await openAppSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Open Settings'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : isLoading ||
                _cameraController == null ||
                !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                /// CAMERA PREVIEW
                Positioned.fill(child: CameraPreview(_cameraController!)),

                if (_showCaptureFlash)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(color: Colors.white.withOpacity(0.82)),
                    ),
                  ),

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
                            isRearCamera
                                ? (currentFlash == FlashMode.torch
                                      ? Icons.flash_on
                                      : Icons.flash_off)
                                : (_screenFlashEnabled
                                      ? Icons.flash_on
                                      : Icons.flash_off),

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

class _PermissionStepItem extends StatelessWidget {
  final String index;
  final String text;

  const _PermissionStepItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            index,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
