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

const _handshake = StateHandshake(
  keepaliveInterval: Duration(seconds: 30),
  timestamp: 0,
  registration: Registration(status: RegistrationStatus.registered),
  lines: [null],
  dialogInfos: [],
  presenceInfos: [],
  guestLine: null,
);

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

  test('the voicemail box change goes to voicemail, not to calls', () async {
    final calls = <SignalingModuleEvent>[];
    var reads = 0;
    inbound.call.listen(calls.add);
    inbound.voicemail.listen((_) => reads++);

    module
      ..add(SignalingProtocolEvent(event: const MessageSummaryUpdate(messagesWaiting: true)))
      ..add(SignalingProtocolEvent(event: const MessageSummaryUpdate(messagesWaiting: false)));
    await pumpEventQueue();

    expect(reads, 2);
    expect(calls, isEmpty);
  });

  test(
    'each handshake asks voicemail for a read too: a change said while the session was down is not replayed',
    () async {
      final calls = <SignalingModuleEvent>[];
      var reads = 0;
      inbound.call.listen(calls.add);
      inbound.voicemail.listen((_) => reads++);
      final handshake = SignalingHandshakeReceived(handshake: _handshake);

      module
        ..add(SignalingConnected())
        ..add(handshake);
      await pumpEventQueue();

      expect(reads, 1, reason: 'the handshake, not the connection');
      expect(calls, hasLength(2), reason: 'the call feature keeps both');
    },
  );

  test('a late voicemail listener reads the box from the replayed handshake', () async {
    module
      ..add(SignalingConnected())
      ..add(SignalingHandshakeReceived(handshake: _handshake));

    var reads = 0;
    inbound.voicemail.listen((_) => reads++);
    await pumpEventQueue();

    expect(reads, 1);
  });

  test('calls keep presence and dialogs; voicemail takes no error of the transport', () async {
    final calls = <SignalingModuleEvent>[];
    final voicemailErrors = <Object>[];
    inbound.call.listen(calls.add, onError: (_) {});
    inbound.voicemail.listen((_) {}, onError: voicemailErrors.add);
    final presence = SignalingProtocolEvent(
      event: const NumberPresenceUpdate(number: '100', presenceInfo: []),
    );

    module.add(presence);
    module.live.addError(StateError('the hub went away'));
    await pumpEventQueue();

    expect(calls, [presence]);
    expect(voicemailErrors, isEmpty);
  });

  test('a feature handed its stream twice gets the same stream', () {
    expect(identical(inbound.call, inbound.call), isTrue);
    expect(identical(inbound.voicemail, inbound.voicemail), isTrue);
  });

  test('an event reaches the feature in the same turn the module sends it', () {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);

    module.add(SignalingConnected());

    expect(received, hasLength(1));
  });
}
