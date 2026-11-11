import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/system_notification.dart';

/// The mark of a kind of notification, the same on the phone and on a watch.
extension SystemNotificationTypeIcon on SystemNotificationType {
  IconData get icon => switch (this) {
    SystemNotificationType.announcement => Icons.announcement_outlined,
    SystemNotificationType.promotion => Icons.local_offer_outlined,
    SystemNotificationType.security => Icons.security_outlined,
    SystemNotificationType.system => Icons.settings_outlined,
  };
}
