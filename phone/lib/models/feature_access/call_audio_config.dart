import 'package:equatable/equatable.dart';

/// What the deployment decided about a call's audio output at build time, and
/// whether it lets the person using the app change that decision.
class CallAudioConfig extends Equatable {
  const CallAudioConfig({this.speakerOnMinimize = true, this.speakerOnMinimizeConfigurable = false});

  /// Whether an audio call moves to the loudspeaker when its screen is left.
  /// The value a device uses until someone changes it there.
  final bool speakerOnMinimize;

  /// Whether the media settings screen shows the control at all.
  final bool speakerOnMinimizeConfigurable;

  @override
  List<Object?> get props => [speakerOnMinimize, speakerOnMinimizeConfigurable];
}
