import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

StateHandshake _handshake({List<Line?> lines = const []}) => StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 1,
  registration: const Registration(status: RegistrationStatus.unregistered),
  lines: lines,
  presenceInfos: const [],
  dialogInfos: const [],
  guestLine: null,
);

SignalingProtocolEvent _protocol(Event event) => SignalingProtocolEvent(event: event);

void main() {
  late SignalingEventBuffer buffer;

  setUp(() => buffer = SignalingEventBuffer(now: () => 7));

  List<Type> kinds() => buffer.snapshot.map((e) => e.runtimeType).toList();

  StateHandshake replayed() => buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;

  test('lifecycle events replay in order with the handshake in its place', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(SignalingConnected());
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake()));
    buffer.onEvent(SignalingDisconnecting());

    expect(kinds(), [SignalingConnecting, SignalingConnected, SignalingHandshakeReceived, SignalingDisconnecting]);
  });

  test('a new session drops everything before it', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake()));
    buffer.onEvent(SignalingConnecting());

    expect(kinds(), [SignalingConnecting]);
    expect(buffer.hasActiveCalls, isFalse);
  });

  test('protocol events are folded into the replayed handshake, not replayed', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake(lines: [null])));
    buffer.onEvent(_protocol(RegisteredEvent()));
    buffer.onEvent(_protocol(IncomingCallEvent(line: 0, callId: 'c', callee: 'bob', caller: 'alice')));

    expect(buffer.snapshot.whereType<SignalingProtocolEvent>(), isEmpty);
    final handshake = replayed();
    expect(handshake.registration.status, RegistrationStatus.registered);
    expect(handshake.lines.single?.callId, 'c');
    expect(buffer.hasActiveCalls, isTrue);
  });

  test('a call that ended after the handshake is gone from what a later subscriber gets', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake(lines: [null])));
    buffer.onEvent(_protocol(IncomingCallEvent(line: 0, callId: 'c', callee: 'bob', caller: 'alice')));
    expect(replayed().lines.single, isNotNull);

    buffer.onEvent(_protocol(HangupEvent(line: 0, callId: 'c', code: 200, reason: 'OK')));

    expect(replayed().lines.single, isNull);
    expect(buffer.hasActiveCalls, isFalse);
  });

  test('a second handshake replaces the state and is replayed once', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake(lines: [null])));
    buffer.onEvent(SignalingHandshakeReceived(handshake: _handshake(lines: [null, null])));

    expect(buffer.snapshot.whereType<SignalingHandshakeReceived>(), hasLength(1));
    expect(replayed().lines, hasLength(2));
  });

  test('a protocol event before any handshake changes nothing', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(_protocol(IncomingCallEvent(line: 0, callId: 'c', callee: 'bob', caller: 'alice')));

    expect(kinds(), [SignalingConnecting]);
    expect(buffer.hasActiveCalls, isFalse);
  });

  test('clear empties the buffer and the session', () {
    buffer.onEvent(SignalingConnecting());
    buffer.onEvent(
      SignalingHandshakeReceived(
        handshake: _handshake(
          lines: [Line(callId: 'c', callLogs: const [])],
        ),
      ),
    );
    buffer.clear();

    expect(buffer.snapshot, isEmpty);
    expect(buffer.hasActiveCalls, isFalse);
  });
}
