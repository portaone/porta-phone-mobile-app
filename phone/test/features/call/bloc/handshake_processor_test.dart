import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/features/call/utils/handshake_processor.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockCallkeepConnections extends Mock implements CallkeepConnections {}

class MockQueuedTerminationRequestsRepository extends Mock implements QueuedTerminationRequestsRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kCallId = 'call-abc';
const _kLine = 0;

IncomingCallEvent _makeIncomingEvent({int line = _kLine, String callId = _kCallId}) {
  return IncomingCallEvent(line: line, callId: callId, callee: 'callee', caller: '1234');
}

AcceptedEvent _makeAcceptedEvent({int? line = _kLine, String callId = _kCallId}) {
  return AcceptedEvent(line: line, callId: callId);
}

ProceedingEvent _makeProceedingEvent({int? line = _kLine, String callId = _kCallId}) {
  return ProceedingEvent(line: line, callId: callId, code: 180);
}

RingingEvent _makeRingingEvent({int? line = _kLine, String callId = _kCallId}) {
  return RingingEvent(line: line, callId: callId);
}

Line _makeLine({String callId = _kCallId, required List<CallLog> callLogs}) {
  return Line(callId: callId, callLogs: callLogs);
}

CallkeepConnection _makeConnection({
  String callId = _kCallId,
  CallkeepConnectionState state = CallkeepConnectionState.stateActive,
}) {
  return CallkeepConnection(callId: callId, state: state, disconnectCause: null);
}

/// A call the BLoC tracks as it normally does: offered, with its offer in hand.
ActiveCall _tracked({String callId = _kCallId}) =>
    _activeCall(callId, CallProcessingStatus.incomingFromOffer, offered: true);

/// A call a push registered whose offer never came as a live event.
ActiveCall _awaitingOffer({
  String callId = _kCallId,
  CallProcessingStatus status = CallProcessingStatus.incomingFromPush,
}) => _activeCall(callId, status, offered: false);

ActiveCall _activeCall(String callId, CallProcessingStatus status, {required bool offered}) => ActiveCall(
  callId: callId,
  line: _kLine,
  direction: CallDirection.incoming,
  handle: const CallkeepHandle.number('1234'),
  createdTime: DateTime(2026),
  video: false,
  processingStatus: status,
  incomingOffer: offered ? JsepValue({'type': 'offer', 'sdp': 'v=0'}) : null,
);

