import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'system_notification_type_icon.dart';

/// One notice on a watch: the kind's mark, the title, three lines of the text
/// and the time; marked seen once it shows.
///
/// The tint of an unseen notice is the one it had when it first showed, held
/// while the card is on the face: the seen mark queued as it shows turns the
/// notice seen a moment later, and a tint following that would be gone before
/// it could be noticed.
class SystemNotificationWatchCard extends StatefulWidget {
  const SystemNotificationWatchCard({
    required this.notification,
    required this.time,
    required this.seen,
    required this.onSeen,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final SystemNotification notification;
  final String time;
  final bool seen;
  final VoidCallback onSeen;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<SystemNotificationWatchCard> createState() => _SystemNotificationWatchCardState();
}

class _SystemNotificationWatchCardState extends State<SystemNotificationWatchCard> {
  late final bool unseenWhenShown = !widget.seen;

  @override
  void initState() {
    super.initState();
    // Built when it scrolls into view: that is when it has been seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.seen) widget.onSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    return WatchNoticeCard(
      leading: Icon(notification.type.icon),
      title: notification.title,
      body: notification.content,
      time: widget.time,
      unread: unseenWhenShown,
      onTap: widget.onOpen,
      onLongPress: widget.onDelete,
      longPressHint: context.l10n.system_notifications_SemanticsAction_delete,
    );
  }
}
