import 'package:equatable/equatable.dart';

/// What one call's own connection is to carry, in each direction.
///
/// Who is heard is a property of the connections, never of the microphone: the
/// app captures one track and hands the same one to every call and to the
/// conference room, so disabling it would silence all of them at once. Taking
/// it off one sender stops only what that connection sends.
class CallAudio extends Equatable {
  const CallAudio({required this.microphone, required this.audible});

  /// Nothing either way: the connection neither sends nor plays.
  const CallAudio.silent() : microphone = false, audible = false;

  /// Whether the pooled microphone track sits on this connection's sender.
  final bool microphone;

  /// Whether the far end's audio plays.
  final bool audible;

  @override
  List<Object?> get props => [microphone, audible];

  @override
  String toString() => 'CallAudio(microphone: $microphone, audible: $audible)';
}
