import 'dart:convert';

import 'package:webtrit_phone/models/ice_settings.dart';

mixin IceSettingsJsonMapper {
  IceSettings iceSettingsFromJson(String json) {
    return iceSettingsFromMap(jsonDecode(json));
  }

  String iceSettingsToJson(IceSettings settings) {
    return jsonEncode(iceSettingsToMap(settings));
  }

  IceSettings iceSettingsFromMap(Map<String, dynamic> map) {
    return IceSettings(
      iceTransportFilter: map['iceTransportFilter'] != null
          ? IceTransportFilter.values.byName(map['iceTransportFilter'])
          : null,
      iceNetworkFilter: map['iceNetworkFilter'] != null
          ? IceNetworkFilter.values.byName(map['iceNetworkFilter'])
          : null,
      // `tryParse` rather than `byName`: a value written by a newer build, or
      // one dropped from the enum, must read as "no choice on this device"
      // instead of throwing on every settings read.
      certificateVerification: TurnCertificateVerification.tryParse(map['certificateVerification'] as String?),
    );
  }

  Map<String, dynamic> iceSettingsToMap(IceSettings settings) {
    return {
      'iceTransportFilter': settings.iceTransportFilter?.name,
      'iceNetworkFilter': settings.iceNetworkFilter?.name,
      'certificateVerification': settings.certificateVerification?.name,
    };
  }
}
