import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

StateHandshake _handshake({
  Registration registration = const Registration(status: RegistrationStatus.unregistered),
  List<Line?> lines = const [],
  Line? guestLine,
  ConferenceInfo? conference,
}) => StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 1705322000000,
  registration: registration,
  lines: lines,
  presenceInfos: const [],
  dialogInfos: const [],
  guestLine: guestLine,
  conference: conference,
);

IncomingCallEvent _incoming(String callId, {int? line = 0}) => IncomingCallEvent(
  line: line,
  callId: callId,
  callee: 'bob',
  caller: 'alice',
  jsep: const {'type': 'offer', 'sdp': 'v=0'},
);

void main() {
  late int clock;
  setUp(() => clock = 1000);
  SessionSnapshot snapshotOf(StateHandshake handshake) => SessionSnapshot(handshake, now: () => clock++);

  group('registration', () {
    test('follows the registration events, the handshake always saying unregistered', () {
      final snapshot = snapshotOf(_handshake());
      snapshot.apply(RegisteringEvent());
      expect(snapshot.toHandshake().registration.status, RegistrationStatus.registering);
      snapshot.apply(RegisteredEvent());
      expect(snapshot.toHandshake().registration.status, RegistrationStatus.registered);
      snapshot.apply(const RegistrationFailedEvent(code: 403, reason: 'Forbidden'));
      expect(
        snapshot.toHandshake().registration,
        const Registration(status: RegistrationStatus.registration_failed, code: 403, reason: 'Forbidden'),
      );
      snapshot.apply(UnregisteringEvent());
      expect(snapshot.toHandshake().registration.status, RegistrationStatus.unregistering);
      snapshot.apply(UnregisteredEvent());
      expect(snapshot.toHandshake().registration.status, RegistrationStatus.unregistered);
    });
  });

  group('lines', () {
    test('an incoming call opens its line with the offer in the log', () {
      final snapshot = snapshotOf(_handshake(lines: [null, null]));
      expect(snapshot.hasActiveCalls, isFalse);

      snapshot.apply(_incoming('c1', line: 1));

      final lines = snapshot.toHandshake().lines;
      expect(lines, hasLength(2));
      expect(lines[0], isNull);
      expect(lines[1]?.callId, 'c1');
      final log = lines[1]!.callLogs.single as CallEventLog;
      expect(log.callEvent, isA<IncomingCallEvent>().having((e) => e.jsep, 'jsep', isNotNull));
      expect(snapshot.hasActiveCalls, isTrue);
    });

    test('a call the handshake reported keeps its position and gathers its events newest first', () {
      final snapshot = snapshotOf(
        _handshake(
          lines: [
            null,
            Line(
              callId: 'c1',
              callLogs: [CallEventLog(timestamp: 1, callEvent: _incoming('c1', line: 1))],
            ),
          ],
        ),
      );

      snapshot.apply(const AcceptedEvent(line: 1, callId: 'c1'));

      final line = snapshot.toHandshake().lines[1]!;
      expect(line.callLogs.map((l) => (l as CallEventLog).callEvent.runtimeType), [AcceptedEvent, IncomingCallEvent]);
      expect((line.callLogs.first as CallEventLog).timestamp, 1000, reason: 'stamped when the event arrived');
    });

    test('a call placed after the handshake opens its line where the server reports it', () {
      final snapshot = snapshotOf(_handshake(lines: [null]));

      snapshot.apply(const RingingEvent(line: 2, callId: 'out'));

      final lines = snapshot.toHandshake().lines;
      expect(lines, hasLength(3));
      expect(lines[2]?.callId, 'out');
    });

    test('a hangup frees the line but keeps its position', () {
      final snapshot = snapshotOf(
        _handshake(
          lines: [
            Line(callId: 'c0', callLogs: const []),
            Line(callId: 'c1', callLogs: const []),
          ],
        ),
      );

      snapshot.apply(const HangupEvent(line: 0, callId: 'c0', code: 200, reason: 'OK'));

      final lines = snapshot.toHandshake().lines;
      expect(lines, hasLength(2), reason: 'the position is the line number; nothing shifts');
      expect(lines[0], isNull);
      expect(lines[1]?.callId, 'c1');
      expect(snapshot.hasActiveCalls, isTrue);
    });

    test('a missed call frees the line too, found by call id rather than by the event line', () {
      final snapshot = snapshotOf(
        _handshake(
          lines: [Line(callId: 'c0', callLogs: const [])],
        ),
      );

      snapshot.apply(const MissedCallEvent(line: 5, callId: 'c0', callee: 'bob', caller: 'alice'));

      expect(snapshot.toHandshake().lines.single, isNull);
      expect(snapshot.hasActiveCalls, isFalse);
    });

    test('an event for an unknown ended call changes nothing', () {
      final snapshot = snapshotOf(_handshake(lines: [null]));

      snapshot.apply(const HangupEvent(line: 0, callId: 'gone', code: 200, reason: 'OK'));

      expect(snapshot.toHandshake().lines, [null]);
    });

    test('a call event without a line is not placed', () {
      final snapshot = snapshotOf(_handshake(lines: [null]));

      snapshot.apply(const RingingEvent(line: null, callId: 'x'));

      expect(snapshot.toHandshake().lines, [null]);
    });
  });

  group('guest line', () {
    test('a call without a line number opens the guest line and counts as active', () {
      final snapshot = snapshotOf(_handshake(lines: [null]));

      snapshot.apply(_incoming('guest', line: null));

      final rendered = snapshot.toHandshake();
      expect(rendered.guestLine?.callId, 'guest');
      expect(rendered.lines, [null], reason: 'the numbered lines are untouched');
      expect(snapshot.hasActiveCalls, isTrue);

      snapshot.apply(const HangupEvent(line: null, callId: 'guest', code: 200, reason: 'OK'));
      expect(snapshot.toHandshake().guestLine, isNull);
      expect(snapshot.hasActiveCalls, isFalse);
    });

    test('gathers its events and is freed by its hangup', () {
      final snapshot = snapshotOf(
        _handshake(
          guestLine: Line(callId: 'guest', callLogs: const []),
        ),
      );

      snapshot.apply(const AcceptedEvent(line: null, callId: 'guest'));
      expect(snapshot.toHandshake().guestLine?.callLogs, hasLength(1));

      snapshot.apply(const HangupEvent(line: null, callId: 'guest', code: 200, reason: 'OK'));
      expect(snapshot.toHandshake().guestLine, isNull);
    });
  });

  test('what the handshake reported and no event changes is rendered as it was', () {
    final handshake = _handshake(conference: const ConferenceInfo(room: 7));
    final snapshot = snapshotOf(handshake);
    snapshot.apply(RegisteredEvent());

    final rendered = snapshot.toHandshake();
    expect(rendered.keepaliveInterval, handshake.keepaliveInterval);
    expect(rendered.timestamp, handshake.timestamp);
    expect(rendered.presenceInfos, handshake.presenceInfos);
    expect(rendered.dialogInfos, handshake.dialogInfos);
    expect(rendered.conference, handshake.conference);
  });

  test('events that carry no session state are ignored', () {
    final snapshot = snapshotOf(_handshake(lines: [null]));
    final before = snapshot.toHandshake();

    snapshot.apply(const ConferenceTerminatedEvent(room: 1));

    expect(snapshot.toHandshake(), before);
  });
}
