import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';
import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// A hold or unhold the server declines, or that never reached it, is only a
/// hold that did not happen: the call stays up, its previous hold state
/// stands, its peer connection is untouched, and a later attempt still works.
/// Code 410 is the exception - it says there is no call to hold - and a fault
/// in this client is not a refused request; both still end the call.
///
/// The probes were written by the review of the refused-hold change and are
/// adopted as the handler's coverage.
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  const survivable = [
    WebtritSignalingErrorException(1, 0, 'line_in_conference'),
    WebtritSignalingErrorException(1, 403, 'forbidden'),
    WebtritSignalingErrorException(1, 500, 'internal'),
    WebtritSignalingTransactionTimeoutException(1, 'tx'),
  ];

  for (final held in [false, true]) {
    for (final failure in [...survivable, NotConnectedException()]) {
      test('held=$held survives $failure and can retry', () async {
        final peer = h.seedEstablishedCall('a', held: held);
        h.signaling.failure = failure;

        await h.bloc.performSetHeld('a', !held);
        await pumpEventQueue();

        expect(h.signaling.requests, hasLength(1));
        expect(h.signaling.requests.single, held ? isA<UnholdRequest>() : isA<HoldRequest>());
        final call = h.bloc.state.activeCalls.single;
        expect(call.held, held, reason: 'the state change is the one thing lost');
        expect(call.processingStatus, CallProcessingStatus.connected);
        expect(await h.peers.retrieve('a'), same(peer));
        expect(peer.closes, 0);
        expect(h.callkeep.ended, isEmpty);
        expect(h.errors.errors, isEmpty, reason: 'a refusal is not a fault to report');

        h.signaling.failure = null;
        await h.bloc.performSetHeld('a', !held);
        await pumpEventQueue();

        expect(h.bloc.state.activeCalls.single.held, !held);
        expect(peer.closes, 0);
        expect(h.callkeep.ended, isEmpty);
      });
    }
  }

  for (final failure in [const WebtritSignalingErrorException(1, 410, 'call not found'), StateError('bad state')]) {
    test('$failure still ends the call and releases its peer connection', () async {
      final peer = h.seedEstablishedCall('a');
      h.signaling.failure = failure;

      await h.bloc.performSetHeld('a', true);
      await pumpEventQueue();

      expect(h.bloc.state.activeCalls, isEmpty);
      expect(h.callkeep.ended, ['a']);
      expect(peer.closes, 1);
      expect(await h.peers.retrieve('a'), isNull);
      expect(h.errors.errors, [failure]);
    });
  }

  test('the OS is answered before the server is, so a refusal is not visible to it', () async {
    // Known and deferred: the perform event fulfils before the hold transaction
    // starts, so CallKit and Telecom learn "held" while the call is not. This
    // test pins the behaviour as it is; the fix needs a design of its own.
    h.seedEstablishedCall('a');
    h.signaling.gate = Completer<void>();

    final osAnswer = await h.bloc.performSetHeld('a', true);

    expect(osAnswer, isTrue);
    expect(h.signaling.gate!.isCompleted, isFalse, reason: 'the server has not answered yet');

    h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'line_in_conference');
    h.signaling.gate!.complete();
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.single.held, isFalse);
    expect(h.callkeep.ended, isEmpty);
  });
}
