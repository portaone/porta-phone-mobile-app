import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../call_bloc_harness.dart';

/// The contract harness: a real [CallBloc] driven by the event flows a person
/// can produce, not by a seeded state.
///
/// The ordinary harness ([CallBlocHarness]) seeds a call with `emit`, which
/// is a test seam: it puts the bloc into a state the code under test never
/// puts it into by itself. A contract test that pinned the queue order on
/// such a state would pin the order of a fiction. So this harness reaches the
/// same bloc only through the flows that exist in production:
///
///   - an incoming call arrives as a signaling offer and is answered from the
///     platform ([CallContractHarness.ringIncomingCall] +
///     [CallContractHarness.answerIncomingCall]),
///   - an outgoing call is placed and accepted by the far end
///     ([CallContractHarness.placeOutgoingCall] +
///     [CallContractHarness.acceptOutgoingCall]),
///   - the platform asks for something through the delegate, and the
///     bloc answers it.
///
/// It names the flows, not the components behind them: a test that needs a
/// call up says "an incoming call, answered", never "a seeded ActiveCall with
/// processingStatus connected". The seams the flows need (the timers of the
/// renegotiation coordinator, the room's offer deadline, the media manager)
/// are the ones the contract does not talk about, so they are the defaults of
/// the harness and never named by a test.
class CallContractHarness {
  CallContractHarness._({required int lines, required bool sendPresenceSettings, required bool conference})
    : _lines = lines,
      _harness = CallBlocHarness(
        sendPresenceSettings: sendPresenceSettings,
        capabilities: CallCapabilitiesConfig(isConferenceEnabled: conference),
      ) {
    // The platform answers a hold the way it answers it in production: it
    // calls the delegate back, and the bloc learns of the change that way.
    _harness.callkeep.relayHeldToDelegate = true;
  }

  /// A bloc with [lines] lines, its session ready unless [sessionReady] is
  /// false.
  ///
  /// An outgoing call that is placed while the session is not ready waits
  /// for it, and that wait is a contract of its own. Ready means what the
  /// server makes it: the connection is up and the handshake brings the
  /// registration and the lines, so the bloc reaches the state by its own
  /// handlers, and the harness returns once it has.
  static Future<CallContractHarness> start({
    int lines = 2,
    bool sendPresenceSettings = false,
    bool conference = false,
    bool sessionReady = true,
  }) async {
    final harness = CallContractHarness._(
      lines: lines,
      sendPresenceSettings: sendPresenceSettings,
      conference: conference,
    );
    if (sessionReady) await harness.sessionBecomesReady();
    return harness;
  }

  final int _lines;

  final CallBlocHarness _harness;

  /// The bloc under test.
  CallBloc get bloc => _harness.bloc;

  /// The signaling the test can drive.
  FakeSignalingModule get signaling => _harness.signaling;

  /// The platform the test can read and hold.
  FakeCallkeep get callkeep => _harness.callkeep;

  /// The peer connection factory, for a test that looks at the connection.
  FakePeerConnectionFactory get peerFactory => _harness.peerFactory;

  /// The microphone the fake media builder hands out.
  FakeUserMediaBuilder get media => _harness.media;

  /// How often the bloc said a call ended.
  int get callsEnded => _harness.callsEnded;

  /// What the bloc told the app about the lines, in order: one entry per
  /// state change the bloc made.
  List<LinesState> get publishedLines => _harness.publishedLines;

  /// The side effects of the state changes, in the order they ran: the lines
  /// were published, a peer connection was disposed. A change runs them
  /// synchronously and outside the queues, so their order is behaviour.
  List<String> get sideEffectOrder => _harness.sideEffectOrder;

  Future<void> close() => _harness.close();

  /// Waits until [done] holds, or gives up after enough turns for the bloc to
  /// run everything one event wakes.
  ///
  /// The turns are pumped, never waited for: no real time passes, so a slow
  /// machine cannot let a deadline pass early or late.
  Future<void> settle(bool Function() done) => _harness.settle(done);

  /// Lets the work that is already running finish, whether or not the bloc has
  /// anything left to do.
  ///
  /// [settle] stops as soon as its condition holds, so a test that waits for
  /// the absence of something needs this: there is nothing to wait for, and
  /// the work in flight still has to be given its turns.
  Future<void> pump([int turns = 20]) async {
    for (var turn = 0; turn < turns; turn++) {
      await pumpEventQueue();
    }
  }

  /// The call the bloc holds, or null.
  ActiveCall? call(String callId) => bloc.state.retrieveActiveCall(callId);

