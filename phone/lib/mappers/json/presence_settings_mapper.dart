import 'dart:convert';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/iso_instant.dart';

class PresenceSettingsJsonMapper {
  static String toJson(PresenceSettings data) => jsonEncode(toMap(data));

  static PresenceSettings fromJson(String json) => fromMap(jsonDecode(json));

  static Map<String, dynamic> toMap(PresenceSettings data) {
    return {
      'available': data.available,
      'note': data.note,
      'statusIcon': data.statusIcon,
      'device': data.device,
      'timeOffsetMin': data.timeOffsetMin,
      // An instant, not the wall clock of the phone: the phone can be in
      // another zone by the time this is read back, and a wall clock with no
      // zone would then be taken for a different moment.
      'timestamp': data.timestamp.toUtc().toIso8601String(),
      'activity': switch (data.activity) {
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
      'dndMode': data.dndMode,
    };
  }

  static PresenceSettings fromMap(Map<String, dynamic> map) {
    final timeOffsetMin = map['timeOffsetMin'] as int;
    final timestamp = map['timestamp'] as String;

    return PresenceSettings(
      available: map['available'] as bool,
      note: map['note'] as String,
      statusIcon: map['statusIcon'] as String?,
      device: map['device'] as String,
      timeOffsetMin: timeOffsetMin,
      // Older builds stored the wall clock of the phone with no zone; the
      // offset stored with it is the zone it was read in. An unreadable value
      // fails as it always has, with the parser's own error.
      timestamp: parseIsoInstant(timestamp, wallClockOffsetMin: timeOffsetMin) ?? DateTime.parse(timestamp),
      activity: switch (map['activity']) {
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
        null => null,
        _ => null,
      },
      dndMode: map['dndMode'] as bool? ?? false,
    );
  }
}

mixin PresenceSettingJsonMapperMixin {
  PresenceSettings presenceSettingsFromJson(String json) => PresenceSettingsJsonMapper.fromJson(json);
  String presenceSettingsToJson(PresenceSettings data) => PresenceSettingsJsonMapper.toJson(data);
  PresenceSettings presenceSettingsFromMap(Map<String, dynamic> map) => PresenceSettingsJsonMapper.fromMap(map);
  Map<String, dynamic> presenceSettingsToMap(PresenceSettings data) => PresenceSettingsJsonMapper.toMap(data);
}
