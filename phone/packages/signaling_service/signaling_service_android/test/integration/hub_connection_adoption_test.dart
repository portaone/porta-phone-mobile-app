import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:signaling_service_android/src/constants.dart';
import 'package:signaling_service_android/src/fgs/hub/signaling_hub_codec.dart';
import 'package:signaling_service_android/src/fgs/hub/signaling_hub_command.dart';
import 'package:signaling_service_android/src/fgs/hub_connection_manager.dart';

SignalingHandshakeReceived _handshake(int timestamp) => SignalingHandshakeReceived(
  handshake: StateHandshake(
    keepaliveInterval: const Duration(seconds: 30),
    timestamp: timestamp,
    registration: const Registration(status: RegistrationStatus.registered),
    lines: const [null],
    presenceInfos: const [],
    dialogInfos: const [],
    guestLine: null,
  ),
);

/// HubConnectionManager listens to the module before the hub's ack and holds
/// what arrives until the attempt is adopted: what reaches onEvent when the
/// ack comes, when the attempt is torn down first, and when a newer attempt
/// supersedes it. The probes were written by the review of the change and are
/// adopted as its coverage; they drive a fake hub over real ports.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ReceivePort port;
  late HubConnectionManager manager;
  late List<SignalingModuleEvent> received;
  late List<SignalingHubSubscribeCommand> attempts;
  late Completer<void> firstSubscribe;
  setUp(() {
    IsolateNameServer.removePortNameMapping(kSignalingHubPortName);
    port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, kSignalingHubPortName);
    received = [];
    attempts = [];
    firstSubscribe = Completer<void>();
    port.listen((wire) {
      final command = SignalingHubCommand.decode(wire);
      if (command is SignalingHubSubscribeCommand) {
        attempts.add(command);
        if (!firstSubscribe.isCompleted) firstSubscribe.complete();
        if (attempts.length > 1) {
          command.replyPort.send(encodeSubAck());
          command.replyPort.send(encodeHubEvent(SignalingConnected()));
          command.replyPort.send(encodeHubEvent(_handshake(2)));
        }
      }
    });
    manager = HubConnectionManager(
      consumerId: 'review',
      onEvent: received.add,
      onError: (error, stack) => fail('$error'),
      isActive: () => true,
    );
  });
  tearDown(() async {
    await manager.tearDown();
    port.close();
    IsolateNameServer.removePortNameMapping(kSignalingHubPortName);
  });

  test('events before adoption are held until ack and forwarded once', () async {
    manager.begin();
    await firstSubscribe.future.timeout(const Duration(seconds: 2));
    final reply = attempts.single.replyPort;
    reply.send(encodeHubEvent(SignalingConnected()));
    reply.send(encodeHubEvent(_handshake(1)));
    await pumpEventQueue();
    expect(received, isEmpty);
    reply.send(encodeSubAck());
    await pumpEventQueue();
    expect(received.whereType<SignalingConnected>(), hasLength(1));
    expect(received.whereType<SignalingHandshakeReceived>().single.handshake.timestamp, 1);
  });

  test('teardown while awaiting ack discards the attempt and its replay', () async {
    manager.begin();
    await firstSubscribe.future.timeout(const Duration(seconds: 2));
    final stopping = manager.tearDown();
    final reply = attempts.single.replyPort;
    reply.send(encodeSubAck());
    reply.send(encodeHubEvent(SignalingConnected()));
    reply.send(encodeHubEvent(_handshake(1)));
    await stopping;
    await pumpEventQueue();
    expect(received, isEmpty);
    expect(manager.isConnected, isFalse);
  });

  test('superseding an unacknowledged attempt forwards only the new generation', () async {
    manager.begin();
    await firstSubscribe.future.timeout(const Duration(seconds: 2));
    final old = attempts.single.replyPort;
    old.send(encodeHubEvent(_handshake(1)));
    await pumpEventQueue();
    manager.begin();
    old.send(encodeSubAck());
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (received.whereType<SignalingHandshakeReceived>().isEmpty && DateTime.now().isBefore(deadline)) {
      await pumpEventQueue();
    }
    expect(attempts, hasLength(2));
    expect(received.whereType<SignalingHandshakeReceived>().map((event) => event.handshake.timestamp), [2]);
    expect(received.whereType<SignalingConnected>(), hasLength(1));
  });
}