  /// An incoming call arrives from the far end: a signaling offer with an
  /// SDP, on [line], for [callId].
  ///
  /// This is the flow of a real incoming call - the server's offer, the
  /// platform told about it, the call in the state - not a seeded one.
  Future<void> ringIncomingCall(
    String callId, {
    int line = 0,
    String caller = '100',
    String callee = '200',
    bool video = false,
  }) async {
    signaling.emit(
      IncomingCallEvent(
        line: line,
        callId: callId,
        caller: caller,
        callee: callee,
        jsep: video
            ? {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n'}
            : {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
    await settle(() => call(callId) != null);
  }

  /// The platform answers the incoming call [callId]: the same callback the
  /// operating system makes when the person taps answer.
  Future<bool> answerIncomingCall(String callId) async {
    final answered = bloc.performAnswerCall(callId);
    await settle(() => call(callId)?.processingStatus == CallProcessingStatus.incomingAnswering);
    return answered;
  }

  /// The far end accepts the incoming call: the signaling accepted event with
  /// the answer SDP.
  Future<void> acceptIncomingCall(String callId, {int line = 0}) async {
    signaling.emit(
      AcceptedEvent(
        line: line,
        callId: callId,
        jsep: {'type': 'answer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
    await settle(() => call(callId)?.processingStatus == CallProcessingStatus.connected);
  }

  /// An outgoing call is placed to [number]: the person taps the number, the
  /// platform is asked to place it, and the far end accepts it.
  ///
  /// The call id the platform was given is returned - the bloc generates it,
  /// so a test reads it rather than naming it.
  Future<String> placeOutgoingCall({String number = '200', bool video = false}) async {
    bloc.add(CallControlEvent.started(number: number, video: video));
    await settle(() => callkeep.starts.isNotEmpty);
    final callId = callkeep.starts.last.callId;
    await settle(() => call(callId) != null);
    return callId;
  }

  /// The far end accepts the outgoing call [callId]: the signaling accepted
  /// event with the answer SDP.
  Future<void> acceptOutgoingCall(String callId) async {
    signaling.emit(
      AcceptedEvent(
        line: call(callId)?.line ?? 0,
        callId: callId,
        jsep: {'type': 'answer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      ),
    );
    await settle(() => call(callId)?.processingStatus == CallProcessingStatus.connected);
  }

  /// A call that is up: it arrived, it was answered, the far end accepted it.
  Future<void> callUp(String callId, {int line = 0}) async {
    await ringIncomingCall(callId, line: line);
    await answerIncomingCall(callId);
    await acceptIncomingCall(callId, line: line);
  }

  /// The far end hangs the call up: the signaling hangup event.
  Future<void> hangupFromServer(String callId, {int code = 200, int line = 0}) async {
    signaling.emit(HangupEvent(line: line, callId: callId, code: code, reason: 'test'));
    await settle(() => call(callId) == null);
  }

  /// The person puts the call on hold or resumes it: the control the call
  /// screen offers, which the bloc turns into a request to the platform and
  /// then into a request to the server.
  Future<void> holdCall(String callId, {required bool onHold}) async {
    bloc.add(CallControlEvent.setHeld(callId, onHold));
    await settle(() => callkeep.held.any((it) => it.callId == callId && it.onHold == onHold));
  }

  /// The signaling session is up: the connection the client reports.
  Future<void> signalingConnected() async {
    signaling.emitLifecycle(SignalingConnected());
    await settle(() => bloc.state.callServiceState.signalingClientStatus == SignalingClientStatus.connect);
  }

  /// The signaling session went down: the disconnect the client reports.
  Future<void> signalingDisconnected({int code = 1000, String reason = 'test'}) async {
    signaling.emitLifecycle(
      SignalingDisconnected(
        code: code,
        reason: reason,
        knownCode: SignalingDisconnectCode.unmappedError,
        recommendedReconnectDelay: Duration.zero,
      ),
    );
    await settle(() => bloc.state.callServiceState.signalingClientStatus == SignalingClientStatus.disconnect);
  }

  /// The session is ready for an outgoing call: the connection is up and the
  /// account is registered.
  ///
  /// This is the flow the server drives: the client reports its connection and
  /// the registration the server accepted. A call that waits for the session
  /// goes on when it arrives.
  Future<void> sessionBecomesReady() async {
    await signalingConnected();
    _emitHandshake();
    await settle(
      () =>
          bloc.state.callServiceState.registration?.status == RegistrationStatus.registered &&
          bloc.state.linesCount > 0,
    );
  }

  /// The handshake the server sends once the session is up: the account is
  /// registered and the lines are there, all of them free.
  void _emitHandshake() {
    signaling.emitHandshake(
      StateHandshake(
        keepaliveInterval: const Duration(seconds: 30),
        timestamp: 0,
        registration: const Registration(status: RegistrationStatus.registered),
        lines: List<Line?>.filled(_lines, null),
        presenceInfos: const [],
        dialogInfos: const [],
        guestLine: null,
      ),
    );
  }

  /// A room stands: two calls are merged, and the mixer offers the room.
  ///
  /// The room owns a connection of its own, which the bloc has to release
  /// when it closes - after the handlers have stopped, or a teardown would
  /// race one that is still running.
  Future<void> roomUp({int room = 7}) async {
    await callUp('a');
    await callUp('b', line: 1);

    bloc.add(CallControlEvent.merged(['a', 'b']));
    await settle(() => signaling.requests.whereType<MergeRequest>().isNotEmpty);

    signaling.emit(
      ConferenceOfferEvent(
        room: room,
        jsep: const {'type': 'offer', 'sdp': contractOfferSdp},
        participants: const [
          ConferenceParticipant(line: 0, callId: 'a', muted: false),
          ConferenceParticipant(line: 1, callId: 'b', muted: false),
        ],
      ),
    );
    await settle(() => peerFactory.created.length >= 3);
  }

  /// The requests the bloc sent to the server, in order.
  List<Request> get requests => signaling.requests;
}

/// The offer and answer SDP the contract flows carry: a minimal audio
/// description, enough for the fake connection to accept.
const contractOfferSdp = 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n';
const contractAnswerSdp = 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n';

/// A gate the test releases when it wants the work in flight to go on.
///
/// The contract tests need work that does not finish until they say so: the
/// ordering of two things is only a fact when the first one is held. The gate
/// is the [Completer] the fake signaling waits for, so a test can hand it
/// over as is.
class HeldWork {
  final Completer<void> gate = Completer<void>();

  /// Whether the work is still held.
  bool get isHeld => !gate.isCompleted;

  /// Lets the work go on.
  void release() {
    if (!gate.isCompleted) gate.complete();
  }
}
