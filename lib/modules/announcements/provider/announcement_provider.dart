import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/announcement_services.dart';
import '../model/announcement_model.dart';

final announcementsProvider =
    FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
      ref.keepAlive();
      return AnnouncementService.getAnnouncements();
    });
