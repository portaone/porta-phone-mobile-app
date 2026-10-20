import 'dart:async';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

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
    Timer Function(Duration, void Function())? createTimer,
    this.maxReplayAttempts = 2,
    this.maxReplayBackoff = const Duration(seconds: 30),
    this.maxUpdatingDeferrals = 10,
  }) : _onCommand = onCommand,
       _iceRestarts = DebounceMap<String>(iceRestartDelay),
       _updatingRetryDelay = updatingRetryDelay,
       _delay = delay ?? Future<void>.delayed,
       _createTimer = createTimer ?? Timer.new;

  final RenegotiationCommandHandler _onCommand;
  final DebounceMap<String> _iceRestarts;
  final Duration _updatingRetryDelay;
  final Future<void> Function(Duration) _delay;
  final Timer Function(Duration, void Function()) _createTimer;

  /// Replays sent quickly, at the delay the failure asks for, while
  /// signaling stays connected. Later ones back off.
  final int maxReplayAttempts;

  /// The longest wait between two replays once the quick ones are used up.
  final Duration maxReplayBackoff;

  /// How many times in a row renegotiation may be deferred because the call
  /// is updating before that flag is taken as stale.
  final int maxUpdatingDeferrals;

  final Map<String, RTCSessionDescription> _pendingOffers = {};

  /// Calls whose kept offer was acknowledged with an interim `updating` and
  /// still waits for its answer on the session that carried it. Such an offer
  /// is not sent again while that session lives: the answer is on its way.
  final Set<String> _awaitingAnswer = {};
  final Map<String, int> _replayAttempts = {};
  final Map<String, Timer> _replayTimers = {};
  final Map<String, int> _updatingDeferrals = {};

  void networkAvailable(String callId) {
    _iceRestarts.schedule(callId, () => _onCommand(RestartIce(callId)));
  }

  List<RenegotiationCommand> signalingConnected(Iterable<({String callId, int? lineId})> calls) {
    final commands = <RenegotiationCommand>[];
    for (final call in calls) {
      _replayTimers.remove(call.callId)?.cancel();
      // The session that would have delivered the answer is gone, so the
      // installed offer is now only recoverable by sending it again.
      _awaitingAnswer.remove(call.callId);
      // Failures on the new session are counted from the start again, so it
      // gets the quick retries before any backoff.
      _replayAttempts.remove(call.callId);
      commands.add(Renegotiate(call.callId, call.lineId));
    }
    return commands;
  }

  Future<RenegotiationCommand> retryAfterUpdating(String callId, int? lineId) async {
    _updatingDeferrals[callId] = (_updatingDeferrals[callId] ?? 0) + 1;
    await _delay(_updatingRetryDelay);
    return Renegotiate(callId, lineId);
  }

  /// Whether the call's `updating` flag has held renegotiation back for so
  /// long that it can no longer belong to an update in progress.
  ///
  /// The flag is cleared only by the reply to that update. When the reply is
  /// lost - the answer to a remote hold or transfer that never arrives, say -
  /// nothing else clears it, and every later ICE restart of the call would be
  /// deferred for the rest of the call. Each deferral waits
  /// [updatingRetryDelay], so the bound is reached after about the time an
  /// update waits for its own reply.
  bool isUpdatingStale(String callId) => (_updatingDeferrals[callId] ?? 0) >= maxUpdatingDeferrals;

  /// Records that renegotiation of the call is no longer held back by its
  /// `updating` flag, so a later update starts its own count of deferrals.
  void updatingSettled(String callId) => _updatingDeferrals.remove(callId);

  bool isTransientSignalingFailure(Object error) {
    // The signaling client throws a disconnected error when its socket closed
    // between the module handing it the request and the send: the same loss
    // of signaling as the others, only met a moment later.
    return error is NotConnectedException ||
        error is WebtritSignalingDisconnectedException ||
        error is WebtritSignalingTransactionTimeoutException ||
        error is WebtritSignalingTransactionTerminateByDisconnectException ||
        error is TimeoutException;
  }

  /// Whether a local offer of this call is kept, replayable or still waiting
  /// for its answer.
  bool hasKeptOffer(String callId) => _pendingOffers.containsKey(callId);

  /// The installed local offer that has to be sent again, or null when there
  /// is none or its answer is still expected on the current session.
  RTCSessionDescription? replayableOffer(String callId) =>
      _awaitingAnswer.contains(callId) ? null : _pendingOffers[callId];

  void keepOffer(
    String callId,
    RTCSessionDescription offer, {
    required bool signalingConnected,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    _pendingOffers[callId] = offer;
    _awaitingAnswer.remove(callId);
    if (!signalingConnected) return;

    final attempt = (_replayAttempts[callId] ?? 0) + 1;
    _replayAttempts[callId] = attempt;

    _replayTimers.remove(callId)?.cancel();
    _replayTimers[callId] = _createTimer(_replayDelay(attempt, retryDelay), () {
      _replayTimers.remove(callId);
      if (_pendingOffers.containsKey(callId)) _onCommand(Renegotiate(callId, null));
    });
  }

  /// The wait before the replay that follows the [attempt]-th failure on a
  /// connected session.
  ///
  /// Stopping after the quick replays would leave the call silent in
  /// have-local-offer until signaling happens to reconnect, with nothing
  /// left that could recover it. Ending the call instead is what recovery
  /// exists to avoid: the server still holds the call. So the replays go on
  /// while the call lives, doubling the wait up to [maxReplayBackoff]; the
  /// cost is one update request per that interval.
  Duration _replayDelay(int attempt, Duration retryDelay) {
    if (attempt <= maxReplayAttempts) return retryDelay;
    final backoff = retryDelay * (1 << min(attempt - maxReplayAttempts, 16));
    return backoff < maxReplayBackoff ? backoff : maxReplayBackoff;
  }

  /// Records that the offer was acknowledged with an interim `updating`: the
  /// answer arrives later as a separate event, and until it does the peer
  /// connection stays in have-local-offer. The offer is kept so that a
  /// signaling loss before that answer can still be recovered on reconnect.
  void awaitAnswer(String callId, RTCSessionDescription offer) {
    _pendingOffers[callId] = offer;
    _awaitingAnswer.add(callId);
    _replayAttempts.remove(callId);
    _replayTimers.remove(callId)?.cancel();
  }

  void offerCompleted(String callId) {
    _pendingOffers.remove(callId);
    _awaitingAnswer.remove(callId);
    _replayAttempts.remove(callId);
    _replayTimers.remove(callId)?.cancel();
  }

  void callRemoved(String callId) {
    _iceRestarts.cancel(callId);
    _updatingDeferrals.remove(callId);
    offerCompleted(callId);
  }

  void dispose() {
    _iceRestarts.dispose();
    for (final timer in _replayTimers.values) {
      timer.cancel();
    }
    _replayTimers.clear();
    _pendingOffers.clear();
    _awaitingAnswer.clear();
    _replayAttempts.clear();
    _updatingDeferrals.clear();
  }
}
