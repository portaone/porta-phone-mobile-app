import 'package:flutter/material.dart' hide Notification;

import 'package:auto_route/auto_route.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
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

/// What the person is told when something asked of the mailbox did not happen.
///
/// Only for the refusals that say nothing for themselves. A message the
/// backend no longer has has a sentence of its own above, and a mailbox that
/// could not be read at all is answered by the retry view in its place.
/// What was left over was a write that did not go through: logged, recorded,
/// and never mentioned, so the screen went on showing the message exactly as
/// it was and the tap read as if it had never been made.
///
/// The sentence says what did not happen; the reason is behind [action]. Most
/// reasons a backend gives mean nothing to the person holding the phone - it is
/// a status code and a word from another system - so putting one in the
/// sentence would trade a clear statement for an unreadable one. What it is
/// worth is being able to ask: the details screen carries the status, the
/// backend's own code and the request id, which is what a support ticket needs
/// and what nobody can recover afterwards from a snackbar that has gone.
sealed class VoicemailFailedNotification extends MessageNotification {
  const VoicemailFailedNotification(this.failure);

  /// What the backend answered, or null where it never answered at all - a
  /// request that did not arrive has nothing to show behind [action]. Kept for
  /// that and not for the sentence.
  final RequestFailure? failure;

  @override
  SnackBarAction? action(BuildContext context) {
    final failure = this.failure;
    if (failure == null) return null;

    final title = l10n(context);
    final fields = failure.errorFields(context);

    return SnackBarAction(
      label: context.l10n.default_ErrorDetails,
      onPressed: () => context.router.push(ErrorDetailsScreenPageRoute(title: title, fields: fields)),
    );
  }
}

final class VoicemailDeleteFailedNotification extends VoicemailFailedNotification {
  const VoicemailDeleteFailedNotification(super.failure, {this.count = 1});

  /// How many messages the delete was over. One for a row, several for a
  /// selection - and the sentence says which, because "the message" after
  /// deleting eleven of them is a sentence about the wrong thing.
  final int count;

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_deleteFailed(count);
}

final class VoicemailRestoreFailedNotification extends VoicemailFailedNotification {
  const VoicemailRestoreFailedNotification(super.failure, {this.count = 1});

  final int count;

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_restoreFailed(count);
}

/// Marking a message read or unread, keeping it or letting it go.
///
/// One sentence for all four, because the person did not think of them as four
/// different things and the flag they touched is on screen to be seen.
final class VoicemailUpdateFailedNotification extends VoicemailFailedNotification {
  const VoicemailUpdateFailedNotification(super.failure);

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_updateFailed;
}

final class VoicemailEmptyTrashFailedNotification extends VoicemailFailedNotification {
  const VoicemailEmptyTrashFailedNotification(super.failure);

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_emptyTrashFailed;
}

/// A read that failed while there was still a list on screen.
///
/// The one case where the list is not the answer: with nothing to show, the
/// screen puts a retry in place of the list and says it there. With something
/// to show it stays, silently out of date, and this is what says so.
final class VoicemailRefreshFailedNotification extends VoicemailFailedNotification {
  const VoicemailRefreshFailedNotification(super.failure);

  @override
  String l10n(BuildContext context) => context.l10n.voicemail_Snackbar_refreshFailed;
}
