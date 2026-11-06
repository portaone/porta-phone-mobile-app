import 'package:test/test.dart';

import 'package:theme_schema/theme_schema.dart';

void main() {
  group('AppConfigCallAudio.voiceNoiseReduction', () {
    test('is off when the theme says nothing', () {
      expect(AppConfigCallAudio.fromJson(const {}).voiceNoiseReduction, isFalse);
    });

    test('is read from the theme', () {
      expect(AppConfigCallAudio.fromJson(const {'voiceNoiseReduction': true}).voiceNoiseReduction, isTrue);
    });

    test('round-trips through json', () {
      const audio = AppConfigCallAudio(voiceNoiseReduction: true);

      expect(AppConfigCallAudio.fromJson(audio.toJson()), audio);
    });
  });
}
