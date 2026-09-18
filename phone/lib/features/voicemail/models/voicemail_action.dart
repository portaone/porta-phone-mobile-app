import 'package:webtrit_phone/app/notifications/models/notification.dart';

import 'notifications.dart';

/// Everything that differs between the five per-message actions, declared
/// rather than passed in at each call.
///
/// What they have in common - the screen showing work, the reading of a
/// refusal, what may be concluded from it - is written once and reads the same
/// for all of them; only the columns below are per action.
enum VoicemailAction {
  remove('removeVoicemail', VoicemailDeleteFailedNotification()),
  restore('restoreVoicemail', VoicemailRestoreFailedNotification(), rereadsTrash: true),
  removePermanently('removeVoicemailPermanently', VoicemailDeleteFailedNotification(), rereadsTrash: true),
  toggleSeen('toggleSeenStatus', VoicemailUpdateFailedNotification()),
  toggleSaved('toggleSavedStatus', VoicemailUpdateFailedNotification());

  const VoicemailAction(this.name, this.whenFailed, {this.rereadsTrash = false});

  /// What a log line and a crash report are filed under.
  final String name;

  /// What the person is told when it did not happen.
  ///
  /// Only for a refusal that says nothing about the message: one that says the
  /// message is gone is answered where the row was, by whoever asked.
  final Notification whenFailed;

  /// Whether it changes what the trash holds.
  ///
  /// The trash keeps no stored copy that could be corrected in place, so while
  /// it is what is on screen it is read again rather than adjusted.
  final bool rereadsTrash;
}
