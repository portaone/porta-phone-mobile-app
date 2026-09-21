import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// What the user picked on the mute sheet.
///
/// The durations are the four the product asks for; a mute set for one of
/// them while another is in force replaces it, which is what "change the
/// duration" is - the core treats a second mute the same way.
enum MuteChoice {
  unmute,
  oneHour,
  eightHours,
  twoDays,
  forever;

  /// Carries the choice to whoever mutes, in the one place that knows the
  /// difference between [forever] and [unmute] - both have no duration, and
  /// a caller reading a duration alone would mute for good on an unmute.
  void dispatch({required void Function(Duration? duration) mute, required VoidCallback unmute}) {
    switch (this) {
      case MuteChoice.unmute:
        unmute();
      case MuteChoice.oneHour:
        mute(const Duration(hours: 1));
      case MuteChoice.eightHours:
        mute(const Duration(hours: 8));
      case MuteChoice.twoDays:
        mute(const Duration(days: 2));
      case MuteChoice.forever:
        mute(null);
    }
  }
}

/// Automation id of one row of the sheet, from the choice it stands for.
String notificationMuteOptionId(MuteChoice choice) => settingsOptionId(notificationMuteOptionIdPrefix, choice.name);

/// The modal bottom sheet that picks how long a conversation's notifications
/// stay off.
///
/// Closes with the choice, or with nothing when it is dismissed. The way back
/// to sound - "Unmute" - is offered first and only while a mute is in force:
/// a sheet that offers to unmute what is not muted asks a question with no
/// answer.
class NotificationMuteSheet extends StatelessWidget {
  const NotificationMuteSheet({required this.muted, super.key});

  /// Whether a mute is in force at the moment the sheet opens.
  final bool muted;

  static Future<MuteChoice?> show(BuildContext context, {required bool muted}) {
    // Sized by its rows rather than capped at the framework's share of the
    // screen, which five rows and a title do not fit on a small one.
    return context.showModalBottomSheet<MuteChoice>(
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => NotificationMuteSheet(muted: muted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SemanticId(
      identifier: notificationMuteSheetId,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(l10n.messaging_NotificationMute_sheetTitle, style: theme.textTheme.titleMedium),
              ),
              if (muted)
                _option(
                  context,
                  MuteChoice.unmute,
                  Icons.notifications_active_outlined,
                  l10n.messaging_NotificationMute_unmute,
                ),
              _option(context, MuteChoice.oneHour, Icons.snooze, l10n.messaging_NotificationMute_forOneHour),
              _option(context, MuteChoice.eightHours, Icons.snooze, l10n.messaging_NotificationMute_forEightHours),
              _option(context, MuteChoice.twoDays, Icons.snooze, l10n.messaging_NotificationMute_forTwoDays),
              _option(
                context,
                MuteChoice.forever,
                Icons.notifications_off_outlined,
                l10n.messaging_NotificationMute_forever,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(BuildContext context, MuteChoice choice, IconData icon, String label) {
    return SemanticAction(
      identifier: notificationMuteOptionId(choice),
      child: ListTile(leading: Icon(icon), title: Text(label), onTap: () => Navigator.pop(context, choice)),
    );
  }
}
