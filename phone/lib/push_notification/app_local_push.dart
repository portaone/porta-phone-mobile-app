import 'package:webtrit_phone/app/constants.dart';

class AppLocalPush {
  final int id;
  final String title;
  final String body;
  final Map<String, String>? payload;

  /// The body is a sentence or two that must be read whole: Android shows it expanded
  /// instead of cutting it to one line.
  final bool longBody;

  AppLocalPush(this.id, this.title, this.body, {this.payload, this.longBody = false});

  factory AppLocalPush.missedCall(String callId, String title, String callerName) {
    return AppLocalPush(callId.hashCode, title, callerName, payload: {'callId': callId, 'type': 'missed_call'});
  }

  /// A new message [voicemailId] in the mailbox.
  factory AppLocalPush.voicemail(String voicemailId, String title, String body) {
    return AppLocalPush(
      voicemailIdOf(voicemailId),
      title,
      body,
      payload: {'source': kLocalPushSourceVoicemail, 'voicemailId': voicemailId},
    );
  }

  /// The id of the local push for the message [voicemailId].
  ///
  /// Keyed by the message, so a second push for the same message replaces the
  /// first in the shade instead of stacking beside it. Negative, because every
  /// other local push takes a non-negative id - database ids of messages and
  /// system notifications, and string hash codes, which the Dart VM keeps
  /// non-negative - and a shared id would silently replace one of them.
  static int voicemailIdOf(String voicemailId) => -1 - (voicemailId.hashCode & 0x3fffffff);

  /// A notification of the app shown in the shade because the app was out of sight (see
  /// `NotificationDelivery.shade`). The system names the app above it, so the message is the
  /// body, whole, with no title of its own. Tapping it only opens the app: its source has no
  /// channel in `LocalPushsBroker`.
  factory AppLocalPush.notice(String text) {
    return AppLocalPush(noticeIdOf(text), '', text, payload: {'source': kLocalPushSourceNotice}, longBody: true);
  }

  /// The id of the notice [text].
  ///
  /// Keyed by the text, so the same message again replaces the one already in the shade
  /// instead of stacking beside it. Below the voicemail range ([voicemailIdOf]) and so apart
  /// from every other local push, which take non-negative ids.
  static int noticeIdOf(String text) => -0x40000001 - (text.hashCode & 0x3fffffff);

  @override
  String toString() {
    return 'AppLocalPush{id: $id, title: $title, body: $body, payload: $payload}';
  }
}
