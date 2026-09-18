import 'package:webtrit_phone/app/notifications/models/notification.dart';

import 'notifications.dart';

/// Everything that differs between the five per-message actions, declared
/// rather than passed in at each call.
///
/// What they have in common - the screen showing work, the reading of a
/// refusal, what may be concluded from it - is written once and reads the same
/// for all of them; only the columns below are per action.
enum VoicemailAction {
  remove('removeVoicemail', voicemailDeleteFailed),
  restore('restoreVoicemail', voicemailRestoreFailed, rereadsTrash: true),
  removePermanently('removeVoicemailPermanently', voicemailDeleteFailed, rereadsTrash: true),
  toggleSeen('toggleSeenStatus', voicemailUpdateFailed),
  toggleSaved('toggleSavedStatus', voicemailUpdateFailed);

  const VoicemailAction(this.name, this.whenFailed, {this.rereadsTrash = false});

  /// What a log line and a crash report are filed under.
  final String name;

  /// What the person is told when it did not happen, given what went wrong.
  ///
  /// Only for a refusal that says nothing about the message: one that says the
  /// message is gone is answered where the row was, by whoever asked. The
  /// failure is carried into the notification rather than into the sentence -
  /// it is what the details behind it are made of.
  final Notification Function(Object error) whenFailed;

  /// Whether it changes what the trash holds.
  ///
  /// The trash keeps no stored copy that could be corrected in place, so while
  /// it is what is on screen it is read again rather than adjusted.
  final bool rereadsTrash;
}
