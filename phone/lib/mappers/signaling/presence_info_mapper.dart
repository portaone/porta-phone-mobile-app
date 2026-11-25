import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/iso_instant.dart';

import 'package:signaling/signaling.dart';

class SignalingPresenceInfoMapper {
  static PresenceInfo fromSignaling(SignalingPresenceInfo data) {
    return PresenceInfo(
      id: data.id,
      number: data.number,
      available: data.available,
      note: data.note,
      statusIcon: data.statusIcon,
      device: data.device,
      timeOffsetMin: data.timeOffsetMin,
      timestamp: _instant(data.timestamp, data.timeOffsetMin),
      activities: data.activities
          .map((activity) {
            return switch (activity) {
              kPresenceActivityKeyAway => PresenceActivity.away,
              kPresenceActivityKeyBusy => PresenceActivity.busy,
              kPresenceActivityKeySleeping => PresenceActivity.sleeping,
              kPresenceActivityKeyDoNotDisturb => PresenceActivity.doNotDisturb,
              kPresenceActivityKeyPermanentAbsence => PresenceActivity.permanentAbsence,
              kPresenceActivityKeyOnThePhone => PresenceActivity.onThePhone,
              kPresenceActivityKeyMeal => PresenceActivity.meal,
              kPresenceActivityKeyMeeting => PresenceActivity.meeting,
              kPresenceActivityKeyAppointment => PresenceActivity.appointment,
              kPresenceActivityKeyVacation => PresenceActivity.vacation,
              kPresenceActivityKeyTravel => PresenceActivity.travel,
              kPresenceActivityKeyInTransit => PresenceActivity.inTransit,
              _ => null,
            };
          })
          .nonNulls
          .toList(),
      source: PresenceInfoSource.values.byName(data.source.name),
      // Core's own stamp, on one clock for every record, which is what lets
      // the records of a number be put in order. Stamping it here instead made
      // every record of an update "arrive" together.
      arrivalTime: data.arrivalTime,
    );
  }

  /// The publisher's time as an instant.
  ///
  /// Builds of this app in the field send their wall clock with no zone and
  /// their offset beside it. Parsed as it stands such a time lands in the
  /// zone of whoever is reading, so the offset is what turns it into an
  /// instant. A time that names its zone is taken as it is.
  static DateTime? _instant(String? timestamp, int? timeOffsetMin) {
    return parseIsoInstant(timestamp, wallClockOffsetMin: timeOffsetMin);
  }
}

mixin SignalingPresenceInfoMapperMixin {
  PresenceInfo fromSignaling(SignalingPresenceInfo data) => SignalingPresenceInfoMapper.fromSignaling(data);
}
