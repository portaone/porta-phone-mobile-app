import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Handing a call over, as the bloc drives it: what is asked of the server,
/// what the call shows meanwhile, and what is given back when the server or
/// the other party says no. Pins the behaviour as it stands, so a rework of
/// how the second call of a transfer is tied to the first has something to
/// keep to.
CallBlocHarness _harness() {
  final h = CallBlocHarness();
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  h.bloc.emit(h.bloc.state.copyWith(linesCount: 3));
  return h;
}

/// Pumps until [done], or gives up after enough turns for anything the bloc
/// queues in response to one event.
Future<void> _settle(bool Function() done) async {
  for (var turn = 0; turn < 50 && !done(); turn++) {
    await pumpEventQueue();
  }
}

Transfer? _transferOf(CallBlocHarness h, String callId) => h.bloc.state.retrieveActiveCall(callId)?.transfer;

List<({String callId, bool onHold})> _resumes(CallBlocHarness h, String callId) =>
    h.callkeep.held.where((it) => it.callId == callId && !it.onHold).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() => h = _harness());
  tearDown(() => h.close());

  group('blind transfer', () {
    Future<void> submit(String number) async {
      h.bloc.add(const CallControlEvent.blindTransferInitiated('b'));
      await _settle(() => _transferOf(h, 'b') is BlindTransferInitiated);
      h.bloc.add(CallControlEvent.blindTransferSubmitted(number: number));
      await _settle(() => h.signaling.requests.whereType<TransferRequest>().isNotEmpty);
      await _settle(() => _transferOf(h, 'b') is! BlindTransferInitiated);
    }

    test('starting one marks the call and steps the screen aside', () async {
      h.seedEstablishedCall('b', line: 1);

      h.bloc.add(const CallControlEvent.blindTransferInitiated('b'));
      await _settle(() => _transferOf(h, 'b') != null);

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
      await _settle(() => _transferOf(h, 'b') is Transfering);

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
      await _settle(() => h.callkeep.endCalls.contains('b'));

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
      await _settle(() => _resumes(h, 'b').isNotEmpty);

      expect(_transferOf(h, 'b'), isNull);
      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<BlindTransferFailedNotification>(), hasLength(1));
      expect(h.callkeep.endCalls, isEmpty);
    });

    test('a refused transfer gives the call back and says so', () async {
      h.seedEstablishedCall('b', line: 1);
      await submit('300');

      h.signaling.emit(const TransferFailedEvent(line: 1, callId: 'b', code: 403));
      await _settle(() => _resumes(h, 'b').isNotEmpty);

      expect(_transferOf(h, 'b'), isNull);
      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<BlindTransferFailedNotification>(), hasLength(1));
    });

    test('a REFER that cannot be sent leaves the call as it was', () async {
      h.seedEstablishedCall('b', line: 1);
      h.signaling.failure = NotConnectedException();

      h.bloc.add(const CallControlEvent.blindTransferInitiated('b'));
      await _settle(() => _transferOf(h, 'b') != null);
      h.bloc.add(const CallControlEvent.blindTransferSubmitted(number: '300'));
      await _settle(() => _transferOf(h, 'b') == null);

      expect(_transferOf(h, 'b'), isNull);
      expect(h.bloc.state.retrieveActiveCall('b'), isNotNull);
    });
  });

  group('attended transfer', () {
    test('starting one steps the screen aside and holds nothing yet', () async {
      h.seedEstablishedCall('b', line: 0);

      h.bloc.add(const CallControlEvent.attendedTransferInitiated('b'));
      await _settle(() => h.bloc.state.minimized == true);

      expect(_transferOf(h, 'b'), isNull);
      expect(h.callkeep.held, isEmpty);
    });

    test('the consultation call is an ordinary call that puts the first on hold', () async {
      h.seedEstablishedCall('b', line: 0);
      h.bloc.add(const CallControlEvent.attendedTransferInitiated('b'));
      await _settle(() => h.bloc.state.minimized == true);

      h.bloc.add(const CallControlEvent.started(number: '300', video: false));
      await _settle(() => h.callkeep.startCalls.isNotEmpty);

      expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
      final consultation = h.bloc.state.activeCalls.singleWhere((call) => call.callId != 'b');
      // Nothing ties it to the call it is a consultation for.
      expect(consultation.fromReferId, isNull);
      expect(consultation.transfer, isNull);
      expect(_transferOf(h, 'b'), isNull);
    });

    test('a consultation call that is not answered leaves the first call on hold', () async {
      // Today's behaviour, pinned so that changing it is a decision: nothing
      // takes the first call off hold when the consultation call ends without
      // an answer.
      h.seedEstablishedCall('b', line: 0);
      h.bloc.add(const CallControlEvent.attendedTransferInitiated('b'));
      await _settle(() => h.bloc.state.minimized == true);
      h.bloc.add(const CallControlEvent.started(number: '300', video: false));
      await _settle(() => h.callkeep.startCalls.isNotEmpty);
      final consultation = h.bloc.state.activeCalls.singleWhere((call) => call.callId != 'b');

      h.signaling.emit(HangupEvent(line: consultation.line, callId: consultation.callId, code: 480, reason: 'test'));
      await _settle(() => h.bloc.state.retrieveActiveCall(consultation.callId) == null);
      await _settle(() => false);

      expect(h.bloc.state.retrieveActiveCall(consultation.callId), isNull);
      expect(_resumes(h, 'b'), isEmpty);
    });

    test('submitting sends a REFER of the first call that replaces the consultation call', () async {
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;

      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await _settle(() => h.signaling.requests.whereType<TransferRequest>().isNotEmpty);
      await _settle(() => _transferOf(h, 'b') != null);

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
      await _settle(() => h.errors.errors.isNotEmpty);

      expect(h.signaling.requests.whereType<TransferRequest>(), isEmpty);
      expect(h.errors.errors, hasLength(1));
    });

    test('the server taking it on shows the transfer in progress', () async {
      h.seedEstablishedCall('b', line: 0, held: true);
      h.seedEstablishedCall('c', line: 1, number: '300');
      final b = h.bloc.state.retrieveActiveCall('b')!;
      final c = h.bloc.state.retrieveActiveCall('c')!;
      h.bloc.add(CallControlEvent.attendedTransferSubmitted(referorCall: b, replaceCall: c));
      await _settle(() => _transferOf(h, 'b') != null);

      h.signaling.emit(const TransferringEvent(line: 0, callId: 'b'));
      await _settle(() => _transferOf(h, 'b') is Transfering);

      expect(_transferOf(h, 'b'), const Transfer.transfering(fromAttendedTransfer: true, fromBlindTransfer: false));
    });
  });

  group('attended transfer asked of this phone', () {
    // The other side consulted this phone and asks it to take over its call
    // with somebody else.
    void ask() => h.signaling.emit(
      const TransferEvent(line: 0, referId: 'ref-1', referTo: '400', referredBy: '300', replaceCallId: 'b'),
    );

    test('the call it replaces asks the person to confirm', () async {
      h.seedEstablishedCall('b', line: 0);

      ask();
      await _settle(() => _transferOf(h, 'b') != null);

      expect(
        _transferOf(h, 'b'),
        const Transfer.attendedTransferConfirmationRequested(referId: 'ref-1', referTo: '400', referredBy: '300'),
      );
    });

    test('declining tells the server and clears the request', () async {
      h.seedEstablishedCall('b', line: 0);
      ask();
      await _settle(() => _transferOf(h, 'b') != null);

      h.bloc.add(const CallControlEvent.attendedRequestDeclined(callId: 'b', referId: 'ref-1'));
      await _settle(() => _transferOf(h, 'b') == null);

      final decline = h.signaling.requests.whereType<DeclineRequest>().single;
      expect(decline.callId, 'b');
      expect(decline.referId, 'ref-1');
      expect(_transferOf(h, 'b'), isNull);
    });

    test('approving places a call to the number it is to be connected with', () async {
      h.seedEstablishedCall('b', line: 0);
      ask();
      await _settle(() => _transferOf(h, 'b') != null);

      h.bloc.add(const CallControlEvent.attendedRequestApproved(referId: 'ref-1', referTo: '400'));
      await _settle(() => h.callkeep.startCalls.isNotEmpty);

      final placed = h.bloc.state.activeCalls.singleWhere((call) => call.callId != 'b');
      expect(h.callkeep.startCalls, [placed.callId]);
      expect(placed.handle, const CallkeepHandle.number('400'));
      expect(placed.fromReferId, 'ref-1');
      expect(placed.processingStatus, CallProcessingStatus.outgoingCreatedFromRefer);
      expect(h.bloc.state.minimized, isFalse);
    });
  });
}
