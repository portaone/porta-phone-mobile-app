import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/settings/features/media_settings/media_settings.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAudioProcessing extends Mock implements AudioProcessingSettingsRepository {}

class _MockEncodingPreset extends Mock implements EncodingPresetRepository {}

class _MockIceSettings extends Mock implements IceSettingsRepository {}

class _MockPeerConnection extends Mock implements PeerConnectionSettingsRepository {}

class _MockVideoCapturing extends Mock implements VideoCapturingSettingsRepository {}

class _MockEncodingSettings extends Mock implements EncodingSettingsRepository {}

void main() {
  late _MockIceSettings iceSettings;
  late _MockPeerConnection peerConnection;

  setUpAll(() {
    registerFallbackValue(IceSettings.blank());
    registerFallbackValue(EncodingSettings.blank());
    registerFallbackValue(AudioProcessingSettings.blank());
    registerFallbackValue(VideoCapturingSettings.blank());
    registerFallbackValue(PeerConnectionSettings.blank());
    registerFallbackValue(TurnCertificateVerification.verify);
  });

  MediaSettingsCubit build(IceConfig iceConfig, {IceSettings? stored}) {
    iceSettings = _MockIceSettings();
    peerConnection = _MockPeerConnection();
    final audio = _MockAudioProcessing();
    final preset = _MockEncodingPreset();
    final video = _MockVideoCapturing();
    final encoding = _MockEncodingSettings();

    when(() => iceSettings.getIceSettings()).thenReturn(stored ?? IceSettings.blank());
    when(() => iceSettings.resolveCertificateVerification(any())).thenAnswer(
      (invocation) =>
          (stored ?? IceSettings.blank()).certificateVerification ??
          invocation.positionalArguments.first as TurnCertificateVerification,
    );
    when(() => iceSettings.setIceSettings(any())).thenAnswer((_) async {});
    when(() => peerConnection.getPeerConnectionSettings(defaultValue: any(named: 'defaultValue')))
        .thenReturn(PeerConnectionSettings.blank());
    when(() => peerConnection.setPearConnectionSettings(any())).thenAnswer((_) async {});
    when(() => audio.getAudioProcessingSettings()).thenReturn(AudioProcessingSettings.blank());
    when(() => audio.setAudioProcessingSettings(any())).thenAnswer((_) async {});
    when(() => preset.getEncodingPreset()).thenReturn(null);
    when(() => preset.setEncodingPreset(any())).thenAnswer((_) async {});
    when(() => video.getVideoCapturingSettings()).thenReturn(VideoCapturingSettings.blank());
    when(() => video.setVideoCapturingSettings(any())).thenAnswer((_) async {});
    when(() => encoding.getEncodingSettings()).thenReturn(EncodingSettings.blank());
    when(() => encoding.setEncodingSettings(any())).thenAnswer((_) async {});

    return MediaSettingsCubit(
      PeerConnectionSettings.blank(),
      iceConfig,
      audio,
      preset,
      iceSettings,
      peerConnection,
      video,
      encoding,
    );
  }

  const configurable = IceConfig(certificateVerificationConfigurable: true);

  group('certificate verification', () {
    test('shows the value the deployment was built with when the device has chosen none', () {
      final cubit = build(
        const IceConfig(
          certificateVerification: TurnCertificateVerification.disabled,
          certificateVerificationConfigurable: true,
        ),
      );

      expect(cubit.state.iceSettings.certificateVerification, TurnCertificateVerification.disabled);
    });

    test('reset keeps the section visible', () {
      // The flag describes the build, not the settings, so resetting the
      // settings must not take the section away with them - which is exactly
      // what a defaulted field let happen once.
      final cubit = build(configurable);

      cubit.reset();

      expect(cubit.state.certificateVerificationConfigurable, isTrue);
    });

    test('reset returns to the deployment default rather than to no choice', () {
      final cubit = build(
        const IceConfig(
          certificateVerification: TurnCertificateVerification.disabled,
          certificateVerificationConfigurable: true,
        ),
        stored: IceSettings.blank().copyWithCertificateVerification(TurnCertificateVerification.verify),
      );

      cubit.reset();

      expect(cubit.state.iceSettings.certificateVerification, TurnCertificateVerification.disabled);
      // What is stored goes back to "no choice", so a later change of the
      // brand default still reaches this device.
      final written = verify(() => iceSettings.setIceSettings(captureAny())).captured.last as IceSettings;
      expect(written.certificateVerification, isNull);
    });

    test('a choice made here is written and shown', () {
      final cubit = build(configurable);

      cubit.setCertificateVerification(TurnCertificateVerification.disabled);

      expect(cubit.state.iceSettings.certificateVerification, TurnCertificateVerification.disabled);
      final written = verify(() => iceSettings.setIceSettings(captureAny())).captured.last as IceSettings;
      expect(written.certificateVerification, TurnCertificateVerification.disabled);
    });
  });
}
