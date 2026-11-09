import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

import 'package:webtrit_phone/app/session/signaling_inbound.dart';

/// A module whose [events] replays [replay] to each new listener, then goes
/// on live - the contract of [SignalingModule.events].
class _Module {
  final live = StreamController<SignalingModuleEvent>.broadcast(sync: true);
  final replay = <SignalingModuleEvent>[];
  int streamsTaken = 0;
  int open = 0;

  Stream<SignalingModuleEvent> events() {
    streamsTaken++;
    final snapshot = [...replay];
    late StreamSubscription<SignalingModuleEvent> liveSubscription;
    final controller = StreamController<SignalingModuleEvent>(sync: true);
    controller
      ..onListen = () {
        open++;
        snapshot.forEach(controller.add);
        liveSubscription = live.stream.listen(controller.add, onError: controller.addError);
      }
      ..onCancel = () {
        open--;
        return liveSubscription.cancel();
      };
    return controller.stream;
  }

  void add(SignalingModuleEvent event) {
    replay.add(event);
    live.add(event);
  }
}

/// An event the server could send that no feature takes.
class _Unowned extends Event {
  const _Unowned();

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => {Event.typeKey: 'unowned'};
}

void main() {
  late _Module module;
  late SignalingInbound inbound;

  setUp(() {
    module = _Module();
    inbound = SignalingInbound(module.events);
  });

  tearDown(() => module.live.close());

  test('the call feature takes every event, in the order the module sends them', () async {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);
    final events = [
      SignalingConnecting(),
      SignalingConnected(),
      SignalingProtocolEvent(event: const ConferenceTerminatedEvent(room: 1)),
      SignalingDisconnecting(),
    ];

    events.forEach(module.add);
    await pumpEventQueue();

    expect(received, events);
  });

  test('a late listener gets the module\'s replay of the session, as a direct listener would', () async {
    final connecting = SignalingConnecting();
    final connected = SignalingConnected();
    module
      ..add(connecting)
      ..add(connected);

    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);
    await pumpEventQueue();

    expect(received, [connecting, connected]);
  });

  test('takes a stream from the module only when listened to, one per listener', () async {
    final call = inbound.call;
    expect(module.streamsTaken, 0);

    final first = call.listen((_) {});
    final second = call.listen((_) {});

    expect(module.streamsTaken, 2);
    expect(module.open, 2);
    await first.cancel();
    await second.cancel();
    expect(module.open, 0);
  });

  test('an event of no consumer goes nowhere; the call stream takes only its own', () async {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);
    final presence = SignalingProtocolEvent(
      event: const NumberPresenceUpdate(number: '100', presenceInfo: []),
    );

    module
      ..add(SignalingProtocolEvent(event: const _Unowned()))
      ..add(presence);
    await pumpEventQueue();

    expect(received, [presence]);
    expect(SignalingInbound.consumerOf(SignalingProtocolEvent(event: const _Unowned())), isNull);
  });

  test('an error of the module reaches the call stream, as it reached the call feature before', () async {
    final errors = <Object>[];
    inbound.call.listen((_) {}, onError: (Object error) => errors.add(error));

    module.live.addError(StateError('the hub went away'));
    await pumpEventQueue();

    expect(errors, hasLength(1));
  });

  test('an event reaches the feature in the same turn the module sends it', () {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);

    module.add(SignalingConnected());

    expect(received, hasLength(1));
  });
}
