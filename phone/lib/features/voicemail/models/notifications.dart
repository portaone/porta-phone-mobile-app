import 'package:flutter/material.dart' hide Notification;

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// Confirms a message went to the trash, and offers the way back.
///
/// Said through the notifications channel rather than by the row that was
/// tapped, because by the time the backend answers that row is usually gone -
/// the list has been re-read and the message is no longer in it.
final class VoicemailMovedToTrashNotification extends MessageNotification {
  const VoicemailMovedToTrashNotification({required this.onUndo});

  /// Putting it back is an action of its own and answers for itself, so this
  /// only starts it.
  final VoidCallback onUndo;

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_movedToTrash;

  @override
  SnackBarAction? action(BuildContext context) =>
      SnackBarAction(label: context.l10n.voicemail_Label_undo, onPressed: onUndo);
}

/// Says why the row a person acted on has gone.
///
/// The one refusal that explains itself: the backend no longer has the message,
/// so the list has been read again and the row went with it. Without this the
/// row would simply vanish under the finger that touched it.
final class VoicemailMessageGoneNotification extends MessageNotification {
  const VoicemailMessageGoneNotification();

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_messageGone;
}
