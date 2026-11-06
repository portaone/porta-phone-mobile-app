import 'package:equatable/equatable.dart';

class AudioProcessingSettings extends Equatable {
  const AudioProcessingSettings({
    this.bypassVoiceProcessing,
    this.echoCancellation,
    this.autoGainControl,
    this.noiseSuppression,
    this.highpassFilter,
    this.audioMirroring,
    this.voiceNoiseReduction,
  });

  final bool? bypassVoiceProcessing;
  final bool? echoCancellation;
  final bool? autoGainControl;
  final bool? noiseSuppression;
  final bool? highpassFilter;
  final bool? audioMirroring;

  /// RNNoise on the outgoing voice, after the platform's own processing. Null and false both
  /// mean off: unlike the fields above it has no platform default to fall back to.
  final bool? voiceNoiseReduction;

  @override
  List<Object?> get props => [
    bypassVoiceProcessing,
    echoCancellation,
    autoGainControl,
    noiseSuppression,
    highpassFilter,
    audioMirroring,
    voiceNoiseReduction,
  ];

  @override
  String toString() {
    return 'AudioProcessingSettings{bypassVoiceProcessing: $bypassVoiceProcessing, echoCancellation: $echoCancellation, autoGainControl: $autoGainControl, noiseSuppression: $noiseSuppression, highpassFilter: $highpassFilter, audioMirroring: $audioMirroring, voiceNoiseReduction: $voiceNoiseReduction}';
  }

  factory AudioProcessingSettings.blank() => const AudioProcessingSettings();

  AudioProcessingSettings copyWithBypassVoiceProcessing(bool? bypassVoiceProcessing) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithEchoCancellation(bool? echoCancellation) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithAutoGainControl(bool? autoGainControl) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithNoiseSuppression(bool? noiseSuppression) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithHighpassFilter(bool? highpassFilter) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithAudioMirroring(bool? audioMirroring) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }

  AudioProcessingSettings copyWithVoiceNoiseReduction(bool? voiceNoiseReduction) {
    return AudioProcessingSettings(
      bypassVoiceProcessing: bypassVoiceProcessing,
      echoCancellation: echoCancellation,
      autoGainControl: autoGainControl,
      noiseSuppression: noiseSuppression,
      highpassFilter: highpassFilter,
      audioMirroring: audioMirroring,
      voiceNoiseReduction: voiceNoiseReduction,
    );
  }
}
