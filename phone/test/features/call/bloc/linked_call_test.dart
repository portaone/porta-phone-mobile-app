import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// A call placed on behalf of another one - a consultation before a transfer:
/// the anchor is held, the new call is tied to it, and every way the new call
/// can fail gives the anchor back.

/// Places a consultation call for 'b' and returns the new call's id.
Future<String> _consult(CallBlocHarness h, {String anchorCallId = 'b'}) async {
  h.bloc.add(CallControlEvent.attendedTransferCallPlaced(anchorCallId: anchorCallId, number: '300'));
  await h.settle(() => h.bloc.state.linkedCall != null);
  return h.bloc.state.linkedCall!.callId;
}

Future<void> _hangUp(CallBlocHarness h, String callId, int code) async {
  final line = h.bloc.state.retrieveActiveCall(callId)!.line;
  h.signaling.emit(HangupEvent(line: line, callId: callId, code: code, reason: 'test'));
  await h.settle(() => h.bloc.state.retrieveActiveCall(callId) == null && h.bloc.state.linkedCall == null);
}

List<({String callId, bool onHold})> _resumes(CallBlocHarness h, String callId) =>
    h.callkeep.held.where((it) => it.callId == callId && !it.onHold).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() => h = CallBlocHarness(lines: 3));
  tearDown(() => h.close());

  test('a consultation holds the call it is for and places a call tied to it', () async {
    h.seedEstablishedCall('b', line: 0);

    final c = await _consult(h);

    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(h.callkeep.startCalls, [c]);
    expect(
      h.bloc.state.linkedCall,
      LinkedCall(callId: c, anchorCallId: 'b', purpose: LinkedCallPurpose.attendedTransfer, anchorWasLive: true),
    );
    expect(h.bloc.state.retrieveActiveCall(c)!.line, 1);
    expect(h.bloc.state.minimized, isFalse);
  });

  test('the consultation is what the screen acts on while it rings, not the call it is for', () async {
    // The hangup acts on the focused call: left on the held call, it ended
    // that call and the consultation went on ringing.
    h.seedEstablishedCall('b', line: 0);
    h.bloc.add(const CallControlEvent.callSelected('b'));
    await pumpEventQueue();

    final c = await _consult(h);

    expect(h.bloc.state.focusedCall?.callId, c);
  });

  group('a consultation that does not come up gives the call back', () {
    for (final (code, failure) in [
      (486, LinkedCallFailure.busy),
      (603, LinkedCallFailure.declined),
      (480, LinkedCallFailure.unanswered),
      (487, LinkedCallFailure.unanswered),
      (500, LinkedCallFailure.failed),
    ]) {
      test('hangup $code', () async {
        h.seedEstablishedCall('b', line: 0);
        final c = await _consult(h);

        await _hangUp(h, c, code);

        expect(h.bloc.state.retrieveActiveCall(c), isNull);
        expect(h.bloc.state.linkedCall, isNull);
        expect(_resumes(h, 'b'), hasLength(1));
        final told = h.notifications.whereType<LinkedCallFailedNotification>().map((it) => it.failure);
        // Busy and the rest are said by the hangup itself, as for any call.
        final saidHere = failure == LinkedCallFailure.declined || failure == LinkedCallFailure.unanswered;
        expect(told, saidHere ? [failure] : isEmpty);
      });
    }
  });

  test('the call is resumed only after the linked call has ended on the platform', () async {
    // Two calls off hold at once are not allowed: iOS drops one, Android holds
    // the older one again. So the resume waits for the end of the linked
    // call to be reported, not just decided.
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);
    final endReported = Completer<void>();
    h.callkeep.endReportGate = endReported;

    h.signaling.emit(HangupEvent(line: 1, callId: c, code: 486, reason: 'busy'));
    await h.settle(() => h.callkeep.ended.contains(c));
    await pumpEventQueue();

    expect(h.callkeep.ended, contains(c));
    expect(_resumes(h, 'b'), isEmpty);

    endReported.complete();
    await h.settle(() => h.bloc.state.linkedCall == null);

    expect(_resumes(h, 'b'), hasLength(1));
  });

  test('a call the platform refuses to place gives the call back', () async {
    h.seedEstablishedCall('b', line: 0);
    h.callkeep.startError = CallkeepCallRequestError.internal;

    h.bloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '300'));
    await h.settle(() => _resumes(h, 'b').isNotEmpty);

    expect(h.bloc.state.activeCalls.map((it) => it.callId), ['b']);
    expect(h.bloc.state.linkedCall, isNull);
    expect(_resumes(h, 'b'), hasLength(1));
  });

  test('a call that was already on hold is left on hold', () async {
    h.seedEstablishedCall('b', line: 0, held: true);
    final c = await _consult(h);

    await _hangUp(h, c, 603);

    expect(_resumes(h, 'b'), isEmpty);
  });

  test('cancelling ends the linked call and gives the call back without a word', () async {
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);

    h.bloc.add(CallControlEvent.ended(c));
    await h.settle(() => h.callkeep.endCalls.contains(c));
    expect(h.callkeep.endCalls, [c]);

    // The platform's end callback, which the fake does not make itself.
    await h.bloc.performEndCall(c);
    await h.settle(() => h.bloc.state.linkedCall == null);
    // The server confirms the hangup with its own code afterwards.
    h.signaling.emit(HangupEvent(line: 1, callId: c, code: 487, reason: 'Request Terminated'));
    await h.settle(() => h.bloc.state.retrieveActiveCall(c) == null);

    expect(_resumes(h, 'b'), hasLength(1));
    expect(h.notifications.whereType<LinkedCallFailedNotification>(), isEmpty);
  });

  test('a late hangup does not resume the call twice', () async {
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);

    await _hangUp(h, c, 603);
    h.signaling.emit(HangupEvent(line: 1, callId: c, code: 487, reason: 'late'));
    await h.settle(() => false);

    expect(_resumes(h, 'b'), hasLength(1));
  });

  test('an answered consultation keeps its link, so the transfer knows which call it is for', () async {
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);
    // The linked call's connection, as the outgoing pipeline would have left
    // it once its offer was sent; the answer is applied to it.
    h.peers.complete(c, FakePeerConnection());

    h.signaling.emit(AcceptedEvent(line: 1, callId: c));
    await h.settle(() => h.bloc.state.retrieveActiveCall(c)?.wasAccepted == true);

    expect(h.bloc.state.linkedCall?.callId, c);
    expect(h.bloc.state.linkedCall?.anchorCallId, 'b');
    expect(_resumes(h, 'b'), isEmpty);
  });

  test('a call answered while the linked one rang keeps the anchor on hold when it fails', () async {
    // Taking the anchor off hold beside the newly answered call would be two
    // live calls at once, which the operating system does not allow.
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);
    h.seedEstablishedCall('d', line: 2, direction: CallDirection.incoming, number: '400');

    await _hangUp(h, c, 603);

    expect(h.bloc.state.linkedCall, isNull);
    // The hold the link put on is left in place; the fake records the
    // request, the real platform would report it back as held.
    expect(_resumes(h, 'b'), isEmpty);
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
  });

  test('once the hand-over is submitted the link is over, and the anchor is not resumed', () async {
    // The server ends both calls after the REFER, in either order; the first
    // to go must not read as the linked call failing.
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);
    h.peers.complete(c, FakePeerConnection());
    h.signaling.emit(AcceptedEvent(line: 1, callId: c));
    await h.settle(() => h.bloc.state.retrieveActiveCall(c)?.wasAccepted == true);
    final b = h.bloc.state.retrieveActiveCall('b')!;
    final cCall = h.bloc.state.retrieveActiveCall(c)!;

    h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: cCall));
    await h.settle(() => h.bloc.state.linkedCall == null);
    expect(h.bloc.state.linkedCall, isNull);

    h.signaling.emit(HangupEvent(line: 1, callId: c, code: 200, reason: 'Call completed elsewhere'));
    await h.settle(() => h.bloc.state.retrieveActiveCall(c) == null);

    expect(_resumes(h, 'b'), isEmpty);
    expect(h.notifications.whereType<LinkedCallFailedNotification>(), isEmpty);
  });

  test('the linked call stays as an ordinary call when the call it was for ends', () async {
    h.seedEstablishedCall('b', line: 0);
    final c = await _consult(h);

    await _hangUp(h, 'b', 480);
    await h.settle(() => h.bloc.state.linkedCall == null);

    expect(h.bloc.state.linkedCall, isNull);
    expect(h.bloc.state.retrieveActiveCall(c), isNotNull);
    expect(h.callkeep.endCalls, isEmpty);
  });

  group('a consultation is refused', () {
    test('while another linked call is under way', () async {
      h.seedEstablishedCall('b', line: 0);
      await _consult(h);
      final before = h.callkeep.startCalls.length;

      h.bloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '400'));
      await h.settle(() => h.notifications.whereType<GeneralUnableToCallNotification>().isNotEmpty);

      expect(h.callkeep.startCalls, hasLength(before));
    });

    test('with every main line taken, without holding anything', () async {
      h.seedEstablishedCall('b', line: 0);
      h.seedEstablishedCall('d', line: 1);
      h.seedEstablishedCall('e', line: 2);

      h.bloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '300'));
      await h.settle(() => h.notifications.isNotEmpty);

      expect(h.notifications.whereType<GeneralUnableToCallNotification>(), hasLength(1));
      expect(h.callkeep.startCalls, isEmpty);
      expect(h.callkeep.held, isEmpty);
      expect(h.bloc.state.linkedCall, isNull);
    });
  });
}
