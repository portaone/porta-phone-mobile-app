import 'package:api/api.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

mixin VoicemailMapper {
  /// A row is built from the list item alone. The backend may list a message
  /// without its sender - one whose headers it could not read - and such a row
  /// is stored with an empty one rather than left out: the recording is still
  /// there to be heard. See [Voicemail.hasSender].
  VoicemailData voicemailToDrift(UserVoicemailSummary userVoicemailItem, String attachmentUrl) {
    final voicemail = VoicemailData(
      id: userVoicemailItem.id,
      date: userVoicemailItem.date,
      duration: userVoicemailItem.duration,
      sender: userVoicemailItem.sender ?? '',
      receiver: userVoicemailItem.receiver ?? '',
      seen: userVoicemailItem.seen,
      size: userVoicemailItem.size,
      type: userVoicemailItem.type,
      attachmentPath: attachmentUrl,
      // Read off the list item rather than the details: both carry them, and
      // the list is the half a refresh always has.
      saved: userVoicemailItem.saved,
      forwardedBy: userVoicemailItem.forwardedBy,
    );

    return voicemail;
  }

  Voicemail voicemailFromDrift(VoicemailData voicemailData, String? contactName, {ReadStatus? readStatus}) {
    final currentReadStatus = readStatus ?? (voicemailData.seen ? ReadStatus.read : ReadStatus.unread);
    return Voicemail(
      id: voicemailData.id,
      date: voicemailData.date,
      duration: voicemailData.duration,
      sender: voicemailData.sender,
      displaySender: contactName ?? voicemailData.sender,
      receiver: voicemailData.receiver,
      status: currentReadStatus,
      size: voicemailData.size,
      type: voicemailData.type,
      url: voicemailData.attachmentPath,
      saved: voicemailData.saved,
      forwardedBy: voicemailData.forwardedBy,
    );
  }
}
