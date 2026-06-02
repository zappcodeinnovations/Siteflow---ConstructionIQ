import 'package:euroside/modules/announcements/model/announcement_model.dart';
import 'package:euroside/services/announcement_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class AnnouncementPage extends StatelessWidget {
  final int projectId;

  final String projectName;

  const AnnouncementPage({
    super.key,

    required this.projectId,

    required this.projectName,
  });

  static const Color _bg = Color(0xffF4F7FB);

  static const Color _surface = Colors.white;

  static const Color _text = Color(0xff0F172A);

  static const Color _subText = Color(0xff64748B);

  String _formatDateTime(String value) {
    try {
      final parsedDateTime = DateTime.parse(value).toLocal();

      return DateFormat('dd MMM yyyy, hh:mm a').format(parsedDateTime);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,

        elevation: 0,

        scrolledUnderElevation: 0,

        title: Text(
          "$projectName Announcements",

          style: const TextStyle(
            color: _text,

            fontWeight: FontWeight.w700,

            fontSize: 18,
          ),
        ),
      ),

      body: FutureBuilder<List<AnnouncementModel>>(
        future: AnnouncementService.getAnnouncements(),

        builder: (context, snapshot) {
          /// LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Iconsax.warning_2,

                      size: 70,

                      color: Colors.red.shade300,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Failed to load announcements",

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          /// FILTER PROJECT ANNOUNCEMENTS
          final announcements = snapshot.data!
              .where((e) => e.projectId == projectId)
              .toList();

          /// EMPTY
          if (announcements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Iconsax.notification,

                      size: 70,

                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "No announcements available",

                      style: TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          /// SUCCESS
          return ListView.builder(
            padding: const EdgeInsets.all(18),

            itemCount: announcements.length,

            itemBuilder: (context, index) {
              final item = announcements[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: _surface,

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),

                      blurRadius: 10,

                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /// ICON
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.1),

                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Iconsax.notification,

                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(width: 16),

                    /// CONTENT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// TITLE
                          Text(
                            item.title,

                            style: const TextStyle(
                              fontSize: 16,

                              fontWeight: FontWeight.w700,

                              color: _text,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// MESSAGE
                          Text(
                            item.message,

                            style: const TextStyle(
                              color: _subText,

                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          /// FOOTER
                          Row(
                            children: [
                              Icon(
                                Iconsax.user,

                                size: 14,

                                color: Colors.grey.shade600,
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: Text(
                                  item.createdByName,

                                  maxLines: 1,

                                  overflow: TextOverflow.ellipsis,

                                  style: const TextStyle(
                                    color: _subText,

                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _formatDateTime(item.createdAt),

                            style: const TextStyle(
                              color: _subText,

                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: Duration(milliseconds: index * 120));
            },
          );
        },
      ),
    );
  }
}
