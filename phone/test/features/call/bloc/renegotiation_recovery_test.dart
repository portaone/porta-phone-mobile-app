import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  final transientFailures = <Object>[
    NotConnectedException('signaling disconnected'),
    const WebtritSignalingDisconnectedException(1),
    const WebtritSignalingTransactionTimeoutException(1, 'tx'),
    const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 4502, 'keepalive timeout'),
    TimeoutException('update result was not received'),
  ];

  for (final failure in transientFailures) {
    test('replays the same local offer after $failure without ending the call', () async {
      final peer = h.seedEstablishedCall('call');
      h.signaling.failure = failure;

      h.signaling.emitLifecycle(SignalingConnected());
      await pumpEventQueue();

      final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
      expect(h.bloc.state.activeCalls, hasLength(1));
      expect(h.callkeep.ended, isEmpty);
      expect(h.errors.errors, isEmpty);
      expect(peer.localDescriptions, hasLength(1));

      h.signaling.failure = null;
      peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      h.signaling.emitLifecycle(SignalingConnected());
      await pumpEventQueue();

      final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
      expect(updates, hasLength(2));
      expect(updates.last.transaction, isNot(firstUpdate.transaction));
      expect(updates.last.jsep, firstUpdate.jsep);
      expect(peer.localDescriptions, hasLength(1));

      h.signaling.emit(
        UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
      );
      await pumpEventQueue();

      expect(h.bloc.state.activeCalls, hasLength(1));
      expect(h.callkeep.ended, isEmpty);
      expect(h.errors.errors, isEmpty);
    });
  }

  test('replays the offer when signaling drops between its interim updating and the answer', () async {
    final peer = h.seedEstablishedCall('call');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    h.signaling.emit(
      UpdatingEvent(transaction: firstUpdate.transaction, line: firstUpdate.line, callId: firstUpdate.callId),
    );
    await pumpEventQueue();
    expect(h.bloc.state.retrieveActiveCall('call')?.updating, isTrue);

    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(updates.last.transaction, isNot(firstUpdate.transaction));
    expect(updates.last.jsep, firstUpdate.jsep);
    expect(peer.localDescriptions, hasLength(1));
    expect(h.bloc.state.retrieveActiveCall('call')?.updating, isFalse);

    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('forgets the offer once the answer to its interim updating arrives', () async {
    final peer = h.seedEstablishedCall('call');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    h.signaling.emit(
      UpdatingEvent(transaction: firstUpdate.transaction, line: firstUpdate.line, callId: firstUpdate.callId),
    );
    await pumpEventQueue();

    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emit(
      AcceptedEvent(
        line: firstUpdate.line,
        callId: firstUpdate.callId,
        jsep: const {'type': 'answer', 'sdp': 'v=0\r\n'},
      ),
    );
    await pumpEventQueue();
    expect(peer.remoteDescriptions.map((description) => description.type), contains('answer'));
    expect(h.bloc.state.retrieveActiveCall('call')?.updating, isFalse);

    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateStable;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    // A fresh offer, not the answered one sent again.
    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(peer.localDescriptions, hasLength(2));

    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();
  });

  test('applies a quick answer the cached signaling state does not know is due yet', () async {
    final peer = h.seedEstablishedCall('call');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    h.signaling.emit(
      UpdatingEvent(transaction: firstUpdate.transaction, line: firstUpdate.line, callId: firstUpdate.callId),
    );
    await pumpEventQueue();

    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emit(
      AcceptedEvent(
        line: firstUpdate.line,
        callId: firstUpdate.callId,
        jsep: const {'type': 'answer', 'sdp': 'v=0\r\n'},
      ),
    );
    await pumpEventQueue();
    expect(peer.remoteDescriptions.map((description) => description.type), contains('answer'));

    peer.nativeSignalingStateValue = null;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    // The answered offer is done with: the reconnect makes a fresh one.
    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(peer.localDescriptions, hasLength(2));

    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();
  });

  test('keeps the offer when the accepted event carries no answer', () async {
    final peer = h.seedEstablishedCall('call');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    h.signaling.emit(
      UpdatingEvent(transaction: firstUpdate.transaction, line: firstUpdate.line, callId: firstUpdate.callId),
    );
    await pumpEventQueue();
    h.signaling.emit(AcceptedEvent(line: firstUpdate.line, callId: firstUpdate.callId));
    await pumpEventQueue();

    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(updates.last.jsep, firstUpdate.jsep);
    expect(peer.localDescriptions, hasLength(1));

    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('replays the kept offer when the cached signaling state still reads stable', () async {
    final peer = h.seedEstablishedCall('call');
    h.signaling.failure = TimeoutException('update result was not received');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;

    h.signaling.failure = null;
    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(updates.last.jsep, firstUpdate.jsep);
    expect(peer.localDescriptions, hasLength(1));
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('retries a timed-out offer while signaling stays connected', () async {
    await h.close();
    final retryTimers = _ManualTimers();
    h = CallBlocHarness(renegotiationReplayTimer: retryTimers.create);
    final peer = h.seedEstablishedCall('call');
    h.signaling.failure = TimeoutException('update result was not received');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    retryTimers.fireNext();
    await pumpEventQueue();

    h.signaling.failure = null;
    retryTimers.fireNext();
    await pumpEventQueue();
    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(3));
    expect(updates.map((request) => request.jsep), everyElement(firstUpdate.jsep));
    expect(peer.localDescriptions, hasLength(1));

    final recovered = updates.last;
    h.signaling.emit(UpdatedEvent(transaction: recovered.transaction, line: recovered.line, callId: recovered.callId));
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('sends a replayed offer again after the update is rejected with a call error', () async {
    await h.close();
    final retryTimers = _ManualTimers();
    h = CallBlocHarness(renegotiationReplayTimer: retryTimers.create);
    final peer = h.seedEstablishedCall('call');
    h.signaling.failure = NotConnectedException('signaling disconnected');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;

    h.signaling.failure = null;
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final replay = h.signaling.requests.whereType<UpdateRequest>().last;
    expect(replay.jsep, firstUpdate.jsep);

    h.signaling.emit(
      CallErrorEvent(
        transaction: replay.transaction,
        line: replay.line,
        callId: replay.callId,
        code: 491,
        reason: 'request pending',
      ),
    );
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(2));

    // The first failure's timer was cancelled by the reconnect; the error's is the latest.
    retryTimers.fireLast();
    await pumpEventQueue();

    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(3));
    expect(updates.last.jsep, firstUpdate.jsep);
    expect(peer.localDescriptions, hasLength(1));

    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('does not send a new offer while the call is already updating', () async {
    h.seedEstablishedCall('call', updating: true);

    h.signaling.emitLifecycle(SignalingConnected());
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('renegotiates once a stale updating flag has held it back for the bound', () async {
    await h.close();
    final deferrals = <Completer<void>>[];
    h = CallBlocHarness(
      renegotiationUpdatingDelay: (_) {
        final deferral = Completer<void>();
        deferrals.add(deferral);
        return deferral.future;
      },
    );
    h.seedEstablishedCall('call', updating: true);

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    for (var deferral = 0; deferral < 9; deferral++) {
      deferrals[deferral].complete();
      await pumpEventQueue();
    }
    expect(deferrals, hasLength(10));
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
    expect(h.bloc.state.retrieveActiveCall('call')?.updating, isTrue);

    deferrals[9].complete();
    await pumpEventQueue();

    final update = h.signaling.requests.whereType<UpdateRequest>().single;
    expect(deferrals, hasLength(10), reason: 'the stale flag is cleared, not waited on again');
    h.signaling.emit(UpdatedEvent(transaction: update.transaction, line: update.line, callId: update.callId));
    await pumpEventQueue();
    expect(h.bloc.state.retrieveActiveCall('call')?.updating, isFalse);
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
  });

  test('keeps replaying with a growing delay after the quick replays fail', () async {
    await h.close();
    final retryTimers = _ManualTimers();
    h = CallBlocHarness(renegotiationReplayTimer: retryTimers.create);
    final peer = h.seedEstablishedCall('call');
    h.signaling.failure = TimeoutException('update result was not received');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final firstUpdate = h.signaling.requests.whereType<UpdateRequest>().single;
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    for (var replay = 0; replay < 4; replay++) {
      retryTimers.fireNext();
      await pumpEventQueue();
    }

    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(5));
    expect(retryTimers.durations, const [
      Duration(seconds: 2),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
    ]);
    expect(retryTimers.pending, 1, reason: 'the call is not left without a next replay');

    h.signaling.failure = null;
    retryTimers.fireNext();
    await pumpEventQueue();
    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(6));
    expect(updates.map((request) => request.jsep), everyElement(firstUpdate.jsep));
    expect(peer.localDescriptions, hasLength(1));
    h.signaling.emit(
      UpdatedEvent(transaction: updates.last.transaction, line: updates.last.line, callId: updates.last.callId),
    );
    await pumpEventQueue();
    expect(retryTimers.pending, 0);
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('cancels a pending replay when the call ends', () async {
    await h.close();
    final retryTimers = _ManualTimers();
    h = CallBlocHarness(renegotiationReplayTimer: retryTimers.create);
    h.seedEstablishedCall('call');
    h.signaling.failure = TimeoutException('update result was not received');

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
    h.signaling.failure = null;
    await h.bloc.performEndCall('call', CallkeepEndedBy.user);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);

    retryTimers.fireNext();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
  });

  test('still ends the call when renegotiation fails for a non-signaling reason', () async {
    final peer = h.seedEstablishedCall('call');
    final failure = StateError('invalid peer connection state');
    h.signaling.failure = failure;

    h.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty);
    expect(h.callkeep.ended, ['call']);
    expect(peer.closes, 1);
    expect(h.errors.errors, [failure]);
  });
}

class _ManualTimers {
  final _timers = <_ManualTimer>[];
  final durations = <Duration>[];

  int get pending => _timers.where((timer) => timer.isActive).length;

  Timer create(Duration duration, void Function() callback) {
    durations.add(duration);
    final timer = _ManualTimer(callback);
    _timers.add(timer);
    return timer;
  }

  void fireNext() => _timers.removeAt(0).fire();

  void fireLast() => _timers.removeLast().fire();
}

class _ManualTimer implements Timer {
  _ManualTimer(this._callback);

  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}
