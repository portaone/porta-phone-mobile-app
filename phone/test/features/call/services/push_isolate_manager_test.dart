import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_async/fake_async.dart';
import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/services/isolate_manager.dart';

/// Records what the push session asks of callkeep.
class _FakeCallkeep implements PushSessionCallkeep {
  final List<String> reported = [];
  final List<String> released = [];

  @override
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate) {}

  @override
  Future<void> reportEndCall(String callId, CallkeepEndCallReason reason) async => reported.add(callId);

  @override
  Future<void> releaseCall(String callId) async => released.add(callId);
}

/// A signaling module the test drives by hand.
class _FakeSignaling extends Fake implements SignalingModule {
  final _events = StreamController<SignalingModuleEvent>.broadcast(sync: true);

  /// Whether the session counts as connected; requests made while it is false are queued.
  bool connected = true;

  /// Every request the session sent, in order.
  final List<Request> executed = [];

  @override
  Stream<SignalingModuleEvent> get events => _events.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void>? execute(Request request) async => executed.add(request);

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

  /// An incoming call that arrives as a protocol event rather than as a handshake line.
  void incoming(String callId, {required int line, required String caller}) => _events.add(
    SignalingProtocolEvent(
      event: IncomingCallEvent(line: line, callId: callId, callee: '555001', caller: caller),
    ),
  );

  void unregistered() => _events.add(SignalingProtocolEvent(event: UnregisteredEvent()));

