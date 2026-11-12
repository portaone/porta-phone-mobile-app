import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

// The far end re-INVITEs the call without an SDP: it asks for an offer
// instead of making one. Such an update is owed an answer like any other,
// and the answer to it is an offer of the client's own. The offer goes into
// the 200 OK of the re-INVITE, and the far end's answer comes back as an
// accepted event with an answer, which the bloc applies to the peer
// connection.

const _callId = 'a';

/// The far end's request for an offer: no SDP of its own.
const _offerRequest = UpdatingCallEvent(line: 0, callId: _callId, caller: '100', callee: '200');

/// The far end's answer to the offer the client made for the request.
const _answer = {'type': 'answer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};

/// The session as the server reports it: the update the far end asked for and
/// the offer of the client that answered it. The log is newest first.
final _handshakeWithOfferedUpdate = StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 1,
  registration: const Registration(status: RegistrationStatus.registered),
  lines: [
    Line(
      callId: _callId,
      callLogs: [
        CallRequestLog(
          timestamp: 11,
          callRequest: UpdateRequest(
            transaction: 't-1',
            line: 0,
            callId: _callId,
            jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          ),
        ),
        const CallEventLog(timestamp: 10, callEvent: _offerRequest),
        const CallEventLog(timestamp: 2, callEvent: AcceptedEvent(line: 0, callId: _callId)),
      ],
    ),
  ],
  presenceInfos: [],
  dialogInfos: [],
  guestLine: null,
);

/// The session as the server reports it after a loss: the update the far end
/// asked for, with nothing of the client after it.
final _handshakeWithOpenUpdate = StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 1,
  registration: const Registration(status: RegistrationStatus.registered),
  lines: [
    Line(
      callId: _callId,
      callLogs: [
        const CallEventLog(timestamp: 10, callEvent: _offerRequest),
        const CallEventLog(timestamp: 2, callEvent: AcceptedEvent(line: 0, callId: _callId)),
      ],
    ),
  ],
  presenceInfos: [],
  dialogInfos: [],
  guestLine: null,
);

List<UpdateRequest> _offers(CallBlocHarness harness) =>
    harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer').toList();

List<UpdateRequest> _answers(CallBlocHarness harness) =>
    harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'answer').toList();

/// The server's word that the offer was taken; the answer of the far end
/// comes later, as an accepted event.
Future<void> _confirmOffer(CallBlocHarness harness) async {
  final offer = _offers(harness).last;
  harness.signaling.emit(UpdatingEvent(line: 0, callId: _callId, transaction: offer.transaction));
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an update that asks for an offer is answered with an offer of the client\'s own', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    expect(_offers(harness), hasLength(1), reason: 'the far end asked for an offer');
    expect(_answers(harness), isEmpty, reason: 'there is nothing of the far end to answer');

    await _confirmOffer(harness);
  });

  test('the offer for the update is installed on the peer connection', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    expect(peer.localDescriptions.map((d) => d.type), ['offer']);
    expect(peer.remoteDescriptions, isEmpty, reason: 'the far end sent no offer of its own');

    await _confirmOffer(harness);
  });

  test('the offer for the update carries the constraints of the media policy', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    expect(peer.offerConstraints.single?['mandatory'], {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false});

    await _confirmOffer(harness);
  });

  test('the answer of the far end is applied to the offer of the client', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();
    await _confirmOffer(harness);

    // The offer of the client is installed, so the connection waits for its
    // answer, as on a real one.
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;

    // The call is still updating: the answer of the far end is on its way.
    expect(harness.bloc.state.retrieveActiveCall(_callId)?.updating, isTrue);

    harness.signaling.emit(AcceptedEvent(line: 0, callId: _callId, jsep: _answer));
    await pumpEventQueue();

    expect(peer.remoteDescriptions.map((d) => d.type), ['answer']);
    expect(harness.bloc.state.retrieveActiveCall(_callId)?.updating, isFalse);
  });

  test('an update that asks for an offer is not answered again by the handshake that reports it', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();
    await _confirmOffer(harness);

    // The handshake reports the update with the offer of the client after it:
    // the update is answered, so it is not handed over again.
    harness.signaling.emitHandshake(_handshakeWithOfferedUpdate);
    await pumpEventQueue();

    expect(_offers(harness), hasLength(1));
    expect(_answers(harness), isEmpty);
  });

  test('the call is not renegotiated while the update it owes an answer is open', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    // The offer is out and waits for the server's word; the update is open.
    expect(_offers(harness), hasLength(1));

    // A reconnect owes the call a renegotiation; it waits behind the update.
    harness.reconnect();
    await pumpEventQueue();

    expect(_offers(harness), hasLength(1), reason: 'the offer of the update is the one that is out');
  });

  test('the offer of the client for the update is sent again on the session that follows a loss', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();
    await _confirmOffer(harness);

    // The answer of the far end will not come on the next session, so the
    // offer goes out again on it.
    harness.reconnect();
    await pumpEventQueue();

    expect(_offers(harness), hasLength(2), reason: 'the offer of the update is replayed');
  });

  test('the offer of the client for an update it could not send is sent on the session that follows', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    // The socket goes down as the offer is handed over: it is installed on
    // the peer connection but never sent.
    harness.signaling.sendable = false;
    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();
    expect(_offers(harness), isEmpty, reason: 'nothing could be sent');
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;

    // The next session still owes the update and hands it over again.
    harness.signaling.sendable = true;
    harness.signaling.emitLifecycle(SignalingConnected());
    harness.signaling.emitHandshake(_handshakeWithOpenUpdate);
    await pumpEventQueue();

    expect(_offers(harness), hasLength(1), reason: 'the offer installed before is the one sent now');
    expect(peer.localDescriptions.where((d) => d.type == 'offer'), hasLength(1), reason: 'no second offer is made');

    await _confirmOffer(harness);
  });

  test('no offer is made for the update while the signaling is down', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    harness.signaling.connected = false;
    harness.signaling.emitLifecycle(SignalingDisconnecting());
    await pumpEventQueue();
    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    expect(peer.localDescriptions.where((d) => d.type == 'offer'), isEmpty);
  });

  test('the offer of the client for the update is sent again after the server refuses it', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    final offer = _offers(harness).single;
    harness.signaling.emit(
      CallErrorEvent(transaction: offer.transaction, line: 0, callId: _callId, code: 491, reason: 'Request Pending'),
    );
    await pumpEventQueue();

    expect(harness.bloc.state.retrieveActiveCall(_callId)?.updating, isFalse);
    expect(_offers(harness), hasLength(1), reason: 'the retry waits for its own delay');
  });

  test('an offer the server completes is settled as any offer of the client', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    final peer = harness.seedEstablishedCall(_callId);

    harness.signaling.emit(_offerRequest);
    await pumpEventQueue();

    // `updated` ends the exchange as it ends a renegotiation of the client:
    // the call is not left updating, and an answer that still comes is
    // applied.
    final offer = _offers(harness).single;
    harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offer.transaction));
    await pumpEventQueue();

    expect(harness.bloc.state.retrieveActiveCall(_callId)?.updating, isFalse);

    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    peer.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    harness.signaling.emit(AcceptedEvent(line: 0, callId: _callId, jsep: _answer));
    await pumpEventQueue();

    expect(peer.remoteDescriptions.map((d) => d.type), ['answer']);
    expect(harness.bloc.state.retrieveActiveCall(_callId)?.updating, isFalse);
  });
}
