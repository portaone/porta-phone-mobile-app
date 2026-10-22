import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// A request sent in the middle of a call that is lost with the signaling -
/// the socket closed under it, the client gave up on its keepalive (4502) and
/// terminated every transaction, or its reply never came - does not end the
/// call: the server still holds it. Any other failure, a local timeout
/// included, still ends it, and so does a lost answer to the far end's update.
///
/// The keepalive case is the one seen on real phones: the ICE restart's answer
/// arrived, then the client closed its session for a keepalive with no reply,
/// and the candidate request still queued behind it ended a call the server
/// held.

final _transient = <Object>[
  NotConnectedException('signaling disconnected'),
  const WebtritSignalingDisconnectedException(1),
  const WebtritSignalingTransactionTimeoutException(1, 'tx'),
  const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 4502, 'signaling keepalive timeout error'),
  TimeoutException('the reply was not received'),
];

final _candidate = RTCIceCandidate('candidate:1 1 udp 2122260223 192.168.0.11 49240 typ host', '0', 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() => h = CallBlocHarness(lines: 2));
  tearDown(() => h.close());

  /// An outgoing call up to its offer, on a peer connection the bloc made and
  /// wired itself, so the connection's own callbacks reach the bloc.
  Future<(ActiveCall, FakePeerConnection)> placeCall() async {
    h.seedSignalingReady();
    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty);
    final call = h.bloc.state.activeCalls.single;
    h.bloc.performStartCall(call.callId, call.handle, null, false);
    await h.settle(
      () => h.bloc.state.retrieveActiveCall(call.callId)?.processingStatus == CallProcessingStatus.outgoingOfferSent,
    );
    return (call, h.peerFactory.created.single);
  }

  /// The same call, answered by the far end.
  Future<(ActiveCall, FakePeerConnection)> callUp() async {
    final (call, peer) = await placeCall();
    h.signaling.emit(
      AcceptedEvent(line: call.line, callId: call.callId, jsep: const {'type': 'answer', 'sdp': 'v=0\r\n'}),
    );
    await h.settle(
      () => h.bloc.state.retrieveActiveCall(call.callId)?.processingStatus == CallProcessingStatus.connected,
    );
    expect(h.bloc.state.retrieveActiveCall(call.callId)?.processingStatus, CallProcessingStatus.connected);
    return (call, peer);
  }

  for (final (what, lose) in <(String, void Function(FakePeerConnection))>[
    ('a candidate', (peer) => peer.onIceCandidate!(_candidate)),
    ('the end of candidates', (peer) => peer.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateComplete)),
  ]) {
    group(what, () {
      for (final failure in _transient) {
        test('lost with $failure on a call that is up leaves the call up', () async {
          final (call, peer) = await callUp();
          h.signaling.failure = failure;

          lose(peer);
          await h.settle(() => h.signaling.requests.whereType<IceTrickleRequest>().isNotEmpty);
          await pumpEventQueue();

          expect(h.signaling.requests.whereType<IceTrickleRequest>(), hasLength(1));
          expect(h.bloc.state.retrieveActiveCall(call.callId), isNotNull);
          expect(h.callkeep.ended, isEmpty);
          expect(h.errors.errors, isEmpty);
        });
      }

      // A call still being set up is not renegotiated on reconnect, so nothing
      // would send the candidate again: only the two losses always tolerated
      // here keep it.
      for (final failure in [
        NotConnectedException('down'),
        const WebtritSignalingTransactionTimeoutException(1, 'tx'),
      ]) {
        test('lost with $failure while the call is set up leaves it up', () async {
          final (call, peer) = await placeCall();
          h.signaling.failure = failure;

          lose(peer);
          await h.settle(() => h.signaling.requests.whereType<IceTrickleRequest>().isNotEmpty);
          await pumpEventQueue();

          expect(h.bloc.state.retrieveActiveCall(call.callId), isNotNull);
          expect(h.errors.errors, isEmpty);
        });
      }

      for (final failure in [
        const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 4502, 'keepalive'),
        StateError('a fault in this client'),
      ]) {
        test('$failure while the call is set up ends it', () async {
          final (call, peer) = await placeCall();
          h.signaling.failure = failure;

          lose(peer);
          await h.settle(() => h.bloc.state.retrieveActiveCall(call.callId) == null);

          expect(h.bloc.state.retrieveActiveCall(call.callId), isNull);
          expect(h.errors.errors, [failure]);
        });
      }

      test('any other failure on a call that is up still ends it', () async {
        final (call, peer) = await callUp();
        final failure = StateError('a fault in this client');
        h.signaling.failure = failure;

        lose(peer);
        await h.settle(() => h.bloc.state.retrieveActiveCall(call.callId) == null);

        expect(h.bloc.state.retrieveActiveCall(call.callId), isNull);
        expect(h.errors.errors, [failure]);
      });
    });
  }

  group("the answer to the far end's update", () {
    // Kept as it was: a lost answer still ends the call. The media server waits
    // for that answer with no timer of its own and holds back any offer of this
    // side until it comes, so a call kept up would hang without audio.
    for (final failure in _transient) {
      test('lost with $failure still ends the call', () async {
        h.seedEstablishedCall('call');
        h.signaling.failure = failure;

        h.signaling.emit(
          const UpdatingCallEvent(
            line: 0,
            callId: 'call',
            callee: '200',
            caller: '100',
            jsep: {'type': 'offer', 'sdp': 'v=0\r\n'},
          ),
        );
        await h.settle(() => h.bloc.state.retrieveActiveCall('call') == null);

        expect(h.bloc.state.retrieveActiveCall('call'), isNull);
      });
    }
  });
}
