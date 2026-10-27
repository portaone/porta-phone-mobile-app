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

/// A fresh local offer for a pulled call whose negotiations have settled.
///
/// [attempt] identifies the arming that produced the command: a later arming,
/// a hold or the call's removal makes it stale before it is acted on.
class ResumePulledCall extends RenegotiationCommand {
  const ResumePulledCall(super.callId, this.attempt);

  final Object attempt;
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
    Timer Function(Duration, void Function())? createPullResumeTimer,
    this.pullResumeSettle = const Duration(milliseconds: 1500),
    this.maxPullResumes = 3,
    this.pullResumeWindow = const Duration(seconds: 30),
    this.maxPullResumeDeferrals = 20,
    Random? random,
  }) : _onCommand = onCommand,
       _iceRestarts = DebounceMap<String>(iceRestartDelay),
       _updatingRetryDelay = updatingRetryDelay,
       _delay = delay ?? Future<void>.delayed,
       _createTimer = createTimer ?? Timer.new,
       _createPullResumeTimer = createPullResumeTimer ?? Timer.new,
       _random = random ?? Random();

  final RenegotiationCommandHandler _onCommand;
  final DebounceMap<String> _iceRestarts;
  final Duration _updatingRetryDelay;
  final Future<void> Function(Duration) _delay;
  final Timer Function(Duration, void Function()) _createTimer;
  final Timer Function(Duration, void Function()) _createPullResumeTimer;
  final Random _random;

  /// Replays sent quickly, at the delay the failure asks for, while
  /// signaling stays connected. Later ones back off.
  final int maxReplayAttempts;

  /// The longest wait between two replays once the quick ones are used up.
  final Duration maxReplayBackoff;

  /// How many times in a row renegotiation may be deferred because the call
  /// is updating before that flag is taken as stale.
  final int maxUpdatingDeferrals;

  /// How long a pulled call's negotiations must stay quiet before its resume
  /// offer is sent. A settling time, not a proof that the server is done.
  final Duration pullResumeSettle;

  /// The most resume offers one pulled call sends, retries included.
  final int maxPullResumes;

  /// How long after the pull a server offer may still arm another resume.
  /// A resume already armed when it passes still goes out.
  final Duration pullResumeWindow;

  /// How many times in a row the resume may be put off because the call was
  /// not ready for it, about half a minute of settling times.
  final int maxPullResumeDeferrals;

  final Map<String, RTCSessionDescription> _pendingOffers = {};

  /// Calls whose kept offer was acknowledged with an interim `updating` and
  /// still waits for its answer on the session that carried it. Such an offer
  /// is not sent again while that session lives: the answer is on its way.
  final Set<String> _awaitingAnswer = {};
  final Map<String, int> _replayAttempts = {};
  final Map<String, Timer> _replayTimers = {};
  final Map<String, int> _updatingDeferrals = {};
  final Map<String, _PullResume> _pullResumes = {};

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

  /// Starts the resume of a call that replaced a dialog, on its accept.
  ///
  /// PortaSIP can keep playing music to the far end after a successful pull
  /// although both sides negotiated sendrecv; answering its offers does not
  /// stop it, a fresh offer of our own does. Later accepts of the same call -
  /// the answer to that offer among them - do not arm it again.
  void pullAccepted(String callId) {
    if (_pullResumes.containsKey(callId)) return;
    final resume = _pullResumes[callId] = _PullResume();
    resume.window = _createPullResumeTimer(pullResumeWindow, () => resume.window = null);
    _armPullResume(callId, pullResumeSettle);
  }

  /// Holds the resume back from the moment a server offer arrives until it is
  /// answered or left: the offer can wait in the event queue for a while, and
  /// a resume sent meanwhile would collide with it.
  void pullServerOfferReceived(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    resume.serverOffers++;
    resume.settle?.cancel();
    resume.settle = null;
    resume.attempt = null;
  }

  /// Re-arms the resume after an answered server offer: the offer may have
  /// started the music again, and our offer waits until such offers settle.
  ///
  /// An offer that holds the call ([sendRecv] false), the far end's hold or a
  /// transfer, puts a pending resume off instead: a sendrecv offer of ours
  /// would only run into it. Its later sendrecv offer arms the resume again.
  void pullServerOfferAnswered(String callId, {bool sendRecv = true}) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    if (resume.serverOffers > 0) resume.serverOffers--;
    if (!sendRecv) {
      resume.settle?.cancel();
      resume.settle = null;
      resume.attempt = null;
      return;
    }
    if (resume.window == null || resume.sent >= maxPullResumes) return;
    resume.deferrals = 0;
    _armPullResume(callId, pullResumeSettle);
  }

  /// A server offer that was not answered no longer holds the resume back.
  void pullServerOfferLeft(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    if (resume.serverOffers > 0) resume.serverOffers--;
    if (resume.window == null || resume.sent >= maxPullResumes) return;
    _armPullResume(callId, pullResumeSettle);
  }

  /// Puts the resume off by one settling time when the call was not ready for
  /// it: an unfinished negotiation or an update in progress.
  void pullResumeDeferred(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    if (++resume.deferrals > maxPullResumeDeferrals) {
      _closePullResume(callId);
      return;
    }
    _armPullResume(callId, pullResumeSettle);
  }

  bool isPullResumeCurrent(String callId, Object attempt) {
    final resume = _pullResumes[callId];
    return resume != null && !resume.closed && identical(resume.attempt, attempt);
  }

  /// Records that the [attempt]'s offer is going out; it can no longer be
  /// started again from a stale command.
  void pullResumeSent(String callId, Object attempt) {
    if (!isPullResumeCurrent(callId, attempt)) return;
    final resume = _pullResumes[callId]!;
    resume.attempt = null;
    resume.sent++;
    resume.deferrals = 0;
  }

  /// Settles a resume offer the server turned down.
  ///
  /// A 491 is a collision with a transaction of the other side; RFC 3261
  /// 14.1 asks to try again after a random 2.1-4 s, as the owner of the
  /// Call-ID. Any other refusal would only be repeated, so the resume ends.
  void pullResumeRejected(String callId, int code) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    if (code != 491 || resume.sent >= maxPullResumes) {
      _closePullResume(callId);
      return;
    }
    _armPullResume(callId, Duration(milliseconds: 2100 + _random.nextInt(1901)));
  }

  /// Settles a resume offer that got no reply: signaling was lost or the
  /// server did not answer in time. It is tried again after one settling time
  /// while the bound of resumes allows.
  void pullResumeInterrupted(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null || resume.closed) return;
    if (resume.sent >= maxPullResumes) {
      _closePullResume(callId);
      return;
    }
    _armPullResume(callId, pullResumeSettle);
  }

  /// A deliberate hold, or a resume that failed for good: no automatic
  /// resume of this call is sent any more.
  void cancelPullResume(String callId) => _closePullResume(callId);

  /// Completes when the call is being ended, so that a wait for the answer to
  /// its resume offer does not hold the end back.
  Future<void> pullCallEnding(String callId) => (_pullResumes[callId]?.ending.future) ?? Completer<void>().future;

  /// The call is being ended: the answer to its resume offer is not needed.
  void callEnding(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null) return;
    _closePullResume(callId);
    if (!resume.ending.isCompleted) resume.ending.complete();
  }

  void _armPullResume(String callId, Duration delay) {
    final resume = _pullResumes[callId]!;
    resume.settle?.cancel();
    resume.settle = null;
    // Answering the server offer that holds it back arms it again.
    if (resume.serverOffers > 0) {
      resume.attempt = null;
      return;
    }
    final attempt = resume.attempt = Object();
    resume.settle = _createPullResumeTimer(delay, () {
      resume.settle = null;
      if (identical(resume.attempt, attempt) && !resume.closed) _onCommand(ResumePulledCall(callId, attempt));
    });
  }

  void _closePullResume(String callId) {
    final resume = _pullResumes[callId];
    if (resume == null) return;
    resume.closed = true;
    resume.attempt = null;
    resume.settle?.cancel();
    resume.settle = null;
    resume.window?.cancel();
    resume.window = null;
  }

  void callRemoved(String callId) {
    _iceRestarts.cancel(callId);
    _updatingDeferrals.remove(callId);
    callEnding(callId);
    _pullResumes.remove(callId);
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
    for (final callId in _pullResumes.keys.toList()) {
      callEnding(callId);
    }
    _pullResumes.clear();
  }
}

class _PullResume {
  Timer? settle;
  Timer? window;
  Object? attempt;
  int sent = 0;
  int deferrals = 0;

  /// Server offers that have arrived and are not answered yet.
  int serverOffers = 0;
  bool closed = false;
  final Completer<void> ending = Completer<void>();
}
