import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/models/models.dart';

import 'package:signaling/signaling.dart';

class SignalingPresenceSettingsMapper {
  static SignalingPresenceSettings toSignaling(PresenceSettings data) {
    return SignalingPresenceSettings(
      available: data.available,
      note: data.note,
      statusIcon: data.statusIcon,
      device: data.device,
      timeOffsetMin: data.timeOffsetMin,
      // As an instant, zone and all. The wall clock with no zone that used to
      // go out was read by each client in its own way, and two devices of one
      // person could not be put in order by it.
      timestamp: _instant(data).toIso8601String(),
      activity: switch (data.activity) {
        PresenceActivity.away => kPresenceActivityKeyAway,
        PresenceActivity.busy => kPresenceActivityKeyBusy,
        PresenceActivity.sleeping => kPresenceActivityKeySleeping,
        PresenceActivity.doNotDisturb => kPresenceActivityKeyDoNotDisturb,
        PresenceActivity.permanentAbsence => kPresenceActivityKeyPermanentAbsence,
        PresenceActivity.onThePhone => kPresenceActivityKeyOnThePhone,
        PresenceActivity.meal => kPresenceActivityKeyMeal,
        PresenceActivity.meeting => kPresenceActivityKeyMeeting,
        PresenceActivity.appointment => kPresenceActivityKeyAppointment,
        PresenceActivity.vacation => kPresenceActivityKeyVacation,
        PresenceActivity.travel => kPresenceActivityKeyTravel,
        PresenceActivity.inTransit => kPresenceActivityKeyInTransit,
        null => null,
      },
      dndMode: data.dndMode,
    );
  }

  /// The moment the status was set, in UTC.
  ///
  /// A time held in UTC is that moment already. A local one is the wall clock
  /// of [PresenceSettings.timeOffsetMin], the offset taken together with it,
  /// and is not converted through the zone the phone is in now: after the
  /// phone moved to another zone that would name a different moment.
  static DateTime _instant(PresenceSettings data) {
    final timestamp = data.timestamp;
    if (timestamp.isUtc) return timestamp;

    return DateTime.utc(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      timestamp.second,
      timestamp.millisecond,
      timestamp.microsecond,
    ).subtract(Duration(minutes: data.timeOffsetMin));
  }
}

mixin SignalingPresenceSettingMapperMixin {
  SignalingPresenceSettings toSignaling(PresenceSettings data) => SignalingPresenceSettingsMapper.toSignaling(data);
}
