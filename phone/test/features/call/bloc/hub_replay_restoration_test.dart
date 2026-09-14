import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_android/src/fgs/hub/signaling_hub.dart';
import 'package:signaling_service_android/src/fgs/hub/signaling_hub_client.dart';
import 'package:signaling_service_android/src/fgs/hub/signaling_hub_module.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'call_bloc_harness.dart';

/// What a late subscriber of the foreground-service hub gets, driven end to
/// end: a real hub on real ports, a real client and, where the outcome is a
/// call state, a real CallBloc. The hub replays the session as state - a
/// handshake rendered from the calls that are up - and these pin the cases
/// where state, not history, is what the subscriber must see.
///
/// The probes were written by the review of the hub snapshot change and are
/// adopted as its coverage.
class _Source extends Fake implements SignalingModule {
  final controller = StreamController<SignalingModuleEvent>.broadcast();

  @override
  Stream<SignalingModuleEvent> get events => controller.stream;

  @override
  bool get isConnected => true;
}

const _emptyHandshake = StateHandshake(
  keepaliveInterval: Duration(seconds: 30),
  timestamp: 0,
  registration: Registration(status: RegistrationStatus.registered),
  lines: [null, null],
  presenceInfos: [],
  dialogInfos: [],
  guestLine: null,
);

const _videoOffer = {
  'type': 'offer',
  'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n',
};

/// Runs a hub through [history] after an empty handshake, then attaches a
/// client and returns what it received, and whether the hub counted a call
/// as up before the client came.
Future<({List<SignalingModuleEvent> events, bool active})> _replay(
  List<Event> history, {
  void Function(SignalingModuleEvent)? onEvent,
}) async {
  final source = _Source();
  final hub = SignalingHub(source)..start();
  source.controller.add(SignalingConnecting());
  source.controller.add(SignalingConnected());
  source.controller.add(SignalingHandshakeReceived(handshake: _emptyHandshake));
  for (final event in history) {
    source.controller.add(SignalingProtocolEvent(event: event));
  }
  await pumpEventQueue();
  final active = hub.hasActiveCalls;
  final client = SignalingHubClient.tryConnect('late')!;
  final received = <SignalingModuleEvent>[];
  final subscription = client.events.listen((event) {
    received.add(event);
    onEvent?.call(event);
  });
  final ack = client.awaitAck();
  client.start();
  expect(await ack, isTrue);
  await pumpEventQueue();
  await subscription.cancel();
  await client.dispose();
  await hub.dispose();
  await source.controller.close();
  return (events: received, active: active);
}

/// Every call event a subscriber can learn of from [events]: those inside the
/// handshake's lines, and any replayed as protocol events.
Iterable<CallEvent> _describedCalls(List<SignalingModuleEvent> events) sync* {
  for (final event in events) {
    if (event is SignalingHandshakeReceived) {
      for (final line in [...event.handshake.lines, event.handshake.guestLine].whereType<Line>()) {
        yield* line.callLogs.whereType<CallEventLog>().map((log) => log.callEvent);
      }
    } else if (event is SignalingProtocolEvent && event.event is CallEvent) {
      yield event.event as CallEvent;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a guest call that arrived after the handshake reaches a late subscriber', () async {
    // A guest call has no line number; it is the guest slot, not an event to drop.
    final result = await _replay([
      const IncomingCallEvent(line: null, callId: 'guest', caller: '100', callee: '200', jsep: _videoOffer),
    ]);
    expect(_describedCalls(result.events).whereType<IncomingCallEvent>(), hasLength(1));
  });

  test('a guest call counts as an active call for the config-sync guard', () async {
    final result = await _replay([const IncomingCallEvent(line: null, callId: 'guest', caller: '100', callee: '200')]);
    expect(result.active, isTrue);
  });

  test('a numbered call that arrived after the handshake reaches a late subscriber', () async {
    final result = await _replay([const IncomingCallEvent(line: 0, callId: 'regular', caller: '100', callee: '200')]);
    expect(_describedCalls(result.events).whereType<IncomingCallEvent>(), hasLength(1));
    expect(result.active, isTrue);
  });

  test('a camera turned off before attach is off in the restored call', () async {
    // The caller sent a video offer and then turned the camera off while no
    // Activity was listening; the restored call must be answered as audio.
    final h = CallBlocHarness();
    addTearDown(h.close);
    await _replay(
      [
        const IncomingCallEvent(line: 0, callId: 'video-call', caller: '100', callee: '200', jsep: _videoOffer),
        const MediaStatePeerMessageEvent(line: 0, callId: 'video-call', video: false),
      ],
      onEvent: (event) {
        if (event is SignalingHandshakeReceived) h.signaling.emitHandshake(event.handshake);
        if (event is SignalingProtocolEvent) h.signaling.emit(event.event);
      },
    );
    await pumpEventQueue();
    expect(h.errors.errors, isEmpty);
    expect(h.bloc.state.activeCalls, hasLength(1));
    expect(h.bloc.state.activeCalls.single.video, isFalse);
    expect(h.bloc.state.activeCalls.single.remoteCameraEnabled, isFalse);
  });

  test('a consumer wired before the ack gets the replay, and the live events after it', () async {
    // The module in the app isolate keeps no buffer: its one consumer listens
    // before the hub's ack, receives the session as it stands, and from then
    // on the live events - here a hangup that empties the restored call.
    final source = _Source();
    final hub = SignalingHub(source)..start();
    source.controller.add(SignalingConnecting());
    source.controller.add(SignalingConnected());
    source.controller.add(SignalingHandshakeReceived(handshake: _emptyHandshake));
    source.controller.add(
      SignalingProtocolEvent(
        event: const IncomingCallEvent(line: 0, callId: 'ended', caller: '100', callee: '200', jsep: _videoOffer),
      ),
    );
    await pumpEventQueue();
    final client = SignalingHubClient.tryConnect('consumer-first')!;
    final ack = client.awaitAck();
    final module = SignalingHubModule(client);
    final h = CallBlocHarness();
    final subscription = module.events.listen((event) {
      if (event is SignalingHandshakeReceived) h.signaling.emitHandshake(event.handshake);
      if (event is SignalingProtocolEvent) h.signaling.emit(event.event);
    });
    expect(await ack, isTrue);
    await pumpEventQueue();
    final restored = h.bloc.state.activeCalls.map((c) => c.callId).toList();

    // 487 is what the server sends for a ringing call the caller gave up on.
    source.controller.add(
      SignalingProtocolEvent(
        event: const HangupEvent(line: 0, callId: 'ended', code: 487, reason: 'Request Terminated'),
      ),
    );
    // The hangup crosses two ports and the bloc's mutation queue; a bounded
    // wait, not a fixed number of pumps. The fake callkeep never answers
    // reportEndCall with performEndCall, so the report to callkeep is what is
    // observable here, not the call's removal from the state.
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (h.callkeep.ended.isEmpty && DateTime.now().isBefore(deadline)) {
      await pumpEventQueue();
    }
    final endedInCallkeep = h.callkeep.ended.toList();
    await subscription.cancel();
    await h.close();
    await module.dispose();
    await hub.dispose();
    await source.controller.close();
    expect(restored, ['ended']);
    expect(endedInCallkeep, ['ended']);
  });
}
