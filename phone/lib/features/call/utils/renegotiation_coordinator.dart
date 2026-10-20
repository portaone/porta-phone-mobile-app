import 'dart:async';

import 'package:webtrit_phone/utils/utils.dart';

sealed class RenegotiationCommand {
  const RenegotiationCommand(this.callId);

  final String callId;
}

class RestartIce extends RenegotiationCommand {
  const RestartIce(super.callId);
}

class Renegotiate extends RenegotiationCommand {
  const Renegotiate(super.callId, this.lineId);

  final int? lineId;
}

typedef RenegotiationCommandHandler = void Function(RenegotiationCommand command);

/// Owns the timing and session-bound triggers for per-call renegotiation.
///
/// The bloc supplies facts about connectivity, signaling and call removal,
/// then translates the returned commands into its private events. Keeping the
/// timers and error classification here prevents recovery state from being
/// spread across unrelated bloc handlers.
class RenegotiationCoordinator {
  RenegotiationCoordinator({
    required RenegotiationCommandHandler onCommand,
    Duration iceRestartDelay = const Duration(seconds: 2),
    Duration updatingRetryDelay = const Duration(seconds: 1),
    Future<void> Function(Duration)? delay,
  }) : _onCommand = onCommand,
       _iceRestarts = DebounceMap<String>(iceRestartDelay),
       _updatingRetryDelay = updatingRetryDelay,
       _delay = delay ?? Future<void>.delayed;

  final RenegotiationCommandHandler _onCommand;
  final DebounceMap<String> _iceRestarts;
  final Duration _updatingRetryDelay;
  final Future<void> Function(Duration) _delay;

  void networkAvailable(String callId) {
    _iceRestarts.schedule(callId, () => _onCommand(RestartIce(callId)));
  }

  List<RenegotiationCommand> signalingConnected(Iterable<({String callId, int? lineId})> calls) {
    return [for (final call in calls) Renegotiate(call.callId, call.lineId)];
  }

  Future<RenegotiationCommand> retryAfterUpdating(String callId, int? lineId) async {
    await _delay(_updatingRetryDelay);
    return Renegotiate(callId, lineId);
  }

  void callRemoved(String callId) => _iceRestarts.cancel(callId);

  void dispose() => _iceRestarts.dispose();
}
