import '../models/call_audio_device.dart';

/// Moves an audio call to the loudspeaker while its screen is away, and back
/// when the screen returns.
///
/// The one place that decides it. Leaving the call screen is where a person
/// stops holding the phone to the ear, so a call on the earpiece is the only
/// one moved: a headset, or a speaker the person turned on, already suits a
/// phone held in the hand, and a video call is on the speaker anyway.
///
/// It answers with the device to switch to and leaves the switching to the
/// caller, so the rule can be read and tested without a platform.
class SpeakerOnMinimize {
  SpeakerOnMinimize({required bool Function() isEnabled}) : _isEnabled = isEnabled;

  /// Asked every time the screen is left: the value can change during a call.
  final bool Function() _isEnabled;

  /// The earpiece a call was taken off, kept until its screen returns.
  ({String callId, CallAudioDevice device})? _movedFrom;

  /// The device to switch [callId] to now that its screen was left, or null to
  /// leave the audio where it is.
  CallAudioDevice? onCallScreenLeft({
    required String callId,
    required bool video,
    required CallAudioDevice? current,
    required List<CallAudioDevice> available,
  }) {
    _movedFrom = null;
    if (!_isEnabled() || video) return null;

    final speaker = available.getSpeaker;
    // A device not reported yet is taken for the earpiece the platform starts an audio call on.
    final earpiece = current ?? available.getEarpiece;
    if (speaker == null || earpiece == null || earpiece.type != CallAudioDeviceType.earpiece) return null;

    _movedFrom = (callId: callId, device: earpiece);
    return speaker;
  }

  /// The device to switch [callId] back to now that its screen returned, or
  /// null when this class did not move it or the person has chosen another
  /// device since.
  CallAudioDevice? onCallScreenReturned({required String callId, required CallAudioDevice? current}) {
    final movedFrom = _movedFrom;
    _movedFrom = null;
    if (movedFrom == null || movedFrom.callId != callId) return null;

    final type = current?.type;
    final stillWhereItWasPut = type == null || type == CallAudioDeviceType.speaker || type == movedFrom.device.type;
    return stillWhereItWasPut ? movedFrom.device : null;
  }
}
