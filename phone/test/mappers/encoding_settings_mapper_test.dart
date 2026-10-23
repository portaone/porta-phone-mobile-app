import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/mappers/json/encoding_settings_mapper.dart';
import 'package:webtrit_phone/models/encoding_settings.dart';
import 'package:webtrit_phone/models/rtp_codec_profile.dart';

class _Mapper with EncodingSettingsJsonMapper {}

void main() {
  final mapper = _Mapper();

  group('conference audio profiles', () {
    test('are kept through a save and a load, order and switches included', () {
      final settings = EncodingSettings(
        conferenceAudioProfiles: [
          (option: RTPCodecProfile.pcma, enabled: true),
          (option: RTPCodecProfile.opus, enabled: false),
        ],
      );

      final loaded = mapper.encodingSettingsFromJson(mapper.encodingSettingsToJson(settings));

      expect(loaded.conferenceAudioProfiles, settings.conferenceAudioProfiles);
      expect(loaded, settings);
    });

    test('are unset in settings saved before they existed', () {
      final loaded = mapper.encodingSettingsFromJson('{"audioProfiles":[{"profile":"opus","enabled":true}]}');

      expect(loaded.conferenceAudioProfiles, isNull);
      expect(loaded.audioProfiles, [(option: RTPCodecProfile.opus, enabled: true)]);
    });

    test('leave out a profile this build does not know', () {
      final loaded = mapper.encodingSettingsFromJson(
        '{"conferenceAudioProfiles":[{"profile":"amr","enabled":true},{"profile":"pcmu","enabled":true}]}',
      );

      expect(loaded.conferenceAudioProfiles, [(option: RTPCodecProfile.pcmu, enabled: true)]);
    });
  });
}
