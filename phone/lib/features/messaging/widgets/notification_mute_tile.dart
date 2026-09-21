import 'package:flutter/material.dart';

import 'package:clock/clock.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'notification_mute_sheet.dart';

/// The "Notifications" row of a conversation's info: what the mute is now,
/// and the way to change it.
///
/// [mute] is the mute in force at this moment, not the one stored - a timed
/// mute that has lapsed reads as none here, the way it does everywhere else.
/// The row itself decides nothing: it opens the sheet and hands the choice up.
class NotificationMuteTile extends StatelessWidget {
  const NotificationMuteTile({required this.mute, required this.onChoice, super.key});

  final NotificationMute mute;
  final ValueChanged<MuteChoice> onChoice;

  Future<void> _onTap(BuildContext context) async {
    final choice = await NotificationMuteSheet.show(context, muted: mute.muted);
    if (choice != null) onChoice(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SemanticAction(
      identifier: chatInfoNotificationsId,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(mute.muted ? Icons.notifications_off_outlined : Icons.notifications_outlined),
        title: Text(l10n.messaging_NotificationMute_title),
        subtitle: Text(notificationMuteSubtitle(l10n, mute)),
        onTap: () => _onTap(context),
      ),
    );
  }
}

/// The line under "Notifications": on, muted, or muted until when.
///
/// A moment later today is given as a clock time; any other is given with its
/// day, since two days is past midnight by definition. 24-hour, like the
/// timestamps in the conversation list this row is reached from.
String notificationMuteSubtitle(AppLocalizations l10n, NotificationMute mute) {
  if (!mute.muted) return l10n.messaging_NotificationMute_on;

  final until = mute.mutedUntil;
  if (until == null) return l10n.messaging_NotificationMute_muted;

  final time = until.isSameDay(clock.now()) ? until.toHHmm : '${until.toDayOfMonth} ${until.toHHmm}';
  return l10n.messaging_NotificationMute_mutedUntil(time);
}

/// The small mark on a muted conversation's row in the list.
///
/// It sits in the row's trailing slot, beside the time, whatever the row is -
/// a dialog, a group with its member count, a text thread. A mark that moves
/// from row to row is one the eye has to look for twice.
///
/// It says nothing on its own, so it carries the word for a screen reader.
class NotificationMutedIndicator extends StatelessWidget {
  const NotificationMutedIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Semantics(
        label: context.l10n.messaging_SemanticsLabel_muted,
        child: const Icon(Icons.notifications_off_outlined, size: 14),
      ),
    );
  }
}
