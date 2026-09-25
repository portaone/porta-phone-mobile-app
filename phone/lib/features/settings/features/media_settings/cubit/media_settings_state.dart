import 'package:equatable/equatable.dart';
import 'package:webtrit_phone/models/models.dart';

// TODO(Serdun): Maybe better to use Freezed for avoid a lot of copyWith methods.
class MediaSettingsState with EquatableMixin {
  MediaSettingsState({
    required this.encodingSettings,
    required this.encodingPreset,
    required this.audioProcessingSettings,
    required this.videoCapturingSettings,
    required this.iceSettings,
    required this.pearConnectionSettings,
    this.certificateVerificationConfigurable = false,
  });

  final EncodingSettings encodingSettings;
  final EncodingPreset? encodingPreset;
  final AudioProcessingSettings audioProcessingSettings;
  final VideoCapturingSettings videoCapturingSettings;

  // TODO: Move [iceSettings] to [PeerConnectionSettings] since it relates to WebRTC session-level configuration,
  // such as ICE servers, transport policy, and connection establishment behavior.
  final IceSettings iceSettings;
  final PeerConnectionSettings pearConnectionSettings;

  /// Whether this deployment offers the certificate policy control at all.
  /// Fixed for the life of the screen - it comes from the build, not from
  /// anything the person can change here.
  final bool certificateVerificationConfigurable;

  MediaSettingsState copyWithEncodingPresets(EncodingPreset? preset) {
    return MediaSettingsState(
      encodingSettings: encodingSettings,
      encodingPreset: preset,
      audioProcessingSettings: audioProcessingSettings,
      videoCapturingSettings: videoCapturingSettings,
      iceSettings: iceSettings,
      pearConnectionSettings: pearConnectionSettings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  MediaSettingsState copyWithEncodingSettings(EncodingSettings settings) {
    return MediaSettingsState(
      encodingSettings: settings,
      encodingPreset: encodingPreset,
      audioProcessingSettings: audioProcessingSettings,
      videoCapturingSettings: videoCapturingSettings,
      iceSettings: iceSettings,
      pearConnectionSettings: pearConnectionSettings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  MediaSettingsState copyWithAudioProcessingSettings(AudioProcessingSettings settings) {
    return MediaSettingsState(
      encodingSettings: encodingSettings,
      encodingPreset: encodingPreset,
      audioProcessingSettings: settings,
      videoCapturingSettings: videoCapturingSettings,
      iceSettings: iceSettings,
      pearConnectionSettings: pearConnectionSettings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  MediaSettingsState copyWithVideoCapturingSettings(VideoCapturingSettings settings) {
    return MediaSettingsState(
      encodingSettings: encodingSettings,
      encodingPreset: encodingPreset,
      audioProcessingSettings: audioProcessingSettings,
      videoCapturingSettings: settings,
      iceSettings: iceSettings,
      pearConnectionSettings: pearConnectionSettings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  MediaSettingsState copyWithIceSettings(IceSettings settings) {
    return MediaSettingsState(
      encodingSettings: encodingSettings,
      encodingPreset: encodingPreset,
      audioProcessingSettings: audioProcessingSettings,
      videoCapturingSettings: videoCapturingSettings,
      iceSettings: settings,
      pearConnectionSettings: pearConnectionSettings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  MediaSettingsState copyWithPeerConnectionSettings(PeerConnectionSettings settings) {
    return MediaSettingsState(
      encodingSettings: encodingSettings,
      encodingPreset: encodingPreset,
      audioProcessingSettings: audioProcessingSettings,
      videoCapturingSettings: videoCapturingSettings,
      iceSettings: iceSettings,
      pearConnectionSettings: settings,
      certificateVerificationConfigurable: certificateVerificationConfigurable,
    );
  }

  @override
  List<Object?> get props => [
    encodingSettings,
    encodingPreset,
    audioProcessingSettings,
    videoCapturingSettings,
    iceSettings,
    pearConnectionSettings,
    certificateVerificationConfigurable,
  ];

  @override
  String toString() {
    return 'MediaSettingsState - '
        'encodingPreset: $encodingPreset,'
        'encodingSettings: $encodingSettings},'
        'audioProcessingSettings: $audioProcessingSettings,'
        'videoCapturingSettings: $videoCapturingSettings,'
        'iceSettings: $iceSettings,'
        'pearConnectionSettings: $pearConnectionSettings';
  }
}
