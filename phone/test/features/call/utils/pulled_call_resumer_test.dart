import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';

import '../bloc/call_bloc_harness.dart';

void main() {
  late ManualOfferDeadline timer;
  late List<RenegotiationCommand> commands;
  late RenegotiationCoordinator coordinator;
  late FakeSignalingModule signaling;
  late FakePeerConnection peer;
  late PulledCallView? call;
  late List<bool> updating;
  late PulledCallResumer resumer;

  PulledCallView view({bool held = false, bool updating = false, bool signalingReady = true}) => (
    signalingReady: signalingReady,
    pulled: true,
    connected: true,
    hungUp: false,
    held: held,
    conferenced: false,
    updating: updating,
    line: 0,
    video: false,
  );

  setUp(() {
    timer = ManualOfferDeadline();
    commands = [];
    coordinator = RenegotiationCoordinator(onCommand: commands.add, createPullResumeTimer: timer.createTimer);
    signaling = FakeSignalingModule();
    peer = FakePeerConnection();
    call = view();
    updating = [];
    resumer = PulledCallResumer(
      coordinator: coordinator,
      signaling: signaling,
      peerConnection: (_) async => peer,
      readCall: (_) => call,
      prepareOffer: (_, _) {},
    );
  });
  tearDown(() => signaling.close());

  /// The attempt the coordinator hands out once the pull has settled.
  Object settledAttempt() {
    coordinator.pullAccepted('a');
    timer.pass();
    return (commands.removeLast() as ResumePulledCall).attempt;
  }

  Future<void> run(Object attempt) => resumer.run('a', attempt, setUpdating: updating.add);

  /// Starts [run] and lets it reach the wait for the reply to its offer.
  Future<UpdateRequest> sent(Future<void> running) async {
    await pumpEventQueue();
    return signaling.requests.whereType<UpdateRequest>().single;
  }

  void reply(Event Function(UpdateRequest update) event) =>
      signaling.emit(event(signaling.requests.whereType<UpdateRequest>().last));

  test('sends one fresh offer and settles on the reply', () async {
    final attempt = settledAttempt();
    final running = run(attempt);
    final update = await sent(running);
    expect(update.jsep['type'], 'offer');
    expect(coordinator.isPullResumeCurrent('a', attempt), isFalse);
    reply((u) => UpdatedEvent(transaction: u.transaction, line: u.line, callId: u.callId));
    await running;
    expect(updating, [false]);
    expect(coordinator.hasKeptOffer('a'), isFalse);
  });

  test('an interim acknowledgement keeps the offer for its answer', () async {
    final running = run(settledAttempt());
    await sent(running);
    reply((u) => UpdatingEvent(transaction: u.transaction, line: u.line, callId: u.callId));
    await running;
    expect(updating, [true]);
    expect(coordinator.hasKeptOffer('a'), isTrue);
  });

  test('an unfinished negotiation puts the offer off by one settling time', () async {
    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveRemoteOffer;
    await run(settledAttempt());
    expect(signaling.requests, isEmpty);
    expect(timer.isArmed, isTrue);
  });

  test('a held call is not resumed', () async {
    final attempt = settledAttempt();
    call = view(held: true);
    await run(attempt);
    expect(signaling.requests, isEmpty);
    expect(peer.localDescriptions, isEmpty);
  });

  test('a hold while the offer is made rolls it back unsent', () async {
    final attempt = settledAttempt();
    peer.offerGate = Completer<void>();
    final running = run(attempt);
    await pumpEventQueue();
    coordinator.cancelPullResume('a');
    peer.offerGate!.complete();
    await running;
    expect(signaling.requests, isEmpty);
    expect(peer.localDescriptions, isEmpty);
  });

  test('a 491 is rolled back and tried again, another refusal ends the resume', () async {
    var running = run(settledAttempt());
    await sent(running);
    reply(
      (u) => CallErrorEvent(transaction: u.transaction, line: u.line, callId: u.callId, code: 491, reason: 'pending'),
    );
    await running;
    expect(peer.localDescriptions.last.type, 'rollback');
    expect(updating, [false]);
    expect(timer.isArmed, isTrue);

    timer.pass();
    running = run((commands.removeLast() as ResumePulledCall).attempt);
    await pumpEventQueue();
    reply((u) => CallErrorEvent(transaction: u.transaction, line: u.line, callId: u.callId, code: 488, reason: 'no'));
    await running;
    expect(timer.isArmed, isFalse);
    expect(signaling.requests.whereType<UpdateRequest>(), hasLength(2));
  });

  test('the end of the call does not wait for the reply', () async {
    final running = run(settledAttempt());
    await sent(running);
    coordinator.callEnding('a');
    await running.timeout(const Duration(seconds: 1));
    expect(updating, isEmpty);
    expect(coordinator.hasKeptOffer('a'), isFalse);
  });

  test('a signaling loss rolls the offer back and tries again within the bound', () async {
    signaling.failure = const WebtritSignalingDisconnectedException(0);
    await run(settledAttempt());
    expect(coordinator.hasKeptOffer('a'), isFalse);
    expect(peer.localDescriptions.map((d) => d.type), ['offer', 'rollback']);
    expect(timer.isArmed, isTrue);
  });

  test('a call that receives video keeps receiving it in the resume offer', () async {
    final videoPeer = _ConstraintsPeer();
    peer = videoPeer;
    final running = run(settledAttempt());
    await sent(running);
    expect((videoPeer.constraints!['mandatory'] as Map)['OfferToReceiveVideo'], isTrue);
    reply((u) => UpdatedEvent(transaction: u.transaction, line: u.line, callId: u.callId));
    await running;
  });

  group('offersSendRecv', () {
    test('reads the audio direction, falling back to the session one', () {
      expect(PulledCallResumer.offersSendRecv('v=0\r\nm=audio 9 RTP/AVP 0\r\na=sendrecv\r\n'), isTrue);
      expect(PulledCallResumer.offersSendRecv('v=0\r\nm=audio 9 RTP/AVP 0\r\na=sendonly\r\n'), isFalse);
      expect(PulledCallResumer.offersSendRecv('v=0\r\na=inactive\r\nm=audio 9 RTP/AVP 0\r\n'), isFalse);
      expect(
        PulledCallResumer.offersSendRecv('v=0\r\nm=audio 9 RTP/AVP 0\r\nm=video 9 RTP/AVP 96\r\na=inactive\r\n'),
        isTrue,
      );
      expect(PulledCallResumer.offersSendRecv(null), isTrue);
    });
  });
}

/// An audio call receiving video on a recvonly transceiver, as a soft-mute
/// pull does; records the constraints the resume offer is made with.
class _ConstraintsPeer extends FakePeerConnection {
  Map<String, dynamic>? constraints;

  final _video = FakeRtpTransceiver(sender: FakeRtpSender(null), kind: 'video')..receiver.describe();

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async => [_video];

  @override
  Future<RTCSessionDescription> createOffer([Map<String, dynamic>? constraints]) {
    this.constraints = constraints;
    return super.createOffer(constraints);
  }
}
