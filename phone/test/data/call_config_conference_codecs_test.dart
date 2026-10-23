import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

import '../helpers/feature_access_factories.dart';

/// The conference mixer's codecs as the build names them.
EncodingConfig _encodingFor(List<String>? names) {
  final appConfig = createMockAppConfig();
  final encoding = appConfig.callConfig.encoding;
  when(() => encoding.conferenceAudioCodecs).thenReturn(names);
  return CallMapper.map(appConfig, const FeatureOverrides(), null).encoding;
}

void main() {
  group('conference codecs from the build', () {
    test('are opus, PCMA and PCMU when the build names none', () {
      expect(_encodingFor(null).conferenceAudioCodecs, {RTPCodec.opus, RTPCodec.pcma, RTPCodec.pcmu});
    });

    test('are the ones the build names, case aside', () {
      expect(_encodingFor(['PCMU', 'g722']).conferenceAudioCodecs, {RTPCodec.pcmu, RTPCodec.g722});
    });

    test('leave out a name this build does not know and one that carries no voice', () {
      expect(_encodingFor(['amr', 'telephone-event', 'CN', 'red', 'pcma']).conferenceAudioCodecs, {RTPCodec.pcma});
    });

    test('are the default when nothing named is a voice codec', () {
      expect(
        _encodingFor(['amr', 'telephone-event']).conferenceAudioCodecs,
        EncodingConfig.defaultConferenceAudioCodecs,
      );
      expect(_encodingFor(const []).conferenceAudioCodecs, EncodingConfig.defaultConferenceAudioCodecs);
    });
  });

  group('the list a person orders them from', () {
    EncodingConfig config(Set<RTPCodec> codecs) => EncodingConfig(
      bypassConfig: false,
      configurationAllowed: true,
      defaultPresetOverride: const DefaultPresetOverride(
        audioBitrate: null,
        videoBitrate: null,
        ptime: null,
        maxptime: null,
        opusSamplingRate: null,
        opusBitrate: null,
        opusStereo: null,
        opusDtx: null,
        removeStaticAudioRtpMaps: null,
        remapTE8payloadTo101: null,
      ),
      conferenceAudioCodecs: codecs,
    );

    test('is the default order of the mixer\'s codecs', () {
      final profiles = config(EncodingConfig.defaultConferenceAudioCodecs).conferenceAudioProfilesToChoose;

      expect(profiles.map((p) => p.option), [RTPCodecProfile.opus, RTPCodecProfile.pcmu, RTPCodecProfile.pcma]);
      expect(profiles.every((p) => p.enabled), isTrue);
    });

    test('holds only what the mixer speaks, and a codec the default does not name after the rest', () {
      final profiles = config({RTPCodec.g722, RTPCodec.pcma}).conferenceAudioProfilesToChoose;

      expect(profiles.map((p) => p.option), [RTPCodecProfile.pcma, RTPCodecProfile.g722]);
    });
  });
}
