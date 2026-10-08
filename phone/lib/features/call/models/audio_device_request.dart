import 'call_audio_device.dart';

/// An audio device the person asked for that the platform has not confirmed yet.
///
/// The call screen shows [device] instead of the route in use until the platform
/// has finished the request and reported the route once more, so a route read
/// while the audio is still being moved does not put the old device back.
class AudioDeviceRequest {
  const AudioDeviceRequest(this.device, {this.applied = false});

  final CallAudioDevice device;

  /// The platform's part of the request is over, whether it moved the audio or
  /// not: the next route report takes the request's place.
  final bool applied;

  AudioDeviceRequest asApplied() => AudioDeviceRequest(device, applied: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioDeviceRequest && device == other.device && applied == other.applied;

  @override
  int get hashCode => Object.hash(device, applied);

  @override
  String toString() => 'AudioDeviceRequest(device: $device, applied: $applied)';
}
