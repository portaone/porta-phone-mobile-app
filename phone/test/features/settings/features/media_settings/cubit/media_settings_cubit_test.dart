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

/// The device's choice kept in memory, resolved by the same rule as the real one.
class _CallAudioSettings implements CallAudioSettingsRepository {
  _CallAudioSettings(this.stored);

  bool? stored;

  @override
  bool? getSpeakerOnMinimize() => stored;

  @override
  bool resolveSpeakerOnMinimize(CallAudioConfig config) =>
      config.speakerOnMinimizeConfigurable ? stored ?? config.speakerOnMinimize : config.speakerOnMinimize;

  @override
  Future<void> setSpeakerOnMinimize(bool? value) async => stored = value;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late _MockIceSettings iceSettings;
  late _MockPeerConnection peerConnection;
  late _CallAudioSettings callAudio;

  setUpAll(() {
    registerFallbackValue(IceSettings.blank());
    registerFallbackValue(EncodingSettings.blank());
    registerFallbackValue(AudioProcessingSettings.blank());
    registerFallbackValue(VideoCapturingSettings.blank());
    registerFallbackValue(PeerConnectionSettings.blank());
    registerFallbackValue(TurnCertificateVerification.verify);
  });

  MediaSettingsCubit build(
    IceConfig iceConfig, {
    IceSettings? stored,
    CallAudioConfig audioConfig = const CallAudioConfig(),
    bool? storedSpeakerOnMinimize,
  }) {
    callAudio = _CallAudioSettings(storedSpeakerOnMinimize);
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
      audioConfig: audioConfig,
      callAudioSettingsRepository: callAudio,
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

  group('speaker when the call screen is left', () {
    const offered = CallAudioConfig(speakerOnMinimize: true, speakerOnMinimizeConfigurable: true);

    test('shows the value the deployment was built with when the device has chosen none', () {
      expect(build(const IceConfig(), audioConfig: offered).state.speakerOnMinimize, isTrue);
      expect(
        build(
          const IceConfig(),
          audioConfig: const CallAudioConfig(speakerOnMinimize: false, speakerOnMinimizeConfigurable: true),
        ).state.speakerOnMinimize,
        isFalse,
      );
    });

    test('shows the choice made on this device over the deployment value', () {
      final cubit = build(const IceConfig(), audioConfig: offered, storedSpeakerOnMinimize: false);

      expect(cubit.state.speakerOnMinimize, isFalse);
      expect(cubit.state.speakerOnMinimizeConfigurable, isTrue);
    });

    test('ignores a stored choice where the deployment does not offer the control', () {
      final cubit = build(
        const IceConfig(),
        audioConfig: const CallAudioConfig(speakerOnMinimize: true),
        storedSpeakerOnMinimize: false,
      );

      expect(cubit.state.speakerOnMinimize, isTrue);
      expect(cubit.state.speakerOnMinimizeConfigurable, isFalse);
    });

    test('a choice made here is written and shown, and survives another setting changing', () {
      final cubit = build(const IceConfig(), audioConfig: offered);

      cubit.setSpeakerOnMinimize(false);
      cubit.setEncodingPreset(null);

      expect(cubit.state.speakerOnMinimize, isFalse);
      expect(cubit.state.speakerOnMinimizeConfigurable, isTrue);
      expect(callAudio.stored, isFalse);
    });

    test('reset returns to the deployment value and stores no choice', () {
      final cubit = build(const IceConfig(), audioConfig: offered, storedSpeakerOnMinimize: false);

      cubit.reset();

      expect(cubit.state.speakerOnMinimize, isTrue);
      expect(callAudio.stored, isNull);
    });
  });
}
