import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Handing a call over, as the bloc drives it: what is asked of the server,
/// what the call shows meanwhile, and what is given back when the server or
/// the other party says no. Pins the behaviour as it stands, so a rework of
/// how the second call of a transfer is tied to the first has something to
/// keep to. Where today's behaviour is a gap rather than intent, the test
/// says so.

Transfer? _transferOf(CallBlocHarness h, String callId) => h.bloc.state.retrieveActiveCall(callId)?.transfer;

List<({String callId, bool onHold})> _resumes(CallBlocHarness h, String callId) =>
    h.callkeep.held.where((it) => it.callId == callId && !it.onHold).toList();

/// The calls the test placed, apart from the ones it seeded.
List<ActiveCall> _placed(CallBlocHarness h, {Set<String> seeded = const {'b'}}) =>
    h.bloc.state.activeCalls.where((call) => !seeded.contains(call.callId)).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() => h = CallBlocHarness(lines: 3));
  tearDown(() => h.close());

  group('blind transfer', () {
    Future<void> initiate() async {
      h.bloc.add(const CallControlEvent.blindTransferInitiated('b'));
      await h.settle(() => _transferOf(h, 'b') is BlindTransferInitiated);
    }

    Future<void> submit(String number) async {
      await initiate();
      h.bloc.add(CallControlEvent.blindTransferSubmitted(number: number));
      await h.settle(() => h.signaling.answered.whereType<TransferRequest>().isNotEmpty);
      await h.settle(() => _transferOf(h, 'b') is! BlindTransferInitiated);
    }

    test('starting one marks the call and steps the screen aside', () async {
      h.seedEstablishedCall('b', line: 1);

      await initiate();

      expect(_transferOf(h, 'b'), const Transfer.blindTransferInitiated());
      expect(h.bloc.state.minimized, isTrue);
      expect(h.callkeep.held, isEmpty);
    });

    test('a chosen number is sent as a REFER of that call, and the screen comes back', () async {
      h.seedEstablishedCall('b', line: 1);

      await submit('300');

      final request = h.signaling.requests.whereType<TransferRequest>().single;
      expect(request.callId, 'b');
      expect(request.line, 1);
      expect(request.number, '300');
      expect(request.replaceCallId, isNull);
      expect(_transferOf(h, 'b'), const Transfer.blindTransferTransferSubmitted(toNumber: '300'));
      expect(h.bloc.state.minimized, isFalse);
    });

    test('the server taking it on shows the transfer in progress', () async {
      h.seedEstablishedCall('b', line: 1);
      await submit('300');

      h.signaling.emit(const TransferringEvent(line: 1, callId: 'b'));
      await h.settle(() => _transferOf(h, 'b') is Transfering);

      expect(
        _transferOf(h, 'b'),
        const Transfer.transfering(fromAttendedTransfer: false, fromBlindTransfer: true, toNumber: '300'),
      );
    });

    test('an accepted REFER ends the call here', () async {
      h.seedEstablishedCall('b', line: 1);
      await submit('300');

      h.signaling.emit(
        const ReferNotifyEvent(
          line: 1,
          callId: 'b',
          subscriptionState: SubscriptionState.terminated,
          state: ReferAccepted(),
        ),
      );
      await h.settle(() => h.callkeep.endCalls.contains('b'));

      expect(h.callkeep.endCalls, ['b']);
    });

    test('a failed REFER gives the call back and says so', () async {
      h.seedEstablishedCall('b', line: 1);
      await submit('300');

      h.signaling.emit(
        const ReferNotifyEvent(
          line: 1,
          callId: 'b',
          subscriptionState: SubscriptionState.terminated,
          state: ReferFailed(sipCode: 603, reason: 'Decline'),
        ),
      );
      await h.settle(() => _resumes(h, 'b').isNotEmpty);

      expect(_transferOf(h, 'b'), isNull);
      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<BlindTransferFailedNotification>(), hasLength(1));
      expect(h.callkeep.endCalls, isEmpty);
    });

    test('a refused transfer gives the call back and says so', () async {
      h.seedEstablishedCall('b', line: 1);
      await submit('300');

      h.signaling.emit(const TransferFailedEvent(line: 1, callId: 'b', code: 403));
      await h.settle(() => _resumes(h, 'b').isNotEmpty);

      expect(_transferOf(h, 'b'), isNull);
      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<BlindTransferFailedNotification>(), hasLength(1));
    });

    for (final (name, failure) in [
      ('the session is not connected', NotConnectedException()),
      ('the server does not answer in time', const WebtritSignalingTransactionTimeoutException(1, 'tx')),
    ]) {
      test('a REFER that fails because $name drops the transfer, and nothing else', () async {
        h.seedEstablishedCall('b', line: 1);
        h.signaling.failure = failure;
        await initiate();

        h.bloc.add(const CallControlEvent.blindTransferSubmitted(number: '300'));
        await h.settle(() => _transferOf(h, 'b') == null);

        expect(h.signaling.answered.whereType<TransferRequest>(), hasLength(1));
        expect(_transferOf(h, 'b'), isNull);
        expect(h.bloc.state.retrieveActiveCall('b'), isNotNull);
        // A gap, pinned so changing it is a decision: the call screen stays
        // away and the person is not told the transfer did not happen.
        expect(h.bloc.state.minimized, isTrue);
        expect(h.notifications, isEmpty);
      });
    }

    test('a REFER that fails any other way leaves the call still waiting for a destination', () async {
      // A gap, pinned so changing it is a decision: only an unsent request
      // and a timeout roll the transfer back; anything else is reported and
      // leaves the call marked as looking for a destination, the screen away.
      h.seedEstablishedCall('b', line: 1);
      h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'Server Internal Error');
      await initiate();

      h.bloc.add(const CallControlEvent.blindTransferSubmitted(number: '300'));
      await h.settle(() => h.errors.errors.isNotEmpty);

      expect(h.signaling.answered.whereType<TransferRequest>(), hasLength(1));
      expect(h.errors.errors, hasLength(1));
      expect(_transferOf(h, 'b'), const Transfer.blindTransferInitiated());
      expect(h.bloc.state.minimized, isTrue);
    });
  });

  group('attended transfer', () {
    Future<void> initiate() async {
      h.bloc.add(const CallControlEvent.linkedCallPickingStarted());
      await h.settle(() => h.bloc.state.minimized == true);
    }

    test('starting one steps the screen aside and holds nothing yet', () async {
      h.seedEstablishedCall('b', line: 0);
      expect(h.bloc.state.minimized, isNot(isTrue));

      await initiate();

      expect(h.bloc.state.minimized, isTrue);
      expect(_transferOf(h, 'b'), isNull);
      expect(h.callkeep.held, isEmpty);
    });

    test('the second call is placed on behalf of the first, which it puts on hold', () async {
      h.seedEstablishedCall('b', line: 0);
      await initiate();

      h.bloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '300'));
      await h.settle(() => h.callkeep.starts.isNotEmpty);

      expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
      final consultation = _placed(h).single;
      // The link is what ties the two: which call this one was placed for,
      // and so which call the hand-over is of.
      expect(
        h.bloc.state.linkedCall,
        LinkedCall(
          callId: consultation.callId,
          anchorCallId: 'b',
          purpose: LinkedCallPurpose.attendedTransfer,
          anchorWasLive: true,
        ),
      );
      expect(_transferOf(h, 'b'), isNull);
    });

    test('a second call that rings out gives the first call back', () async {
      // It used to stay on hold: nothing took it off when the call placed
      // for it ended without an answer.
      h.seedSignalingReady();
      h.seedEstablishedCall('b', line: 0);
      await initiate();
      h.bloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '300'));
      await h.settle(() => h.callkeep.starts.isNotEmpty);
      final consultation = _placed(h).single;

      // The platform's perform callback, which the fake does not make itself:
      // the offer goes out and C rings.
      h.bloc.performStartCall(consultation.callId, consultation.handle, null, false);
      await h.settle(
        () =>
            h.bloc.state.retrieveActiveCall(consultation.callId)?.processingStatus ==
            CallProcessingStatus.outgoingOfferSent,
      );
      expect(h.signaling.requests.whereType<OutgoingCallRequest>().single.callId, consultation.callId);

      h.signaling.emit(
        HangupEvent(line: consultation.line, callId: consultation.callId, code: 480, reason: 'No Answer'),
      );
      await h.settle(() => _resumes(h, 'b').isNotEmpty);

      expect(h.bloc.state.retrieveActiveCall(consultation.callId), isNull);
      expect(h.bloc.state.retrieveActiveCall('b'), isNotNull);
      expect(h.bloc.state.linkedCall, isNull);
      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<LinkedCallFailedNotification>().map((it) => it.failure), [
        LinkedCallFailure.unanswered,
      ]);
    });

    test('submitting sends a REFER of the first call that replaces the consultation call', () async {
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;

      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await h.settle(() => _transferOf(h, 'b') != null);

      final request = h.signaling.requests.whereType<TransferRequest>().single;
      expect(request.callId, 'b');
      expect(request.line, 0);
      expect(request.number, '300');
      expect(request.replaceCallId, 'c');
      expect(_transferOf(h, 'b'), const Transfer.attendedTransferTransferSubmitted(replaceCallId: 'c'));
    });

    test('a transfer of a call to itself is not sent', () async {
      h.seedEstablishedCall('b', line: 0);
      final b = h.bloc.state.retrieveActiveCall('b')!;

      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: b));
      await h.settle(() => h.errors.errors.isNotEmpty);

      expect(h.signaling.requests.whereType<TransferRequest>(), isEmpty);
      expect(h.errors.errors, hasLength(1));
    });

    test('the server taking it on shows the transfer in progress', () async {
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;
      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await h.settle(() => _transferOf(h, 'b') != null);

      h.signaling.emit(const TransferringEvent(line: 0, callId: 'b'));
      await h.settle(() => _transferOf(h, 'b') is Transfering);

      expect(_transferOf(h, 'b'), const Transfer.transfering(fromAttendedTransfer: true, fromBlindTransfer: false));
    });

    test('a second submit of a call already being handed over is not sent', () async {
      // The menu keeps the held call listed until the server ends both calls,
      // so a second tap reaches the bloc with the pair it had.
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;
      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await h.settle(() => _transferOf(h, 'b') != null);

      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await h.settle(() => false);

      expect(h.signaling.requests.whereType<TransferRequest>(), hasLength(1));
    });

    test('a call that ended while the menu was open is not handed over to', () async {
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;
      h.signaling.emit(const HangupEvent(line: 1, callId: 'c', code: 200, reason: 'Normal'));
      await h.settle(() => h.bloc.state.retrieveActiveCall('c') == null);

      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await h.settle(() => false);

      expect(h.signaling.requests.whereType<TransferRequest>(), isEmpty);
    });
  });

  group('attended transfer asked of this phone', () {
    // The other side consulted this phone and asks it to take over its call
    // with somebody else.
    Future<void> ask() async {
      h.signaling.emit(
        const TransferEvent(line: 0, referId: 'ref-1', referTo: '400', referredBy: '300', replaceCallId: 'b'),
      );
      await h.settle(() => _transferOf(h, 'b') != null);
    }

    test('the call it replaces asks the person to confirm', () async {
      h.seedEstablishedCall('b', line: 0);

      await ask();

      expect(
        _transferOf(h, 'b'),
        const Transfer.attendedTransferConfirmationRequested(referId: 'ref-1', referTo: '400', referredBy: '300'),
      );
    });

    test('declining tells the server and clears the request', () async {
      h.seedEstablishedCall('b', line: 0);
      await ask();

      h.bloc.add(const CallControlEvent.attendedRequestDeclined(callId: 'b', referId: 'ref-1'));
      await h.settle(() => _transferOf(h, 'b') == null);

      final decline = h.signaling.requests.whereType<DeclineRequest>().single;
      expect(decline.callId, 'b');
      expect(decline.referId, 'ref-1');
      expect(_transferOf(h, 'b'), isNull);
    });

    test('approving places a call to the number it is to be connected with', () async {
      h.seedEstablishedCall('b', line: 0);
      await ask();

      h.bloc.add(const CallControlEvent.attendedRequestApproved(referId: 'ref-1', referTo: '400'));
      await h.settle(() => _placed(h).isNotEmpty);

      final placed = _placed(h).single;
      expect(h.callkeep.starts, [
        (callId: placed.callId, handle: const CallkeepHandle.number('400'), hasVideo: false, proximityEnabled: true),
      ]);
      expect(placed.handle, const CallkeepHandle.number('400'));
      expect(placed.fromReferId, 'ref-1');
      expect(placed.processingStatus, CallProcessingStatus.outgoingCreatedFromRefer);
      expect(h.bloc.state.minimized, isFalse);
      // A gap, pinned so changing it is a decision: unlike any other outgoing
      // call, this one is handed to the platform with the call it replaces
      // still live, not put on hold first.
      expect(h.callkeep.held, isEmpty);
    });
  });
}
