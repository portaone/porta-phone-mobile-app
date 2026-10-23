import 'package:webtrit_phone/app/constants.dart';

class AppLocalPush {
  final int id;
  final String title;
  final String body;
  final Map<String, String>? payload;

  AppLocalPush(this.id, this.title, this.body, {this.payload});

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

  @override
  String toString() {
    return 'AppLocalPush{id: $id, title: $title, body: $body, payload: $payload}';
  }
}