  void connectionFailed() => _events.add(
    SignalingConnectionFailed(
      error: StateError('refused'),
      isRepeated: false,
      recommendedReconnectDelay: Duration.zero,
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
  TestWidgetsFlutterBinding.ensureInitialized();

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

  // A few event-loop turns: enough for a deferred handshake check and a platform-channel reply.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  // PushNotificationIsolateManager asks Connectivity() itself, so the plugin channel is answered.
  void mockConnectivity(List<String> states) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? states : null,
      );

  group('one call on the session', () {
    test('its hangup ends it and ends the session', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.hangup('c1');
      await session;

      expect(callkeep.reported, ['c1']);
      expect(callkeep.released, isEmpty, reason: 'the plugin ends the session on its own');
      expect(missed.single.$1, 'c1');
    });

    test('an Activity taking over leaves the ringing call to it', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.activityTookOver();
      await session;
      await manager.close().catchError((_) {});
      await settle();

      expect(callkeep.reported, isEmpty, reason: 'the call is live and now the Activity\'s');
      expect(callkeep.released, isEmpty);
    });
  });

  // On a cold start the missed-call record can wait: the notification goes through a platform
  // channel to a main thread busy starting the Activity's engine, and the call log waits on the
  // database. The end must reach callkeep before that wait, or Telecom keeps the call alive
  // long enough for the Activity to be replayed a call the caller has left. The session itself
  // must outlive the record, so it is not released until the record is done.
  group('ending a call does not wait for its missed-call record', () {
    late Completer<void> notificationShown;

    setUp(() {
      notificationShown = Completer<void>();
      // A fresh signaling module: the outer setUp's manager must not hear these events.
      signaling = _FakeSignaling();
      manager = PushNotificationIsolateManager(
        callkeep: callkeep,
        createSignaling: () => signaling,
        logger: Logger('test'),
        onMissedCall: (callId, name) {
          missed.add((callId, name));
          return notificationShown.future;
        },
      )..init();
    });

    test('an own call already gone from the server is ended while its record is pending', () async {
      var done = false;
      final session = manager.run(owner)..whenComplete(() => done = true);
      signaling.handshake([]);
      await settle();

      expect(missed.single.$1, 'c1', reason: 'the missed call is being recorded');
      expect(callkeep.reported, ['c1'], reason: 'callkeep must end the call before the record');
      expect(done, isFalse, reason: 'the session must live until the record is done');

      notificationShown.complete();
      await session;
      expect(callkeep.released, isEmpty, reason: 'the plugin ends the session on its own');
    });

    test('an own call hung up is ended while its record is pending', () async {
      var done = false;
      final session = manager.run(owner)..whenComplete(() => done = true);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.hangup('c1');
      await settle();

      expect(callkeep.reported, ['c1']);
      expect(done, isFalse);

      notificationShown.complete();
      await session;
    });

    test('another call hung up is ended while its record is pending', () async {
      var done = false;
      manager.run(owner).whenComplete(() => done = true);
      signaling.handshake([(callId: 'c1', caller: '555002'), (callId: 'c2', caller: '555003')]);

      signaling.hangup('c2', line: 1);
      await settle();

      expect(callkeep.reported, ['c2']);
      expect(done, isFalse, reason: 'c1 still rings');

      notificationShown.complete();
      await settle();
      expect(done, isFalse, reason: 'c1 still rings after the record too');
    });

    test('the Activity taking over waits for a record another call started', () async {
      // The order seen in the design review: a second call hangs up and its record begins,
      // then the Activity takes the session over. The session must not complete - and the
      // plugin must not stop the service - before that record is done.
      var done = false;
      final session = manager.run(owner)..whenComplete(() => done = true);
      signaling.handshake([(callId: 'c1', caller: '555002'), (callId: 'c2', caller: '555003')]);
      signaling.hangup('c2', line: 1);
      await settle();

      signaling.activityTookOver();
      await settle();
      expect(done, isFalse, reason: 'the record of c2 is still pending');

      notificationShown.complete();
      await session;
      expect(missed.single.$1, 'c2');
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
      expect(callkeep.reported, ['c2'], reason: 'the other call is ended natively');
      expect(callkeep.released, isEmpty, reason: 'c1 must not be released while it rings');

      signaling.hangup('c1');
      await session;

      expect(callkeep.reported, ['c2', 'c1']);
    });

    test('the own call not on line 0 is still found and left to the Activity', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c2', caller: '555003'), (callId: 'c1', caller: '555002')]);

      signaling.activityTookOver();
      await session;
      await manager.close().catchError((_) {});
      await settle();

      expect(callkeep.reported, isEmpty, reason: 'c1 is live: nothing ends it');
      expect(callkeep.released, isEmpty, reason: 'releasing c1 would decline a call that still rings');
    });
    test('the session ends when its own call is already gone from the lines', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c2', caller: '555003')]);

      await session.timeout(const Duration(seconds: 1));

      expect(callkeep.reported, ['c1'], reason: 'the own call ended before the session opened');
    });
  });

  group('missed call', () {
    test('another incoming call the session saw is recorded under its own caller', () async {
      manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002'), (callId: 'c2', caller: '555003')]);

      signaling.hangup('c2', line: 1);
      await settle();

      expect(missed, [('c2', '555003')]);
    });

    test('another call the session never saw arrive is not recorded as missed', () async {
      manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.hangup('c9', line: 1);
      await settle();

      expect(missed, isEmpty, reason: 'an outgoing call or one answered elsewhere is not a missed call');
      expect(callkeep.reported, ['c9'], reason: 'it is still ended natively');
    });
  });

  group('handshake without lines', () {
    test('the own call arriving as an event right after keeps the session on it', () async {
      var ended = false;
      final session = manager.run(owner)..whenComplete(() => ended = true);
      signaling.handshake([]);
      signaling.incoming('c1', line: 0, caller: '555002');
      await settle();

      expect(ended, isFalse, reason: 'the call is replayed after the handshake, not missing');
      expect(callkeep.released, isEmpty);

      signaling.hangup('c1');
      await session;

      expect(callkeep.reported, ['c1']);
    });

    test('nothing arriving after it ends the own call as missed', () async {
      final session = manager.run(owner);
      signaling.handshake([]);

      await session.timeout(const Duration(seconds: 1));

      expect(callkeep.reported, ['c1']);
      expect(missed, [('c1', 'User 555002')]);
    });
  });

  group('the session losing the server', () {
    test('unregistering releases the own call without recording it', () async {
      final session = manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      signaling.unregistered();
      await session;

      expect(callkeep.released, ['c1']);
      expect(missed, isEmpty);
    });

    test('a failed connection releases the own call without recording it', () async {
      final session = manager.run(owner);

      signaling.connectionFailed();
      await session;

      expect(callkeep.released, ['c1']);
      expect(missed, isEmpty);
    });
  });

  group('decline from the notification', () {
    test('while connected is sent at once on the call line', () async {
      manager.run(owner);
      signaling.handshake([(callId: 'c2', caller: '555003'), (callId: 'c1', caller: '555002')]);

      manager.performEndCall('c1');
      await settle();

      final decline = signaling.executed.single as DeclineRequest;
      expect((decline.callId, decline.line), ('c1', 1));
    });

    test('for a call not on the lines is dropped', () async {
      manager.run(owner);
      signaling.handshake([(callId: 'c1', caller: '555002')]);

      manager.performEndCall('c9');
      await settle();

      expect(signaling.executed, isEmpty);
    });

    test('before the handshake waits for it and then goes out on the call line', () async {
      signaling.connected = false;
      manager.run(owner);

      manager.performEndCall('c1');
      await settle();
      expect(signaling.executed, isEmpty, reason: 'queued until the session knows the lines');

      signaling.connected = true;
      signaling.handshake([(callId: 'c1', caller: '555002')]);
      await settle();

      final decline = signaling.executed.single as DeclineRequest;
      expect((decline.callId, decline.line), ('c1', 0));
    });

    test('queued for a call the handshake does not list is dropped', () async {
      signaling.connected = false;
      manager.run(owner);

      manager.performEndCall('c9');
      signaling.connected = true;
      signaling.handshake([(callId: 'c1', caller: '555002')]);
      await settle();

      expect(signaling.executed, isEmpty);
    });

    test('dropped for an unknown call stays dropped when a later handshake lists it', () async {
      signaling.connected = false;
      manager.run(owner);

      manager.performEndCall('c9');
      signaling.connected = true;
      signaling.handshake([(callId: 'c1', caller: '555002')]);
      await settle();
      signaling.handshake([(callId: 'c1', caller: '555002'), (callId: 'c9', caller: '555009')]);
      await settle();

      expect(signaling.executed, isEmpty);
    });

    test('queued longer than 10 s is dropped', () {
      fakeAsync((async) {
        final signaling = _FakeSignaling()..connected = false;
        final manager = PushNotificationIsolateManager(
          callkeep: _FakeCallkeep(),
          createSignaling: () => signaling,
          logger: Logger('test'),
          onMissedCall: (callId, name) async {},
        )..init();
        manager.run(owner);

        manager.performEndCall('c1');
        async.elapse(const Duration(seconds: 11));
        signaling.connected = true;
        signaling.handshake([(callId: 'c1', caller: '555002')]);
        async.flushMicrotasks();

        expect(signaling.executed, isEmpty);
      });
    });
  });

  group('closing the session', () {
    test('an answer with network leaves the call to the Activity', () async {
      mockConnectivity(['wifi']);
      final session = manager.run(owner);

      manager.performAnswerCall('c1');
      await settle();
      final ended = expectLater(session, throwsStateError, reason: 'close() ends a running session with an error');
      await manager.close();
      await ended;

      expect(callkeep.released, isEmpty, reason: 'the answered call is the Activity\'s now');
      expect(callkeep.reported, isEmpty);
    });

    test('an answer without network is not remembered: a call never seen is released', () async {
      mockConnectivity(['none']);
      final session = manager.run(owner);

      manager.performAnswerCall('c1');
      await settle();
      final ended = expectLater(session, throwsStateError, reason: 'close() ends a running session with an error');
      await manager.close();
      await ended;

      expect(callkeep.released, ['c1']);
    });

    test('before the own call was seen releases it', () async {
      final session = manager.run(owner);

      final ended = expectLater(session, throwsStateError, reason: 'close() ends a running session with an error');
      await manager.close();
      await ended;

      expect(callkeep.released, ['c1']);
    });
  });
}
