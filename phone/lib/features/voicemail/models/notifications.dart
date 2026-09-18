import 'package:flutter/widgets.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// What the person is told when something asked of the mailbox did not happen.
///
/// Only for the refusals that say nothing for themselves. A message the
/// backend no longer has is answered on the row it took with it, and a mailbox
/// that could not be read at all is answered by the retry view in its place.
/// What was left over was a write that did not go through: logged, recorded,
/// and never mentioned, so the screen went on showing the message exactly as
/// it was and the tap read as if it had never been made.
///
/// Each is a sentence about what did not happen, not about what went wrong.
/// The reason is the backend's and means nothing to the person holding the
/// phone; what they need is to know the message is still there, so they can
/// try again or leave it.
final class VoicemailDeleteFailedNotification extends MessageNotification {
  const VoicemailDeleteFailedNotification({this.count = 1});

  /// How many messages the delete was over. One for a row, several for a
  /// selection - and the sentence says which, because "the message" after
  /// deleting eleven of them is a sentence about the wrong thing.
  final int count;

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_deleteFailed(count);
}

final class VoicemailRestoreFailedNotification extends MessageNotification {
  const VoicemailRestoreFailedNotification({this.count = 1});

  final int count;

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_restoreFailed(count);
}

/// Marking a message read or unread, keeping it or letting it go.
///
/// One sentence for all four, because the person did not think of them as four
/// different things and the flag they touched is on screen to be seen.
final class VoicemailUpdateFailedNotification extends MessageNotification {
  const VoicemailUpdateFailedNotification();

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_updateFailed;
}

final class VoicemailEmptyTrashFailedNotification extends MessageNotification {
  const VoicemailEmptyTrashFailedNotification();

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_emptyTrashFailed;
}

/// A read that failed while there was still a list on screen.
///
/// The one case where the list is not the answer: with nothing to show, the
/// screen puts a retry in place of the list and says it there. With something
/// to show it stays, silently out of date, and this is what says so.
final class VoicemailRefreshFailedNotification extends MessageNotification {
  const VoicemailRefreshFailedNotification();

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_refreshFailed;
}
