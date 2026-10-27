import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

void main() {
  late CallBlocHarness h;
  late ManualOfferDeadline timer;

  setUp(() {
    timer = ManualOfferDeadline();
    h = CallBlocHarness(pullResumeTimer: timer.createTimer);
    h.seedSignalingReady();
  });
  tearDown(() => h.close());

  Future<FakePeerConnection> accepted({bool pulled = true, bool held = false}) async {
    final peer = h.seedEstablishedCall('a', fromReplaces: pulled ? 'dialog;from-tag=a;to-tag=b' : null, held: held);
    h.signaling.emit(AcceptedEvent(line: 0, callId: 'a'));
    await pumpEventQueue();
    return peer;
  }

  void replyToUpdate() {
    final update = h.signaling.requests.whereType<UpdateRequest>().last;
    h.signaling.emit(UpdatedEvent(transaction: update.transaction, line: update.line, callId: update.callId));
  }

  test('a settled pull sends one fresh offer and its answer does not repeat it', () async {
    await accepted();
    expect(timer.isArmed, isTrue);
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
    timer.pass();
    await pumpEventQueue();
    final update = h.signaling.requests.whereType<UpdateRequest>().single;
    expect(update.jsep['type'], 'offer');
    replyToUpdate();
    await pumpEventQueue();
    h.signaling.emit(AcceptedEvent(line: 0, callId: 'a'));
    await pumpEventQueue();
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
    expect(h.bloc.state.activeCalls, hasLength(1));
  });

  test('an accept whose answer is skipped still arms the resume', () async {
    h.seedEstablishedCall('a', fromReplaces: 'dialog;from-tag=a;to-tag=b');
    h.signaling.emit(
      AcceptedEvent(
        line: 0,
        callId: 'a',
        jsep: const {'type': 'answer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
    await pumpEventQueue();
    expect(timer.isArmed, isTrue);
  });

  test('answering a server offer rearms the settle timer before sending our offer', () async {
    await accepted();
    h.signaling.emit(
      const UpdatingCallEvent(
        line: 0,
        callId: 'a',
        caller: '100',
        callee: '200',
        jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>().single.jsep['type'], 'answer');
    replyToUpdate();
    await pumpEventQueue();
    expect(timer.isArmed, isTrue);
    timer.pass();
    await pumpEventQueue();
    final updates = h.signaling.requests.whereType<UpdateRequest>().toList();
    expect(updates, hasLength(2));
    expect(updates.last.jsep['type'], 'offer');
    replyToUpdate();
    await pumpEventQueue();
  });

  void rejectUpdate(int code, String reason) {
    final update = h.signaling.requests.whereType<UpdateRequest>().last;
    h.signaling.emit(
      CallErrorEvent(
        transaction: update.transaction,
        line: update.line,
        callId: update.callId,
        code: code,
        reason: reason,
      ),
    );
  }

  void serverOffer() {
    h.signaling.emit(
      const UpdatingCallEvent(
        line: 0,
        callId: 'a',
        caller: '100',
        callee: '200',
        jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
  }

  Iterable<UpdateRequest> offers() =>
      h.signaling.requests.whereType<UpdateRequest>().where((update) => update.jsep['type'] == 'offer');

  test('a server offer still waiting for its handler holds the resume back', () async {
    final lookup = Completer<void>();
    await h.close();
    h = CallBlocHarness(pullResumeTimer: timer.createTimer, contactResolver: _SlowContactResolver(lookup.future));
    h.seedSignalingReady();
    await accepted();
    serverOffer();
    await pumpEventQueue();
    expect(timer.isArmed, isFalse);
    timer.pass();
    await pumpEventQueue();
    expect(offers(), isEmpty);

    lookup.complete();
    await pumpEventQueue();
    replyToUpdate();
    await pumpEventQueue();
    timer.pass();
    await pumpEventQueue();
    expect(offers(), hasLength(1));
    replyToUpdate();
    await pumpEventQueue();
  });

  test('a resume refused with 491 is sent again and keeps the established call', () async {
    await accepted();
    timer.pass();
    await pumpEventQueue();
    rejectUpdate(491, 'Request Pending');
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.callkeep.ended, isEmpty);
    expect(h.errors.errors, isEmpty);
    expect(timer.isArmed, isTrue);
    timer.pass();
    await pumpEventQueue();
    expect(offers(), hasLength(2));
    replyToUpdate();
    await pumpEventQueue();
    expect(timer.isArmed, isFalse);
  });

  test('491 retries stop at the bound of resumes', () async {
    await accepted();
    for (var i = 0; i < 3; i++) {
      timer.pass();
      await pumpEventQueue();
      rejectUpdate(491, 'Request Pending');
      await pumpEventQueue();
    }
    expect(offers(), hasLength(3));
    expect(timer.isArmed, isFalse);
    expect(h.bloc.state.activeCalls, hasLength(1));
  });

  test('a resume refused for another reason is not repeated', () async {
    await accepted();
    timer.pass();
    await pumpEventQueue();
    rejectUpdate(488, 'Not Acceptable Here');
    await pumpEventQueue();
    expect(timer.isArmed, isFalse);
    expect(offers(), hasLength(1));
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.errors.errors, isEmpty);
  });

  test('a server offer after an answered resume arms it again', () async {
    await accepted();
    timer.pass();
    await pumpEventQueue();
    replyToUpdate();
    await pumpEventQueue();
    serverOffer();
    await pumpEventQueue();
    replyToUpdate();
    await pumpEventQueue();
    expect(timer.isArmed, isTrue);
    timer.pass();
    await pumpEventQueue();
    expect(offers(), hasLength(2));
    replyToUpdate();
    await pumpEventQueue();
  });

  test('ending the call does not wait for the answer to the resume', () async {
    await accepted();
    timer.pass();
    await pumpEventQueue();
    expect(offers(), hasLength(1));
    h.bloc.add(const CallControlEvent.ended('a'));
    await pumpEventQueue();
    expect(h.callkeep.endCalls, ['a']);
    expect(h.errors.errors, isEmpty);
  });

  test('a hold waits for the answer to a resume already sent', () async {
    await accepted();
    timer.pass();
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.setHeld('a', true));
    await pumpEventQueue();
    expect(h.callkeep.held, isEmpty);
    rejectUpdate(491, 'Request Pending');
    await pumpEventQueue();
    expect(h.callkeep.held, hasLength(1));
    expect(timer.isArmed, isFalse);
    expect(offers(), hasLength(1));
  });

  test('a regular call has no post-pull offer', () async {
    await accepted(pulled: false);
    timer.pass();
    await pumpEventQueue();
    expect(timer.isArmed, isFalse);
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('a held call is never resumed by the timer', () async {
    await accepted(held: true);
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
    expect(h.bloc.state.activeCalls.single.held, isTrue);
  });

  test('an unfinished negotiation defers the resume', () async {
    final peer = await accepted();
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveRemoteOffer;
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
    expect(timer.isArmed, isTrue);
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateStable;
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
    replyToUpdate();
    await pumpEventQueue();
  });

  test('ending the call while its fresh offer is being created sends nothing', () async {
    final peer = await accepted();
    peer.offerGate = Completer<void>();
    timer.pass();
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.ended('a'));
    await pumpEventQueue();
    peer.offerGate!.complete();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('a hold requested while creating the offer cancels the automatic resume', () async {
    final peer = await accepted();
    peer.offerGate = Completer<void>();
    timer.pass();
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.setHeld('a', true));
    await pumpEventQueue();
    peer.offerGate!.complete();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('a signaling loss before the timer sends nothing for later replay', () async {
    await accepted();
    h.signaling.connected = false;
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('closing cancels the pending resume', () async {
    await accepted();
    await h.bloc.close();
    expect(timer.isArmed, isFalse);
    timer.pass();
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });
}

/// Takes as long as [_done] to look a number up, as the device's contacts can.
class _SlowContactResolver implements ContactResolver {
  _SlowContactResolver(this._done);

  final Future<void> _done;

  @override
  Future<Contact?> resolve(String? number) => _done.then((_) => null);
}
