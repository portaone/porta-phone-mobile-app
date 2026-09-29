import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/services/isolate_manager.dart';

/// Records what the push session asks of callkeep.
class _FakeCallkeep implements PushSessionCallkeep {
  final List<String> released = [];
  final List<String> handedOff = [];

  @override
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate) {}

  @override
  Future<void> releaseCall(String callId) async => released.add(callId);

  @override
  Future<void> handoffCall(String callId) async => handedOff.add(callId);
}

/// A signaling module the test drives by hand.
class _FakeSignaling extends Fake implements SignalingModule {
  final _events = StreamController<SignalingModuleEvent>.broadcast(sync: true);

  @override
  Stream<SignalingModuleEvent> get events => _events.stream;

  @override
  bool get isConnected => true;

  @override
  Future<void>? execute(Request request) async {}

  @override
  void connect() {}

  @override
  Future<void> dispose() async => _events.close();

  void handshake(List<({String callId, String caller})> incoming) => _events.add(
    SignalingHandshakeReceived(
      handshake: StateHandshake(
        keepaliveInterval: const Duration(seconds: 30),
        timestamp: 0,
        registration: const Registration(status: RegistrationStatus.registered),
        lines: [
          for (final (i, call) in incoming.indexed)
            Line(
              callId: call.callId,
              callLogs: [
                CallEventLog(
                  timestamp: 0,
                  callEvent: IncomingCallEvent(line: i, callId: call.callId, callee: '555001', caller: call.caller),
                ),
              ],
            ),
        ],
        presenceInfos: const [],
        dialogInfos: const [],
        guestLine: null,
      ),
    ),
  );

  void hangup(String callId, {int line = 0}) => _events.add(
    SignalingProtocolEvent(
      event: HangupEvent(line: line, callId: callId, code: 487, reason: 'Request Terminated'),
    ),
  );

  void activityTookOver() => _events.add(
    SignalingDisconnected(
      code: 4441,
      reason: 'force attach close',
      knownCode: SignalingDisconnectCode.controllerForceAttachClose,
      recommendedReconnectDelay: null,
    ),
  );
}

void main() {
  late _FakeCallkeep callkeep;
  late _FakeSignaling signaling;
  late List<(String, String?)> missed;
  late PushNotificationIsolateManager manager;

  const owner = CallkeepIncomingCallMetadata(
    callId: 'c1',
    handle: CallkeepHandle.number('555002'),
    displayName: 'User 555002',
  );

  setUp(() {
    callkeep = _FakeCallkeep();
    signaling = _FakeSignaling();
    missed = [];
    manager = PushNotificationIsolateManager(
      callkeep: callkeep,
      createSignaling: () => signaling,
      logger: Logger('test'),
      onMissedCall: (callId, name) async => missed.add((callId, name)),
    )..init();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('one call on the session', () {
    test('its hangup releases it and ends the session', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.hangup('c1');
      await session;

      expect(callkeep.released, ['c1']);
      expect(missed.single.$1, 'c1');
    });

    test('an Activity taking over hands the ringing call off', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.activityTookOver();
      await session;
      await manager.close().catchError((_) {});
      await settle();

      expect(callkeep.handedOff, ['c1']);
      expect(callkeep.released, isEmpty);
    });
  });

  group('more than one call on the session', () {
    test('another call hanging up keeps the session on its own call', () async {
      var ended = false;
      final session = manager.run(owner)..whenComplete(() => ended = true);
      signaling.handshake([(callId: 'c1', caller: '555002'), (callId: 'c2', caller: '555003')]);

      signaling.hangup('c2', line: 1);
      await settle();

      expect(ended, isFalse, reason: 'c1 still rings; the session must hear its hangup');
      expect(callkeep.released, ['c2'], reason: 'the other call is ended natively');
      expect(callkeep.handedOff, isEmpty, reason: 'c1 must not be handed off while it rings');

      signaling.hangup('c1');
      await session;

      expect(callkeep.released, ['c2', 'c1']);
    });

    test('the own call not on line 0 is still found and handed off', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c2', caller: '555003'), (callId: 'c1', caller: '555002')]);

      signaling.activityTookOver();
      await session;
      await manager.close().catchError((_) {});
      await settle();

      expect(callkeep.handedOff, ['c1']);
      expect(callkeep.released, isEmpty, reason: 'releasing c1 would decline a call that still rings');
    });
    test('the session ends when its own call is already gone from the lines', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c2', caller: '555003')]);

      await session.timeout(const Duration(seconds: 1));

      expect(callkeep.released, ['c1'], reason: 'the own call ended before the session opened');
    });
  });
}
