import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAppPreferences extends Mock implements AppPreferences {}

void main() {
  const key = 'call-audio-speaker-on-minimize';
  late _MockAppPreferences prefs;
  late CallAudioSettingsRepository repository;

  setUp(() {
    prefs = _MockAppPreferences();
    repository = CallAudioSettingsRepositoryPrefsImpl(prefs);
    when(() => prefs.setBool(any(), any())).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
  });

  void stored(bool? value) => when(() => prefs.getBool(key)).thenReturn(value);

  group('resolveSpeakerOnMinimize', () {
    for (final built in [true, false]) {
      test('follows the deployment ($built) when the device has chosen nothing', () {
        stored(null);
        expect(
          repository.resolveSpeakerOnMinimize(
            CallAudioConfig(speakerOnMinimize: built, speakerOnMinimizeConfigurable: true),
          ),
          built,
        );
      });

      test('the device choice wins over the deployment ($built) where the control is offered', () {
        stored(!built);
        expect(
          repository.resolveSpeakerOnMinimize(
            CallAudioConfig(speakerOnMinimize: built, speakerOnMinimizeConfigurable: true),
          ),
          !built,
        );
      });

      test('a stored choice is ignored where the deployment ($built) does not offer the control', () {
        stored(!built);
        expect(repository.resolveSpeakerOnMinimize(CallAudioConfig(speakerOnMinimize: built)), built);
      });
    }
  });

  test('a choice is written under its key', () async {
    await repository.setSpeakerOnMinimize(false);
    verify(() => prefs.setBool(key, false)).called(1);
  });

  test('null and clear both remove the choice', () async {
    await repository.setSpeakerOnMinimize(null);
    await repository.clear();
    verify(() => prefs.remove(key)).called(2);
    verifyNever(() => prefs.setBool(any(), any()));
  });
}