QueuedTerminationRequest _makeQueuedTerminationRequest({
  QueuedTerminationRequestType type = QueuedTerminationRequestType.decline,
  String callId = _kCallId,
  int? line = _kLine,
}) {
  return QueuedTerminationRequest(type: type, callId: callId, line: line);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockCallkeepConnections mockConnections;
  late MockQueuedTerminationRequestsRepository mockQueuedTerminationRequestsRepository;
  late HandshakeProcessor processor;

  setUpAll(() {
    registerFallbackValue(_makeQueuedTerminationRequest());
  });

  setUp(() {
    mockConnections = MockCallkeepConnections();
    mockQueuedTerminationRequestsRepository = MockQueuedTerminationRequestsRepository();
    processor = HandshakeProcessor(
      callkeepConnections: mockConnections,
      queuedTerminationRequestsRepository: mockQueuedTerminationRequestsRepository,
    );

    // Default: no local connections, no connection for any callId.
    when(() => mockConnections.getConnections()).thenAnswer((_) async => []);
    when(() => mockConnections.getConnection(any())).thenAnswer((_) async => null);
    when(() => mockQueuedTerminationRequestsRepository.getAll).thenReturn(<String, QueuedTerminationRequest>{});
  });

  // -------------------------------------------------------------------------
  // Empty handshake
  // -------------------------------------------------------------------------

  group('empty handshake', () {
    test('returns empty list when lines is empty', () async {
      final actions = await processor.process(lines: [], guestLine: null, activeCalls: const []);
      expect(actions, isEmpty);
    });

    test('returns empty list when all lines are null', () async {
      final actions = await processor.process(lines: [null, null], guestLine: null, activeCalls: const []);
      expect(actions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Unanswered incoming call (single CallEventLog)
  // -------------------------------------------------------------------------

  group('unanswered incoming call', () {
    test('returns HandleIncomingCallAction for single IncomingCallEvent', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HandleIncomingCallAction>());
      final a = actions.first as HandleIncomingCallAction;
      expect(a.event.callId, _kCallId);
    });

    // Regression: WT-1369 — iOS CallKit sends 180 Ringing almost immediately,
    // so by the time a WebSocket reconnect completes the server log already has
    // [RingingEvent (latest), IncomingCallEvent (earliest)] (length=2).
    // The old callLogs.length == 1 guard silently skipped this case.
    test('returns HandleIncomingCallAction when RingingEvent prepended (iPhone 180-Ringing)', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 2000, callEvent: _makeRingingEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HandleIncomingCallAction>());
      final a = actions.first as HandleIncomingCallAction;
      expect(a.event.callId, _kCallId);
    });

    test('returns HandleIncomingCallAction when ProceedingEvent prepended', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 2000, callEvent: _makeProceedingEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HandleIncomingCallAction>());
    });

    test('skips HandleIncomingCallAction when callId already in activeCallIds', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 2000, callEvent: _makeRingingEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_tracked()]);

      expect(actions.whereType<HandleIncomingCallAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Restoration: AcceptedEvent (newest) + IncomingCallEvent (oldest)
  // -------------------------------------------------------------------------

  group('restoration candidate', () {
    Line makeRestorationLine() => _makeLine(
      callLogs: [
        CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent()),
        CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
      ],
    );

    test('returns RestoreCallAction when connection is null and call not in state', () async {
      final line = makeRestorationLine();
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<RestoreCallAction>());
      final a = actions.first as RestoreCallAction;
      expect(a.callId, _kCallId);
      expect(a.line, _kLine);
      expect(a.acceptedTime, DateTime.fromMillisecondsSinceEpoch(2000));
    });

    test('uses AcceptedEvent timestamp (newest) as acceptedTime', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 9999, callEvent: _makeAcceptedEvent()),
          CallEventLog(timestamp: 1111, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      final a = actions.first as RestoreCallAction;
      expect(a.acceptedTime, DateTime.fromMillisecondsSinceEpoch(9999));
    });

    test('skips restoration when callId already in activeCallIds', () async {
      final line = makeRestorationLine();
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_tracked()]);

      expect(actions, isEmpty);
    });

    test(
      'returns RestoreCallAction when Callkeep connection survived (stateActive) but call not in BLoC state',
      () async {
        when(() => mockConnections.getConnection(_kCallId))
            .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateActive));

        final line = makeRestorationLine();
        final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

        expect(actions, hasLength(1));
        expect(actions.first, isA<RestoreCallAction>());
      },
    );

    test(
      'skips restoration when Callkeep connection is stateDisconnected (handled by HangupSignalingAction above)',
      () async {
        when(() => mockConnections.getConnection(_kCallId))
            .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateDisconnected));

        // stateDisconnected with AcceptedEvent -> early exit with HangupSignalingAction, not RestoreCallAction
        final line = makeRestorationLine();
        final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

        expect(actions.whereType<RestoreCallAction>(), isEmpty);
      },
    );

    test('skips restoration when AcceptedEvent.line is null (guest-line call)', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent(line: null)),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<RestoreCallAction>(), isEmpty);
    });

    test('returns RestoreCallAction after re-INVITE: UpdatedEvent newest, AcceptedEvent in logs', () async {
      // After a re-INVITE (transfer or SDP update) the server puts UpdatedEvent as the newest entry.
      // AcceptedEvent is no longer first but must still be found to trigger restoration.
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 3000,
            callEvent: UpdatedEvent(line: _kLine, callId: _kCallId),
          ),
          CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<RestoreCallAction>());
      final a = actions.first as RestoreCallAction;
      expect(a.callId, _kCallId);
      expect(a.incomingCallEvent, isNotNull);
    });

    test('skips restoration when HangupEvent is the latest (call server-terminated)', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 3000,
            callEvent: HangupEvent(line: _kLine, callId: _kCallId, code: 200, reason: 'OK'),
          ),
          CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<RestoreCallAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Restoration: outgoing call (single AcceptedEvent, no IncomingCallEvent)
  // -------------------------------------------------------------------------

  group('outgoing call restoration', () {
    test('returns RestoreCallAction with incomingCallEvent null', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 5000, callEvent: _makeAcceptedEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<RestoreCallAction>());
      final a = actions.first as RestoreCallAction;
      expect(a.callId, _kCallId);
      expect(a.line, _kLine);
      expect(a.acceptedTime, DateTime.fromMillisecondsSinceEpoch(5000));
      expect(a.incomingCallEvent, isNull);
    });

    test('skips restoration when callId already in activeCallIds', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 5000, callEvent: _makeAcceptedEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_tracked()]);

      expect(actions, isEmpty);
    });

    test('skips restoration when AcceptedEvent.line is null', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 5000, callEvent: _makeAcceptedEvent(line: null))]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<RestoreCallAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // stateDisconnected connection - HangupSignalingAction
  // -------------------------------------------------------------------------

  group('stateDisconnected with AcceptedEvent', () {
    test('returns only HangupSignalingAction (early exit)', () async {
      when(() => mockConnections.getConnection(_kCallId))
          .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateDisconnected));

      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeAcceptedEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HangupSignalingAction>());
      final a = actions.first as HangupSignalingAction;
      expect(a.callId, _kCallId);
      expect(a.line, _kLine);
    });

    test('returns only HangupSignalingAction for ProceedingEvent', () async {
      when(() => mockConnections.getConnection(_kCallId))
          .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateDisconnected));

      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeProceedingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HangupSignalingAction>());
    });

    test('early exit: EndLocalCallAction is NOT generated even if orphaned connections exist', () async {
      when(() => mockConnections.getConnection(_kCallId))
          .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateDisconnected));
      when(() => mockConnections.getConnections()).thenAnswer((_) async => [_makeConnection(callId: 'orphan-id')]);

      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeAcceptedEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.whereType<EndLocalCallAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // stateDisconnected connection - DeclineSignalingAction
  // -------------------------------------------------------------------------

  group('stateDisconnected with IncomingCallEvent', () {
    test('returns only DeclineSignalingAction (early exit)', () async {
      when(() => mockConnections.getConnection(_kCallId))
          .thenAnswer((_) async => _makeConnection(state: CallkeepConnectionState.stateDisconnected));

      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<DeclineSignalingAction>());
      final a = actions.first as DeclineSignalingAction;
      expect(a.callId, _kCallId);
    });
  });

  // -------------------------------------------------------------------------
  // Orphaned local connections - EndLocalCallAction
  // -------------------------------------------------------------------------

  group('local connection not in handshake', () {
    test('returns EndLocalCallAction for each orphaned local connection', () async {
      when(() => mockConnections.getConnections())
          .thenAnswer((_) async => [_makeConnection(callId: 'orphan-1'), _makeConnection(callId: 'orphan-2')]);

      final actions = await processor.process(lines: [], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(2));
      expect(actions.every((a) => a is EndLocalCallAction), isTrue);
      final ids = actions.cast<EndLocalCallAction>().map((a) => a.callId).toSet();
      expect(ids, {'orphan-1', 'orphan-2'});
    });

    test('does NOT return EndLocalCallAction when local connection callId is in handshake', () async {
      when(() => mockConnections.getConnections()).thenAnswer((_) async => [_makeConnection(callId: _kCallId)]);

      final line = _makeLine(callLogs: []);
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<EndLocalCallAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Orphaned outgoing call (connection == null, not in BLoC, no AcceptedEvent)
  // -------------------------------------------------------------------------

  group('orphaned outgoing call — null connection, absent from BLoC', () {
    test('returns HangupSignalingAction for unanswered outgoing call (ProceedingEvent)', () async {
      // connection is null (CallKeep entry was removed by performEndCall)
      // call is not in activeCallIds (BLoC also removed it)
      // server still has it with ProceedingEvent → HangupRequest must be sent
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeProceedingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HangupSignalingAction>());
      final a = actions.first as HangupSignalingAction;
      expect(a.callId, _kCallId);
      expect(a.line, _kLine);
    });

    test('does NOT return HangupSignalingAction when call is still in BLoC activeCallIds (iOS guard)', () async {
      // On iOS getConnection() always returns null.
      // If the call IS in activeCalls the user is still in the call — must not hang up.
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeProceedingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_tracked()]);

      expect(actions.whereType<HangupSignalingAction>(), isEmpty);
    });

    test('does NOT interfere with restoration: accepted call with null connection returns RestoreCallAction', () async {
      // App-restart case: connection is null but AcceptedEvent is in logs.
      // Must produce RestoreCallAction, not HangupSignalingAction.
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<HangupSignalingAction>(), isEmpty);
      expect(actions.whereType<RestoreCallAction>(), hasLength(1));
    });

    test('does NOT return HangupSignalingAction for IncomingCallEvent with null connection', () async {
      // Unanswered incoming call with no connection — HandleIncomingCallAction path, not hangup.
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<HangupSignalingAction>(), isEmpty);
    });

    test('does NOT return HangupSignalingAction when server latest event is HangupEvent', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 2000,
            callEvent: HangupEvent(line: _kLine, callId: _kCallId, code: 487, reason: 'Request Terminated'),
          ),
          CallEventLog(timestamp: 1000, callEvent: _makeProceedingEvent()),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<HangupSignalingAction>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // guestLine is treated like a regular line
  // -------------------------------------------------------------------------

  group('guestLine', () {
    test('processes guestLine the same as regular lines', () async {
      final guestLine = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);

      final actions = await processor.process(lines: [], guestLine: guestLine, activeCalls: const []);

      expect(actions, hasLength(1));
      expect(actions.first, isA<HandleIncomingCallAction>());
    });
  });

  // -------------------------------------------------------------------------
  // queued termination requests
  // -------------------------------------------------------------------------

  group('remote media state in the log', () {
    // The caller may turn the camera off while nobody here was listening; the
    // log carries that as a MediaStatePeerMessageEvent after the offer, newest
    // first, and the plan hands the latest one on with the call.
    test('an unanswered incoming call carries the latest media state', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 3000,
            callEvent: const MediaStatePeerMessageEvent(line: _kLine, callId: _kCallId, video: false),
          ),
          CallEventLog(
            timestamp: 2000,
            callEvent: const MediaStatePeerMessageEvent(line: _kLine, callId: _kCallId, video: true),
          ),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);
      final action = actions.single as HandleIncomingCallAction;
      expect(action.mediaState?.video, isFalse, reason: 'the newest entry is the one that stands');
    });

    test('an accepted call carries the latest media state', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 3000,
            callEvent: const MediaStatePeerMessageEvent(line: _kLine, callId: _kCallId, video: false),
          ),
          CallEventLog(timestamp: 2000, callEvent: _makeAcceptedEvent()),
          CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent()),
        ],
      );
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);
      final action = actions.single as RestoreCallAction;
      expect(action.mediaState?.video, isFalse);
    });

    test('a log without a media state hands on none', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);
      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);
      expect((actions.single as HandleIncomingCallAction).mediaState, isNull);
    });
  });

  group('offer delivery to a push-registered call', () {
    const offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 RTP/AVP 0\r\n'};
    final incomingWithOffer = IncomingCallEvent(
      line: _kLine,
      callId: _kCallId,
      callee: 'callee',
      caller: '1234',
      jsep: offer,
    );

    test('a call waiting for its offer gets the offer from the log', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: incomingWithOffer)]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_awaitingOffer()]);

      final delivered = actions.whereType<DeliverOfferAction>().single;
      expect(delivered.event.jsep, offer);
      expect(actions.whereType<HandleIncomingCallAction>(), isEmpty, reason: 'the call is already tracked');
    });

    for (final status in [
      CallProcessingStatus.incomingSubmittedAnswer,
      CallProcessingStatus.incomingPerformingStarted,
    ]) {
      test('a call answered before the handshake ($status) gets the offer too', () async {
        final line = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: incomingWithOffer)]);

        final actions = await processor.process(
          lines: [line],
          guestLine: null,
          activeCalls: [_awaitingOffer(status: status)],
        );

        expect(actions.whereType<DeliverOfferAction>(), hasLength(1));
      });
    }

    test('the newest offer in the log is the one delivered, once per line', () async {
      final older = IncomingCallEvent(
        line: _kLine,
        callId: _kCallId,
        callee: 'callee',
        caller: '1234',
        jsep: const {'sdp': 'old'},
      );
      final line = _makeLine(
        callLogs: [
          CallEventLog(timestamp: 3, callEvent: _makeRingingEvent()),
          CallEventLog(timestamp: 2, callEvent: incomingWithOffer),
          CallEventLog(timestamp: 1, callEvent: older),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_awaitingOffer()]);

      expect(actions.whereType<DeliverOfferAction>().single.event.jsep, offer);
    });

    test('the caller\'s latest media state travels with the offer', () async {
      final line = _makeLine(
        callLogs: [
          CallEventLog(
            timestamp: 2,
            callEvent: const MediaStatePeerMessageEvent(line: _kLine, callId: _kCallId, video: false),
          ),
          CallEventLog(timestamp: 1, callEvent: incomingWithOffer),
        ],
      );

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_awaitingOffer()]);

      expect(actions.whereType<DeliverOfferAction>().single.mediaState?.video, isFalse);
    });

    test('a call that already holds its offer is left alone', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: incomingWithOffer)]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_tracked()]);

      expect(actions, isEmpty);
    });

    test('a log without an offer delivers nothing', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: _makeIncomingEvent())]);

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: [_awaitingOffer()]);

      expect(actions, isEmpty);
    });

    test('offer delivery comes after the per-line actions', () async {
      final other = _makeLine(
        callId: 'other',
        callLogs: [CallEventLog(timestamp: 1, callEvent: _makeIncomingEvent(callId: 'other'))],
      );
      final waiting = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: incomingWithOffer)]);

      final actions = await processor.process(
        lines: [waiting, other],
        guestLine: null,
        activeCalls: [_awaitingOffer()],
      );

      expect(actions.map((a) => a.runtimeType), [HandleIncomingCallAction, DeliverOfferAction]);
    });

    test('a plan that tears the session down carries no offer', () async {
      // A disconnected local connection for another line ends the plan early.
      when(() => mockConnections.getConnection('other'))
          .thenAnswer((_) async => _makeConnection(callId: 'other', state: CallkeepConnectionState.stateDisconnected));
      final waiting = _makeLine(callLogs: [CallEventLog(timestamp: 1, callEvent: incomingWithOffer)]);
      final dying = _makeLine(
        callId: 'other',
        callLogs: [CallEventLog(timestamp: 1, callEvent: _makeAcceptedEvent(callId: 'other'))],
      );

      final actions = await processor.process(
        lines: [waiting, dying],
        guestLine: null,
        activeCalls: [_awaitingOffer()],
      );

      expect(actions.whereType<HangupSignalingAction>(), hasLength(1));
      expect(actions.whereType<DeliverOfferAction>(), isEmpty);
    });
  });

  group('conference block', () {
    test('a room the server reports is hung up first, ahead of the per-line actions', () async {
      // The client keeps no room, so one the server has is one it cannot rejoin.
      // It goes first because the BLoC stops after a hangup or decline action.
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 0, callEvent: _makeProceedingEvent())]);
      final actions = await processor.process(
        lines: [line],
        guestLine: null,
        activeCalls: const [],
        conference: const ConferenceInfo(room: 4242),
      );
      expect(actions.first, isA<HangupStaleConferenceAction>().having((a) => a.room, 'room', 4242));
      expect(actions.last, isA<HangupSignalingAction>());
    });

    test('no room reported, nothing to hang up', () async {
      final actions = await processor.process(lines: [], guestLine: null, activeCalls: const [], conference: null);
      expect(actions, isEmpty);
    });
  });

  group('queued termination requests', () {
    test('returns regular signaling actions for queued requests', () async {
      final queued = {
        'decline:call-1': _makeQueuedTerminationRequest(callId: 'call-1', type: QueuedTerminationRequestType.decline),
        'hangup:call-2': _makeQueuedTerminationRequest(callId: 'call-2', type: QueuedTerminationRequestType.hangup),
      };
      when(() => mockQueuedTerminationRequestsRepository.getAll).thenReturn(queued);

      final actions = await processor.process(lines: [], guestLine: null, activeCalls: const []);

      expect(actions.whereType<DeclineSignalingAction>().map((a) => a.callId).toSet(), {'call-1'});
      expect(actions.whereType<HangupSignalingAction>().map((a) => a.callId).toSet(), {'call-2'});
      verify(() => mockQueuedTerminationRequestsRepository.remove(any())).called(2);
    });

    test('filters queued callIds from handshake line processing', () async {
      final line = _makeLine(callLogs: [CallEventLog(timestamp: 1000, callEvent: _makeIncomingEvent())]);
      when(() => mockQueuedTerminationRequestsRepository.getAll).thenReturn(<String, QueuedTerminationRequest>{
        'decline:${line.callId}': _makeQueuedTerminationRequest(callId: line.callId),
      });

      final actions = await processor.process(lines: [line], guestLine: null, activeCalls: const []);

      expect(actions.whereType<DeclineSignalingAction>(), hasLength(1));
      expect(actions.whereType<HandleIncomingCallAction>(), isEmpty);
      verify(() => mockQueuedTerminationRequestsRepository.remove(any())).called(1);
    });
  });
}
