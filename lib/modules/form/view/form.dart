import 'dart:convert';
import 'dart:io';
import 'package:euroside/network/api_endpoint.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

Widget _permissionStep(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 12,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    ),
  );
}

class _UserFormWebViewPageState extends State<UserFormWebViewPage> {
  late final WebViewController _controller;

  final ImagePicker _imagePicker = ImagePicker();

  static const int _maxUploadDimension = 1600;
  static const int _maxUploadFileSizeBytes = 8 * 1024 * 1024;
  static const int _imageQuality = 55;

  bool isLoading = true;
  bool _isValidationDialogVisible = false;
  bool _isNativePickerOpen = false;

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
            _handleFormSubmitted();
          }

          if (message.message.startsWith("FORM_VALIDATION:")) {
            final payload = message.message.replaceFirst(
              "FORM_VALIDATION:",
              "",
            );
            final dynamic parsed = _tryDecodeJson(payload);

            if (parsed != null) {
              _showFormValidationDialog(parsed);
            }
          }

          if (message.message.startsWith("FORM_ALERT:")) {
            final alertMessage = message.message.replaceFirst(
              "FORM_ALERT:",
              "",
            );

            _showFormValidationDialog({
              'message': alertMessage,
              'errors': <String, dynamic>{},
            });
          }

          if (message.message == "OPEN_GALLERY") {
            if (!_isNativePickerOpen) {
              _pickFromGallery();
            }
          }

          if (message.message == "OPEN_CAMERA") {
            if (!_isNativePickerOpen) {
              _pickFromCamera();
            }
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
      if (window.flutterPhotoButtonInterceptorInstalled)
        return;

      window.flutterPhotoButtonInterceptorInstalled = true;

      function getUploadAction(element) {
        var current = element;

        while (current && current !== document.body) {
          if (
            current.tagName === 'BUTTON' ||
            (current.tagName === 'INPUT' && current.type === 'button') ||
            current.getAttribute('role') === 'button'
          ) {
            const text =
              (
                current.innerText ||
                current.value ||
                current.getAttribute('aria-label') ||
                ''
              ).toLowerCase();

            if(
              text.includes('choose photo') ||
              text.includes('choose from gallery') ||
              text.includes('choose from gallary') ||
              text.includes('gallery')
            ) {
              return 'OPEN_GALLERY';
            }

            if(text.includes('open camera')) {
              return 'OPEN_CAMERA';
            }
          }

          current = current.parentElement;
        }

        return null;
      }

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

          btn.setAttribute('data-flutter-upload-action', 'OPEN_GALLERY');
        }

        /// CAMERA
        if(
          text.includes('open camera')
        ) {
          btn.setAttribute('data-flutter-upload-action', 'OPEN_CAMERA');
        }
      });

      document.addEventListener(
        'click',
        function(e) {
          const uploadButton =
            e.target && e.target.closest
              ? e.target.closest('[data-flutter-upload-action]')
              : null;

          const action = uploadButton
            ? uploadButton.getAttribute('data-flutter-upload-action')
            : getUploadAction(e.target);

          if (!action)
            return;

          e.preventDefault();
          e.stopPropagation();
          e.stopImmediatePropagation();

          Flutter.postMessage(action);
        },
        true
      );
    }

    setTimeout(
      setupPhotoButtons,
      1000
    );
  """);

            await _controller.runJavaScript("""
    (function() {
      if (window.flutterApiInterceptorInstalled)
        return;

      window.flutterApiInterceptorInstalled = true;
              window.flutterFormSubmittedHandled = false;

      function parseJson(raw) {
        if (!raw || typeof raw !== 'string')
          return null;

        try {
          return JSON.parse(raw);
        } catch (e) {
          return null;
        }
      }

      function postValidationIfAny(data) {
        if (!data || typeof data !== 'object')
          return;

        if (data.success === false && (data.message || data.errors)) {
          Flutter.postMessage('FORM_VALIDATION:' + JSON.stringify(data));
        }
      }

      function postSuccessIfAny(data) {
        if (!data || typeof data !== 'object')
          return;

        const message = String(data.message || '').toLowerCase();
        const looksSuccessful =
          data.success === true ||
          message.includes('form submitted successfully') ||
          message.includes('submitted successfully') ||
          message.includes('success');

        if (looksSuccessful && !window.flutterFormSubmittedHandled) {
          window.flutterFormSubmittedHandled = true;
          Flutter.postMessage('FORM_SUBMITTED');
        }
      }

      if (window.fetch) {
        const originalFetch = window.fetch;

        window.fetch = function() {
          return originalFetch.apply(this, arguments).then(function(response) {
            try {
              response.clone().text().then(function(bodyText) {
                const data = parseJson(bodyText);

                if (data) {
                  postValidationIfAny(data);
                  postSuccessIfAny(data);
                }
              });
            } catch (e) {}

            return response;
          });
        };
      }

      const originalOpen = XMLHttpRequest.prototype.open;
      const originalSend = XMLHttpRequest.prototype.send;

      XMLHttpRequest.prototype.open = function() {
        return originalOpen.apply(this, arguments);
      };

      XMLHttpRequest.prototype.send = function() {
        this.addEventListener('load', function() {
          const data = parseJson(this.responseText);

          if (data) {
            postValidationIfAny(data);
            postSuccessIfAny(data);
          }
        });

        return originalSend.apply(this, arguments);
      };
    })();
  """);

            await _controller.runJavaScript("""
    window.flutterUploadState = window.flutterUploadState || {
      files: []
    };

    function getTargetFileInput() {
      const inputs = document.querySelectorAll('input[type=file]');

      return inputs.length ? inputs[inputs.length - 1] : null;
    }

    function rebuildInputFiles(dispatchChange) {
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

      if (dispatchChange !== false) {
        window.flutterApplyingNativeFiles = true;

        input.dispatchEvent(
          new Event('change', {
            bubbles: true,
          })
        );

        setTimeout(function() {
          window.flutterApplyingNativeFiles = false;
        }, 300);
      }
    }

    window.rebuildFlutterSelectedFiles = function() {
      rebuildInputFiles(true);
    };

    window.clearFlutterSelectedFiles = function(dispatchChange) {
      window.flutterUploadState.files = [];
      rebuildInputFiles(dispatchChange);
    };

    window.addFlutterSelectedFile = function(payload, skipRebuild) {
      if (!payload || !payload.name || !payload.base64) {
        return;
      }

      const alreadyAdded = window.flutterUploadState.files.some(function(item) {
        return item.name === payload.name && item.base64 === payload.base64;
      });

      if (!alreadyAdded) {
        window.flutterUploadState.files.push(payload);
      }

      if (!skipRebuild) {
        rebuildInputFiles();
      }
    };
  """);

            /// SUCCESS ALERT
            await _controller.runJavaScript("""
    window.alert =
      function(message) {

      const text = String(message || '');
      const normalized = text.toLowerCase();

      if(
        normalized.includes('form submitted successfully') ||
        normalized.includes('submitted successfully') ||
        normalized.includes('success')
      ) {

        if (!window.flutterFormSubmittedHandled) {
          window.flutterFormSubmittedHandled = true;

          Flutter.postMessage(
            'FORM_SUBMITTED'
          );
        }

        return;
      }

      Flutter.postMessage(
        'FORM_ALERT:' + text
      );
    };
  """);
          },

          onWebResourceError: (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.description)));
          },
        ),
      );

    _loadFormPage(fullUrl);
  }

  dynamic _tryDecodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFormPage(String fullUrl) async {
    try {
      final response = await http.get(Uri.parse(fullUrl));
      final body = response.body.trim();
      final contentType = response.headers['content-type'] ?? '';

      final isJsonResponse =
          contentType.contains('application/json') ||
          body.startsWith('{') ||
          body.startsWith('[');

      if (isJsonResponse) {
        final data = _tryDecodeJson(body);

        if (data != null) {
          _showFormValidationDialog(data);
        } else {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open form right now.')),
          );
        }

        setState(() {
          isLoading = false;
        });

        return;
      }

      await _controller.loadRequest(Uri.parse(fullUrl));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load form: $error')));
    }
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
    if (_isNativePickerOpen) {
      return;
    }

    _isNativePickerOpen = true;

    try {
      final status = await Permission.camera.status;

      if (!status.isGranted) {
        final result = await Permission.camera.request();

        if (!result.isGranted) {
          await _showCameraPermissionDialog();
          return;
        }
      }

      await _controller.runJavaScript(
        'window.clearFlutterSelectedFiles(false);',
      );

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: _imageQuality,
        maxWidth: _maxUploadDimension.toDouble(),
        maxHeight: _maxUploadDimension.toDouble(),
      );

      if (image == null) return;

      await _injectSelectedFile(image.path);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera capture failed: $e')));
    } finally {
      _isNativePickerOpen = false;
    }
  }

  Future<void> _showCameraPermissionDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFF97316),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Camera permission required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enable camera access in your device settings to capture photos for this form.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to enable it',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _permissionStep('Open Settings'),
                      _permissionStep('Tap Permissions or Apps > Permissions'),
                      _permissionStep('Turn on Camera access'),
                      _permissionStep('Return to the app and try again'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.settings_rounded, size: 18),
                        label: const Text(
                          'Open Settings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isNativePickerOpen) {
      return;
    }

    _isNativePickerOpen = true;

    try {
      await _controller.runJavaScript(
        'window.clearFlutterSelectedFiles(false);',
      );

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: _imageQuality,
        maxWidth: _maxUploadDimension.toDouble(),
        maxHeight: _maxUploadDimension.toDouble(),
      );

      if (images.isEmpty) return;

      final List<String> selectedNames = [];

      for (final image in images) {
        final fileName = image.path.split(RegExp(r'[\\/]')).last;

        selectedNames.add(fileName);

        await _injectSelectedFile(
          image.path,
          rebuildInput: false,
          showSnackBar: false,
        );
      }

      await _controller.runJavaScript('window.rebuildFlutterSelectedFiles();');

      _showSelectedFilesSnackBar(selectedNames);
    } catch (e) {
      debugPrint("Gallery Error: $e");
    } finally {
      _isNativePickerOpen = false;
    }
  }

  Future<void> _pickDocument() async {
    if (_isNativePickerOpen) {
      return;
    }

    _isNativePickerOpen = true;

    try {
      await _controller.runJavaScript(
        'window.clearFlutterSelectedFiles(false);',
      );

      final result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.single.path == null) {
        return;
      }

      await _injectSelectedFile(result.files.single.path!);
    } finally {
      _isNativePickerOpen = false;
    }
  }

  Future<void> _injectSelectedFile(
    String filePath, {
    bool rebuildInput = true,
    bool showSnackBar = true,
  }) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      if (fileSize > _maxUploadFileSizeBytes) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected image is too large. Please choose a smaller photo.',
            ),
          ),
        );
        return;
      }

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

      await _controller.runJavaScript(
        "window.addFlutterSelectedFile(${jsonEncode({'name': fileName, 'mimeType': mimeType, 'base64': base64Data})}, true);",
      );

      if (rebuildInput) {
        await _controller.runJavaScript(
          'window.rebuildFlutterSelectedFiles();',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not attach the selected file: $e')),
      );
    }
  }

  void _showSelectedFilesSnackBar(List<String> files) {
    if (!mounted || files.isEmpty) return;

    final isMultiple = files.length > 1;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),

        content: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),

            border: Border.all(color: const Color(0xffE5E7EB)),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: const Color(0xffEEF4FF),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  isMultiple ? Icons.collections_rounded : Icons.image_rounded,
                  color: const Color(0xff2563EB),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      isMultiple
                          ? "${files.length} files selected"
                          : "1 file selected",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...files
                        .take(3)
                        .map(
                          (file) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_rounded,
                                  size: 14,
                                  color: Color(0xff64748B),
                                ),

                                const SizedBox(width: 6),

                                Expanded(
                                  child: Text(
                                    file,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                    if (files.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "+${files.length - 3} more files",
                          style: const TextStyle(
                            color: Color(0xff2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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
  }

  void _handleFormSubmitted() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Form submitted successfully.'),
      ),
    );

    Navigator.pop(context);
  }

  void _showFormValidationDialog(dynamic responseBody) {
    if (!mounted || _isValidationDialogVisible) {
      return;
    }

    String message = 'Please add live photo and signature.';
    final List<String> fieldMessages = [];

    if (responseBody is Map) {
      final serverMessage = responseBody['message']?.toString().trim();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        message = serverMessage;
      }

      final errors = responseBody['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;

          if (value is List && value.isNotEmpty) {
            fieldMessages.add(value.first.toString());
          } else if (value is String && value.isNotEmpty) {
            fieldMessages.add(value);
          }
        }
      }
    } else if (responseBody is String && responseBody.trim().isNotEmpty) {
      message = responseBody.trim();
    }

    _isValidationDialogVisible = true;

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
                    color: const Color(0xffF59E0B).withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffF59E0B),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Form Validation',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    height: 1.5,
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                if (fieldMessages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFCD34D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: fieldMessages
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $item',
                                style: const TextStyle(
                                  color: Color(0xff92400E),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isValidationDialogVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final webViewBottomPadding = Platform.isIOS ? bottomInset + 140 : 60.0;
    final controlsBottom = 10.0 + bottomInset + (Platform.isIOS ? 8.0 : 0.0);

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
              padding: EdgeInsets.only(bottom: webViewBottomPadding),

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

              bottom: controlsBottom,

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
