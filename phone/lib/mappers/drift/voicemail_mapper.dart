import 'package:api/api.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

mixin VoicemailMapper {
  VoicemailData voicemailToDrift(
    UserVoicemailSummary userVoicemailItem,
    UserVoicemail userVoicemailDetails,
    String attachmentUrl,
  ) {
    final voicemail = VoicemailData(
      id: userVoicemailItem.id,
      date: userVoicemailItem.date,
      duration: userVoicemailItem.duration,
      sender: userVoicemailDetails.sender,
      receiver: userVoicemailDetails.receiver,
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
