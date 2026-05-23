import 'dart:convert';
import 'dart:io';

import 'package:euroside/network/api_endpoint.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UserFormWebViewPage extends StatefulWidget {
  final String title;
  final String endpoint;
  final String accessToken;

  const UserFormWebViewPage({
    super.key,
    required this.title,
    required this.endpoint,
    required this.accessToken,
  });

  @override
  State<UserFormWebViewPage> createState() => _UserFormWebViewPageState();
}

class _UserFormWebViewPageState extends State<UserFormWebViewPage> {
  late final WebViewController _controller;

  final ImagePicker _imagePicker = ImagePicker();

  bool isLoading = true;

  int _currentFieldIndex = 0;

  int _totalFields = 0;

  @override
  void initState() {
    super.initState();

    final fullUrl =
        "${ApiEndpoints.baseUrl}"
        "${widget.endpoint}"
        "?access_token=${widget.accessToken}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xffffffff))
      /// JS CHANNELS
      ..addJavaScriptChannel(
        "Flutter",

        onMessageReceived: (message) {
          if (message.message == "FORM_SUBMITTED") {
            _showSuccessDialog();
          }

          if (message.message == "OPEN_GALLERY") {
            _pickFromGallery();
          }

          if (message.message == "OPEN_CAMERA") {
            _pickFromCamera();
          }

          if (message.message.startsWith("FIELD_COUNT:")) {
            final count = int.tryParse(message.message.split(":")[1]) ?? 0;

            setState(() {
              _totalFields = count;
            });
          }

          if (message.message.startsWith("FIELD_INDEX:")) {
            final index = int.tryParse(message.message.split(":")[1]) ?? 0;

            setState(() {
              _currentFieldIndex = index;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              isLoading = true;
            });
          },

          onPageFinished: (_) async {
            setState(() {
              isLoading = false;
            });

            /// ENABLE ZOOM
            await _controller.runJavaScript("""
    var meta =
      document.createElement('meta');

    meta.name = 'viewport';

    meta.content =
      'width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes';

    document
      .getElementsByTagName('head')[0]
      .appendChild(meta);
  """);

            /// FORM FIELD TRACKING
            await _controller.runJavaScript("""
    var formFields = [];
    var currentFieldIndex = -1;

    function initializeFields() {

      formFields = Array.from(
        document.querySelectorAll(
          'input, textarea, select, [contenteditable="true"]'
        )
      ).filter(function(field) {

        return field.offsetParent !== null &&
               field.offsetHeight > 0;
      });

      Flutter.postMessage(
        'FIELD_COUNT:' +
        formFields.length
      );

      formFields.forEach(function(
        field,
        index
      ) {

        field.addEventListener(
          'focus',
          function() {

            currentFieldIndex =
              index;

            Flutter.postMessage(
              'FIELD_INDEX:' +
              index
            );

            field.scrollIntoView({
              behavior: 'smooth',
              block: 'center'
            });
          }
        );
      });
    }

    window.navigateToField =
      function(direction) {

      if(formFields.length === 0)
        return;

      var nextIndex =
        currentFieldIndex +
        direction;

      if(
        nextIndex >= 0 &&
        nextIndex < formFields.length
      ) {

        formFields[nextIndex]
          .focus();
      }
    };

    window.addEventListener(
      'load',
      initializeFields
    );

    document.addEventListener(
      'DOMContentLoaded',
      initializeFields
    );

    setTimeout(
      initializeFields,
      500
    );
  """);

            await _controller.runJavaScript("""
    function setupPhotoButtons() {

      document
        .querySelectorAll('button, input[type=button]')
        .forEach(function(btn) {

        const text =
          (btn.innerText || btn.value || '')
          .toLowerCase();

        /// GALLERY
        if(
          text.includes('choose photo') ||
          text.includes('choose from gallery') ||
          text.includes('choose from gallary') ||
          text.includes('gallery')
        ) {

          btn.onclick = function(e) {

            e.preventDefault();

            Flutter.postMessage(
              'OPEN_GALLERY'
            );
          };
        }

        /// CAMERA
        if(
          text.includes('open camera')
        ) {

          btn.onclick = function(e) {

            e.preventDefault();

            Flutter.postMessage(
              'OPEN_CAMERA'
            );
          };
        }
      });
    }

    setTimeout(
      setupPhotoButtons,
      1000
    );
  """);

            await _controller.runJavaScript("""
    window.flutterUploadState = window.flutterUploadState || {
      files: []
    };

    function getTargetFileInput() {
      const inputs = document.querySelectorAll('input[type=file]');

      return inputs.length ? inputs[inputs.length - 1] : null;
    }

    function rebuildInputFiles() {
      const input = getTargetFileInput();

      if (!input) {
        return;
      }

      const dataTransfer = new DataTransfer();

      window.flutterUploadState.files.forEach(function(item) {
        const byteCharacters = atob(item.base64);
        const byteNumbers = new Array(byteCharacters.length);

        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        const file = new File([byteArray], item.name, {
          type: item.mimeType,
        });

        dataTransfer.items.add(file);
      });

      input.files = dataTransfer.files;
      input.dispatchEvent(
        new Event('change', {
          bubbles: true,
        })
      );
    }

    function renderFlutterUploadPreview() {
      const input = getTargetFileInput();

      if (!input) {
        return;
      }

      let preview = document.getElementById('flutter-upload-preview');

      if (!preview) {
        preview = document.createElement('div');
        preview.id = 'flutter-upload-preview';
        preview.style.marginTop = '12px';
        preview.style.display = 'grid';
        preview.style.gridTemplateColumns = '1fr';
        preview.style.gap = '10px';
        input.parentNode.appendChild(preview);
      }

      preview.innerHTML = '';

      if (!window.flutterUploadState.files.length) {
        const emptyState = document.createElement('div');
        emptyState.style.padding = '12px 14px';
        emptyState.style.border = '1px dashed #d1d5db';
        emptyState.style.borderRadius = '12px';
        emptyState.style.color = '#6b7280';
        emptyState.style.fontSize = '13px';
        // emptyState.textContent = 'No photos added yet.';
        preview.appendChild(emptyState);
        return;
      }

      window.flutterUploadState.files.forEach(function(item, index) {
        const row = document.createElement('div');
        row.style.display = 'flex';
        row.style.alignItems = 'center';
        row.style.gap = '12px';
        row.style.padding = '10px 12px';
        row.style.border = '1px solid #e5e7eb';
        row.style.borderRadius = '12px';
        row.style.background = '#ffffff';

        const thumb = document.createElement('div');
        thumb.style.width = '42px';
        thumb.style.height = '42px';
        thumb.style.borderRadius = '10px';
        thumb.style.overflow = 'hidden';
        thumb.style.flex = '0 0 auto';
        thumb.style.background = '#eef4ff';

        if (item.mimeType && item.mimeType.startsWith('image/')) {
          const img = document.createElement('img');
          img.src = 'data:' + item.mimeType + ';base64,' + item.base64;
          img.style.width = '100%';
          img.style.height = '100%';
          img.style.objectFit = 'cover';
          thumb.appendChild(img);
        } else {
          thumb.style.display = 'grid';
          thumb.style.placeItems = 'center';
          thumb.innerHTML = '<span style="font-size:18px;color:#2563eb;">📎</span>';
        }

        const info = document.createElement('div');
        info.style.flex = '1';
        info.style.minWidth = '0';

        const name = document.createElement('div');
        name.textContent = item.name;
        name.style.fontSize = '13px';
        name.style.fontWeight = '600';
        name.style.color = '#111827';
        name.style.whiteSpace = 'nowrap';
        name.style.overflow = 'hidden';
        name.style.textOverflow = 'ellipsis';

        const meta = document.createElement('div');
        meta.textContent = 'Tap remove if you want to replace this file';
        meta.style.fontSize = '12px';
        meta.style.color = '#6b7280';
        meta.style.marginTop = '2px';

        info.appendChild(name);
        info.appendChild(meta);

        const removeButton = document.createElement('button');
        removeButton.type = 'button';
        removeButton.textContent = 'Remove';
        removeButton.style.border = 'none';
        removeButton.style.background = '#fef2f2';
        removeButton.style.color = '#dc2626';
        removeButton.style.borderRadius = '10px';
        removeButton.style.padding = '8px 10px';
        removeButton.style.fontSize = '12px';
        removeButton.style.fontWeight = '600';
        removeButton.onclick = function() {
          window.flutterUploadState.files.splice(index, 1);
          rebuildInputFiles();
          renderFlutterUploadPreview();
        };

        row.appendChild(thumb);
        row.appendChild(info);
        row.appendChild(removeButton);
        preview.appendChild(row);
      });
    }

    window.addFlutterSelectedFile = function(payload) {
      if (!payload || !payload.name || !payload.base64) {
        return;
      }

      const alreadyAdded = window.flutterUploadState.files.some(function(item) {
        return item.name === payload.name && item.base64 === payload.base64;
      });

      if (!alreadyAdded) {
        window.flutterUploadState.files.push(payload);
      }

      rebuildInputFiles();
      renderFlutterUploadPreview();
    };

    renderFlutterUploadPreview();
  """);

            /// SUCCESS ALERT
            await _controller.runJavaScript("""
    window.alert =
      function(message) {

      if(
        message.includes(
          'Form submitted successfully'
        )
      ) {

        Flutter.postMessage(
          'FORM_SUBMITTED'
        );
      }
    };
  """);
          },

          onWebResourceError: (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.description)));
          },
        ),
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  Future<void> _navigateField(int direction) async {
    await _controller.runJavaScript('window.navigateToField($direction);');
  }

  /// =========================================
  /// UPLOAD OPTIONS
  /// =========================================

  Future<void> _showUploadOptions() async {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Text(
                  "Upload File",

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _uploadOptionTile(
                        icon: Icons.camera_alt_rounded,

                        label: "Camera",

                        onTap: () async {
                          Navigator.pop(context);

                          await _pickFromCamera();
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: _uploadOptionTile(
                        icon: Icons.photo_library_rounded,

                        label: "Gallery",

                        onTap: () async {
                          Navigator.pop(context);

                          await _pickFromGallery();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);

                      await _pickDocument();
                    },

                    icon: const Icon(Icons.attach_file),

                    label: const Text("Choose File"),

                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _uploadOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),

        decoration: BoxDecoration(
          color: const Color(0xffF4F7FB),

          borderRadius: BorderRadius.circular(18),
        ),

        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xff2563EB)),

            const SizedBox(height: 10),

            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    await _injectSelectedFile(image.path);
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isEmpty) return;

      for (final image in images) {
        await _injectSelectedFile(image.path);
      }
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.single.path == null) {
      return;
    }

    await _injectSelectedFile(result.files.single.path!);
  }

  Future<void> _injectSelectedFile(String filePath) async {
    final file = File(filePath);

    final bytes = await file.readAsBytes();

    final base64Data = base64Encode(bytes);

    final fileName = file.path.split(RegExp(r'[\\/]')).last;

    final mimeType = fileName.toLowerCase().endsWith('.png')
        ? 'image/png'
        : fileName.toLowerCase().endsWith('.webp')
        ? 'image/webp'
        : fileName.toLowerCase().endsWith('.gif')
        ? 'image/gif'
        : fileName.toLowerCase().endsWith('.pdf')
        ? 'application/pdf'
        : 'image/jpeg';

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),

        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],

            border: Border.all(color: const Color(0xffE5E7EB)),
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xffEEF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  fileName.endsWith('.png') ||
                          fileName.endsWith('.jpg') ||
                          fileName.endsWith('.jpeg')
                      ? Icons.image_rounded
                      : Icons.insert_drive_file_rounded,
                  color: const Color(0xff2563EB),
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Text(
                      "File Selected",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.all(6),

                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.1),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await _controller.runJavaScript(
      "window.addFlutterSelectedFile(${jsonEncode({'name': fileName, 'mimeType': mimeType, 'base64': base64Data})});",
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),

          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 80,
                  height: 80,

                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.1),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Form Submitted",

                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Your form has been submitted successfully.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    height: 1.5,
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),

                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(vertical: 14),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.pop(context);
                    },

                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),

      appBar: AppBar(
        elevation: 0,

        title: Text(widget.title),

        // actions: [
        //   IconButton(
        //     onPressed: _showUploadOptions,

        //     icon: const Icon(Icons.add_a_photo_rounded),
        //   ),
        // ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),

              child: WebViewWidget(controller: _controller),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.white,

              child: const Center(child: CircularProgressIndicator()),
            ),

          if (_totalFields > 0)
            Positioned(
              left: 30,
              right: 30,

              bottom: 10 + MediaQuery.of(context).padding.bottom,

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  GestureDetector(
                    onTap: _currentFieldIndex > 0
                        ? () => _navigateField(-1)
                        : null,

                    child: Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: _currentFieldIndex > 0
                            ? const Color(0xFF1B5EF7)
                            : Colors.grey.shade300,

                        borderRadius: BorderRadius.circular(14),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),

                            blurRadius: 6,

                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Icon(
                        Icons.chevron_left_rounded,

                        size: 24,

                        color: _currentFieldIndex > 0
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _currentFieldIndex < _totalFields - 1
                        ? () => _navigateField(1)
                        : null,

                    child: Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: _currentFieldIndex < _totalFields - 1
                            ? const Color(0xFF1B5EF7)
                            : Colors.grey.shade300,

                        borderRadius: BorderRadius.circular(14),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),

                            blurRadius: 6,

                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Icon(
                        Icons.chevron_right_rounded,

                        size: 24,

                        color: _currentFieldIndex < _totalFields - 1
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
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
