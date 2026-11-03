import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/mappers/json/audio_processing_settings_mapper.dart';
import 'package:webtrit_phone/models/audio_processing_settings.dart';

class _Mapper with AudioProcessingSettingsJsonMapper {}

void main() {
  final mapper = _Mapper();

  group('voice noise reduction', () {
    test('is kept through a save and a load', () {
      const settings = AudioProcessingSettings(noiseSuppression: false, voiceNoiseReduction: true);

      final loaded = mapper.audioProcessingSettingsFromJson(mapper.audioProcessingSettingsToJson(settings));

      expect(loaded.voiceNoiseReduction, isTrue);
      expect(loaded, settings);
    });

    test('is off for settings saved before it existed', () {
      final loaded = mapper.audioProcessingSettingsFromJson('{"noiseSuppression":true}');

      expect(loaded.voiceNoiseReduction, isNull);
      expect(loaded.noiseSuppression, isTrue);
    });

    test('is kept by every other copyWith', () {
      const settings = AudioProcessingSettings(voiceNoiseReduction: true);

      expect(settings.copyWithBypassVoiceProcessing(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithEchoCancellation(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithAutoGainControl(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithNoiseSuppression(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithHighpassFilter(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithAudioMirroring(true).voiceNoiseReduction, isTrue);
      expect(settings.copyWithVoiceNoiseReduction(null).voiceNoiseReduction, isNull);
    });
  });
}
