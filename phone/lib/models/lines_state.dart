import 'package:equatable/equatable.dart';

sealed class LineState extends Equatable {
  const LineState();

  @override
  List<Object?> get props => [];

  factory LineState.idle() => const IdleLineState();
  factory LineState.inUse({required String callId, required bool ringingOnly}) =>
      InUseLineState(callId: callId, ringingOnly: ringingOnly);
}

final class IdleLineState extends LineState {
  const IdleLineState();

  @override
  String toString() => 'IdleLineState';
}

final class InUseLineState extends LineState {
  const InUseLineState({required this.callId, required this.ringingOnly});
  final String callId;

  /// Whether the call has only rung on this device so far: incoming, and no
  /// answer started here. Such a call holds the line too, while another device
  /// of the account may answer it under the same call id.
  final bool ringingOnly;

  @override
  List<Object?> get props => [callId, ringingOnly];

  @override
  String toString() => 'InUseLineState{callId: $callId, ringingOnly: $ringingOnly}';
}

class LinesState extends Equatable {
  const LinesState({required this.mainLines, required this.guestLine});

  final List<LineState> mainLines;
  final LineState? guestLine;

  factory LinesState.blank() => const LinesState(mainLines: [], guestLine: null);

  /// True when this state has no main lines and no guest line.
  ///
  /// This occurs in two situations:
  /// - Pre-handshake: [CallBloc.onChange] sets [LinesState.blank] while
  ///   [CallState.linesCount] is 0 and [CallState.isHandshakeEstablished] is false.
  /// - Post-handshake with no lines: a valid server state where both main lines
  ///   and guest line are absent (treated the same as blank by [CallRoutingCubit]).
  bool get isBlank => mainLines.isEmpty && guestLine == null;

  @override
  List<Object?> get props => [mainLines, guestLine];

  @override
  String toString() {
    return 'LinesState{mainLines: $mainLines, guestLine: $guestLine}';
  }
}
