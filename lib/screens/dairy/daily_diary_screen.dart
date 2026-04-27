import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DailyDiaryScreen extends StatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  State<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends State<DailyDiaryScreen> {
  int _selectedIndex = 1;
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _siteImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _siteImages.add(image));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildWorkDescriptionCard(),
                    const SizedBox(height: 14),
                    _buildSiteVisualsCard(),
                    const SizedBox(height: 14),
                    _buildUploadDocumentationButton(),
                    const SizedBox(height: 10),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildGpsFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.settings_input_antenna, size: 22, color: Colors.black),
              SizedBox(width: 6),
              Text(
                'EUROSIDE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDDDDDD),
            backgroundImage: const NetworkImage(
              'https://i.pravatar.cc/150?img=12',
            ),
            onBackgroundImageError: (_, __) {},
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ENGINEERING LOG',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Daily Diary',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Project: Euroside Industrial Hub \u2022 Zone 04',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'ENTRY DATE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Thursday, Oct 24, 2024',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'WORK DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Text(
                'Required field',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text field
          TextField(
            controller: _descriptionController,
            maxLines: 10,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Describe technical progress, personnel\non site, equipment utilization, and any\nunforeseen structural observations...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Color(0xFFBBBBBB),
                fontStyle: FontStyle.italic,
                height: 1.7,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 14),

          // Site Visuals section (inside card)
          const Text(
            'SITE VISUALS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildSiteVisualsGrid(),
        ],
      ),
    );
  }

  Widget _buildSiteVisualsCard() {
    // This is intentionally empty — visuals are inside the description card
    return const SizedBox.shrink();
  }

  Widget _buildSiteVisualsGrid() {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add Media tile
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 140,
              height: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFCCCCCC),
                  width: 1.5,
                  // dashed border via custom paint below
                ),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo_outlined, size: 30, color: Color(0xFFAAAAAA)),
                    SizedBox(height: 8),
                    Text(
                      'ADD MEDIA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Existing picked images
          ..._siteImages.map(
            (img) => Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: FileImage(File(img.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Static sample image (construction site)
          if (_siteImages.isEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=300&q=80',
                width: 170,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 170,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B9EB7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image, color: Colors.white54, size: 40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadDocumentationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.cloud_upload_outlined, size: 20),
        label: const Text(
          'UPLOAD DOCUMENTATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.check_circle_outline, size: 20),
        label: const Text(
          'SUBMIT DIARY ENTRY',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGpsFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF999999)),
            SizedBox(width: 4),
            Text(
              'GPS STAMP: 51.5074° N, 0.1278° W \u2022 LONDON, UK',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'System recorded login: 08:42:12 UTC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFFBBBBBB),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard, 'label': 'DASHBOARD'},
      {'icon': Icons.calendar_today, 'label': 'TIMESHEET'},
      {'icon': Icons.bar_chart, 'label': 'ACTIVITY'},
      {'icon': Icons.person, 'label': 'PROFILE'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[i]['icon'] as IconData,
                  size: 22,
                  color: selected ? Colors.black : Colors.grey,
                ),
                const SizedBox(height: 3),
                Text(
                  items[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.black : Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Draws a dashed border around the Add Media box
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = 10;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );

    final path = Path()..addRRect(rect);
    final PathMetrics metrics = path.computeMetrics();

    for (final PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next < metric.length ? next : metric.length),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}