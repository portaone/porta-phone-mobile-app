import 'package:webtrit_phone/models/models.dart';

extension ContactVoicemailExt on Contact {
  /// Whether a voicemail can be forwarded to this contact.
  ///
  /// Forwarding addresses a user on the backend rather than a phone number, so
  /// three things have to hold. The contact has to come from the backend at
  /// all; the id it came with has to be the server's own rather than one this
  /// app invented to keep the row unique; and it must not be the person doing
  /// the forwarding.
  ///
  /// The last one matters more than it looks. The backend happily accepts a
  /// forward to oneself and answers with a second copy of the message in the
  /// same mailbox, counted against the same quota - a way to waste space that
  /// no one would ask for on purpose. `== false` rather than `!= true`: a
  /// backend that omits the flag hides everyone rather than risking that.
  bool get canReceiveForwardedVoicemail {
    final sourceId = this.sourceId;

    return sourceType == ContactSourceType.external &&
        sourceId != null &&
        sourceId.isNotEmpty &&
        !ExternalContact.isSyntheticSourceId(sourceId) &&
        isCurrentUser == false;
  }
}
