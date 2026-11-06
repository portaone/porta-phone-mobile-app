import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import 'package:flutter_webrtc_noise_suppression/flutter_webrtc_noise_suppression.dart';

import 'user_media_builder.dart';

final _logger = Logger('VoiceNoiseReduction');

/// Turns RNNoise on the outgoing voice on while the microphone is open, when the user chose it.
///
/// The work is native, in the flutter_webrtc_noise_suppression plugin (github.com/portaone/porta-flutter-plugins):
/// it puts the noise_suppression plugin's suppressor into flutter_webrtc's capture
/// post-processing slot, after the platform's own echo cancellation and noise suppression. This
/// class only says when.
///
/// The choice is read each time the microphone is opened, so a change in the settings applies
/// from the next call on, not to the call in progress.
class VoiceNoiseReduction implements AudioTrackLifecycle {
  VoiceNoiseReduction({
    required this.isEnabled,
    WebrtcNoiseSuppressionBridge bridge = const WebrtcNoiseSuppressionBridge(),
  }) : _bridge = bridge;

  /// Whether the reduction is on: the user's choice, or the deployment's where there is none.
  final bool Function() isEnabled;

  final WebrtcNoiseSuppressionBridge _bridge;

  bool _attached = false;

  final ValueNotifier<bool> _failed = ValueNotifier(false);

  /// True while the microphone is open and the reduction was asked for but did not start, so the
  /// voice goes out with the platform processing alone. Of the microphone, not of a call: every
  /// call shares it.
  ValueListenable<bool> get failed => _failed;

  /// Whether the platform has the native side: Android and iOS only.
  static bool get isSupported => WebrtcNoiseSuppressionBridge.isSupported;

  @override
  Future<void> onAudioTrackAcquired() async {
    if (!isEnabled()) {
      _failed.value = false;
      return;
    }
    try {
      _attached = await _bridge.attach();
      if (!_attached) _logger.warning('not attached; the call keeps the platform processing only');
    } catch (e, s) {
      // A missing plugin (an engine without it) or a native failure must not stop the call: it
      // goes on with the platform processing, as without the setting.
      _attached = false;
      _logger.warning('attach failed', e, s);
    }
    _failed.value = !_attached;
  }

  @override
  Future<void> onAudioTrackReleased() async {
    _failed.value = false;
    if (!_attached) return;
    _attached = false;
    try {
      await _bridge.detach();
    } catch (e, s) {
      _logger.warning('detach failed', e, s);
    }
  }
}
