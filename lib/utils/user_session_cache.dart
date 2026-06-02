import 'package:euroside/modules/all_projects/provider/all_project_provider.dart';
import 'package:euroside/modules/announcements/provider/announcement_provider.dart';
import 'package:euroside/modules/form/provider/form_provider.dart';
import 'package:euroside/modules/notifications/provider/notification_provider.dart';
import 'package:euroside/modules/profile/provider/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void resetUserSessionCache(WidgetRef ref) {
  ref.invalidate(profileControllerProvider);
  ref.invalidate(AllprojectControllerProvider);
  ref.invalidate(formsListProvider);
  ref.invalidate(formStatusKpiProvider);
  ref.invalidate(announcementsProvider);
  ref.invalidate(notificationsProvider);
}
