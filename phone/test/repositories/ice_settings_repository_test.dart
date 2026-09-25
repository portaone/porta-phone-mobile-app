import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/models/ice_settings.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAppPreferences extends Mock implements AppPreferences {}

void main() {
  late _MockAppPreferences preferences;
  late IceSettingsRepository repository;

  setUp(() {
    preferences = _MockAppPreferences();
    repository = IceSettingsRepositoryPrefsImpl(preferences);
    when(() => preferences.setString(any(), any())).thenAnswer((_) async {});
  });

  void stored(String? json) => when(() => preferences.getString('ice-settings')).thenReturn(json);

  group('certificate verification', () {
    test('follows the deployment default when this device has made no choice', () {
      stored(null);

      expect(
        repository.resolveCertificateVerification(TurnCertificateVerification.disabled),
        TurnCertificateVerification.disabled,
      );
    });

    test('follows the deployment default when only the filters were ever set', () {
      // The distinction that matters: a device that touched the ICE filters has
      // a stored blob, and must still track a later change of the brand default.
      stored('{"iceTransportFilter":"udp","iceNetworkFilter":null}');

      expect(
        repository.resolveCertificateVerification(TurnCertificateVerification.enabled),
        TurnCertificateVerification.enabled,
      );
    });

    test('a choice made on the device wins over the deployment default', () {
      stored('{"certificateVerification":"disabled"}');

      expect(
        repository.resolveCertificateVerification(TurnCertificateVerification.auto),
        TurnCertificateVerification.disabled,
      );
    });

    test('an unknown stored value reads as no choice rather than throwing', () {
      stored('{"certificateVerification":"whatever-a-newer-build-wrote"}');

      expect(
        repository.resolveCertificateVerification(TurnCertificateVerification.enabled),
        TurnCertificateVerification.enabled,
      );
    });

    test('round-trips through the stored representation', () {
      stored(null);
      repository.setIceSettings(
        IceSettings.blank().copyWithCertificateVerification(TurnCertificateVerification.enabled),
      );

      final captured = verify(() => preferences.setString('ice-settings', captureAny())).captured.single as String;
      expect(captured, contains('"certificateVerification":"enabled"'));
    });
  });
}
