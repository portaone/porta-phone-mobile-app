import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import '../bloc/call_bloc_harness.dart';

/// Records what the session sends and answers each request as told.
class _Signaling {
  final List<Request> sent = [];
  final Map<Type, ConferenceRequestResult> answers = {};

  /// Holds the acknowledgement of a request of this type until completed.
  final Map<Type, Completer<void>> gates = {};

  Future<ConferenceRequestResult> send(Request request) async {
    sent.add(request);
    await gates[request.runtimeType]?.future;
    return answers[request.runtimeType] ?? const ConferenceRequestResult.taken();
  }

  List<T> of<T>() => sent.whereType<T>().toList();
}

class _Transceiver extends Fake implements RTCRtpTransceiver {
  _Transceiver(this.mid);

  @override
  final String mid;
}

const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n'};
const _answer = {'type': 'answer', 'sdp': 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n'};

void main() {
  late FakePeerConnectionFactory factory;
  late FakeUserMediaBuilder media;
  late _Signaling signaling;
  late List<List<ConferenceVideoFeed>> reported;
  late ConferenceVideoSession session;

  setUp(() {
    factory = FakePeerConnectionFactory();
    media = FakeUserMediaBuilder();
    signaling = _Signaling();
    reported = [];
    session = ConferenceVideoSession(
      factory: factory,
      userMediaBuilder: media,
      send: signaling.send,
      onFeedsChanged: reported.add,
      retryDelay: Duration.zero,
    );
  });

  group('subscriber', () {
    test('every offer of a subscription is answered on one connection', () async {
      expect(await session.subscribe(), isTrue);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(1));

      await session.handleOffer(_offer);
      await session.handleOffer(_offer);

      expect(factory.created, hasLength(1), reason: 'a later offer renegotiates the same connection');
      expect(factory.created.single.remoteDescriptions, hasLength(2));
      expect(signaling.of<ConferenceVideoAnswerRequest>(), hasLength(2));
      expect(signaling.of<ConferenceVideoAnswerRequest>().first.jsep['type'], 'answer');
    });

    test('an offer nobody subscribed for is not answered', () async {
      await session.handleOffer(_offer);

      expect(factory.created, isEmpty);
      expect(signaling.of<ConferenceVideoAnswerRequest>(), isEmpty);
    });

    test('subscribing again starts from a new connection', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      final first = factory.created.single;

      await session.subscribe();
      await session.handleOffer(_offer);

      expect(first.closes, 1, reason: 'Core remakes the subscription, the old connection is of no use');
      expect(factory.created, hasLength(2));
    });

    test('an unasked offer after the connection failed gets a new connection', () async {
      // Core does that after Janus hung the subscriber up (protocol 18.2).
      await session.subscribe();
      await session.handleOffer(_offer);
      factory.created.single.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;

      await session.handleOffer(_offer);

      expect(factory.created, hasLength(2));
      expect(session.isSubscribed, isTrue, reason: 'the new connection still belongs to the subscription');
      await session.handleOffer(_offer);
      expect(factory.created, hasLength(2));
    });

    test('a candidate ahead of the offer waits for it', () async {
      await session.subscribe();
      await session.handleRemoteCandidate(ConferenceVideoPc.subscriber, {
        'candidate': 'candidate:1 1 udp 1 10.0.0.1 9 typ host',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });
      expect(factory.created, isEmpty);

      await session.handleOffer(_offer);

      expect(factory.created.single.candidates, hasLength(1));
    });

    test('local candidates wait for the answer to be taken, and go tagged with the connection', () async {
      signaling.answers[ConferenceVideoAnswerRequest] = const ConferenceRequestResult.notSent();
      await session.subscribe();
      // Not acknowledged: subscribe's ack is reset by the new connection.
      await session.handleOffer(_offer);
      final peerConnection = factory.created.single;
      peerConnection.onIceCandidate!(RTCIceCandidate('candidate:1', '0', 0));
      peerConnection.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateComplete);
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), isEmpty, reason: 'Core would answer no_peer_connection');

      signaling.answers.remove(ConferenceVideoAnswerRequest);
      await session.handleOffer(_offer);

      final trickles = signaling.of<ConferenceVideoIceTrickleRequest>();
      expect(trickles.map((t) => t.pc), everyElement(ConferenceVideoPc.subscriber));
      expect(trickles.map((t) => t.candidate?['candidate']), ['candidate:1', null], reason: 'null ends the gathering');
    });

    test('a failed subscriber is closed and subscribed again', () async {
      await session.subscribe();
      await session.handleOffer(_offer);

      await session.handleFailed(ConferenceVideoPc.subscriber, code: 500);

      expect(factory.created.single.closes, 1);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));
      await session.handleOffer(_offer);
      expect(factory.created, hasLength(2));
    });

    test('a restart asks the room and answers on the same connection', () async {
      await session.subscribe();
      await session.handleOffer(_offer);

      expect(await session.restartSubscriber(), isTrue);
      await session.handleOffer(_offer);

      expect(signaling.of<ConferenceVideoRestartRequest>(), hasLength(1));
      expect(factory.created, hasLength(1));
    });
  });

  group('feeds', () {
    test('a received stream is named by the participant the room says it carries', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      final stream = FakeMediaStream(
        'remote-0',
        tracks: [FakeMediaStreamTrack(kind: 'video', id: 'v0')],
      );
      factory.created.single.onTrack!(
        RTCTrackEvent(
          track: FakeMediaStreamTrack(kind: 'video', id: 'v0'),
          streams: [stream],
          transceiver: _Transceiver('0'),
        ),
      );
      expect(reported.last, isEmpty, reason: 'the room has not said whose it is yet');

      await session.handleUpdated(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '0', feed: 2, kind: ConferenceVideoKind.camera)],
        ),
      );

      expect(reported.last.single.feed, 2);
      expect(reported.last.single.kind, ConferenceVideoKind.camera);
      expect(reported.last.single.stream, same(stream));
    });

    test('closing the subscriber takes its streams away', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.handleUpdated(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '0', feed: 2, kind: ConferenceVideoKind.camera)],
        ),
      );
      factory.created.single.onTrack!(
        RTCTrackEvent(
          track: FakeMediaStreamTrack(kind: 'video', id: 'v0'),
          streams: [FakeMediaStream('remote-0', tracks: const [])],
          transceiver: _Transceiver('0'),
        ),
      );
      expect(reported.last, hasLength(1));

      await session.teardown();

      expect(reported.last, isEmpty);
    });
  });

  group('publisher', () {
    test('the camera goes out alone, named for Core, and its candidates wait for the publish', () async {
      final published = session.publish();
      final peerConnection = await _created(factory);
      expect((await published).published, isTrue);

      expect(peerConnection.addedTracks.map((track) => track.kind), ['video'], reason: 'audio stays in the mixer');
      expect(peerConnection.fakeTransceivers.single.direction, TransceiverDirection.SendOnly);
      final publish = signaling.of<ConferenceVideoPublishRequest>().single;
      expect(publish.jsep['type'], 'offer');
      expect(publish.descriptions, const [ConferenceVideoDescription(mid: '0', kind: ConferenceVideoKind.camera)]);
      expect(session.isPublishing, isTrue);
    });

    test('candidates gathered before the publish is taken wait for it', () async {
      final ack = Completer<void>();
      signaling.gates[ConferenceVideoPublishRequest] = ack;
      final published = session.publish();
      while (signaling.of<ConferenceVideoPublishRequest>().isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      factory.created.single.onIceCandidate!(RTCIceCandidate('candidate:p', '0', 0));
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), isEmpty, reason: 'Core would answer no_peer_connection');

      ack.complete();
      await published;

      final trickle = signaling.of<ConferenceVideoIceTrickleRequest>().single;
      expect(trickle.pc, ConferenceVideoPc.publisher);
      expect(trickle.candidate?['candidate'], 'candidate:p');
    });

    test('the answer is applied to the publisher', () async {
      await session.publish();
      await session.handlePublisherAnswer(_answer);

      expect(factory.created.single.remoteDescriptions.single.type, 'answer');
    });

    test('a refused publication gives the camera back', () async {
      signaling.answers[ConferenceVideoPublishRequest] = const ConferenceRequestResult.refused('video_disabled');

      expect(await session.publish(), isA<CameraRefused>().having((it) => it.reason, 'reason', 'video_disabled'));

      expect(session.isPublishing, isFalse);
      expect(factory.created.single.closes, 1);
      expect(media.released, hasLength(1));
    });

    test('the camera a call turned off is turned on for the room', () async {
      // The track is the one a video call of this client sends.
      media.cameraEnabled = false;

      await session.publish();

      expect(session.cameraTrack?.enabled, isTrue);
    });

    test('unpublish is sent before the connection closes', () async {
      await session.publish();
      final peerConnection = factory.created.single;
      final order = <String>[];
      peerConnection.order = order;

      await session.unpublish();

      expect(signaling.sent.last, isA<ConferenceVideoUnpublishRequest>());
      expect(order, ['peer connection closed']);
      expect(media.released, hasLength(1));
      expect(session.isPublishing, isFalse);
    });

    test('an ICE restart renegotiates the same publication', () async {
      await session.publish();

      expect(await session.restartPublisher(), isA<CameraPublished>());

      expect(factory.created, hasLength(1));
      expect(factory.created.single.offerConstraints.last, {'iceRestart': true});
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
      expect(signaling.of<ConferenceVideoPublishRequest>().last.descriptions, isNotEmpty);
    });

    test('a failed publisher is published once more, then left unpublished', () async {
      await session.publish();

      await session.handleFailed(ConferenceVideoPc.publisher, code: 432);
      expect(factory.created, hasLength(2), reason: 'one retry on a new connection');
      expect(session.isPublishing, isTrue);

      await session.handleFailed(ConferenceVideoPc.publisher, code: 432);
      expect(factory.created, hasLength(2), reason: 'the room refused again');
      expect(session.isPublishing, isFalse);
      expect(media.released, hasLength(2), reason: 'every camera taken is given back');
    });

    test('an answer resets the retries', () async {
      await session.publish();
      await session.handleFailed(ConferenceVideoPc.publisher);
      await session.handlePublisherAnswer(_answer);

      await session.handleFailed(ConferenceVideoPc.publisher);

      expect(factory.created, hasLength(3));
      expect(session.isPublishing, isTrue);
    });
  });

  group('the session', () {
    test('leave tells the room and closes both connections', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.publish();

      await session.leave();

      expect(signaling.sent.whereType<ConferenceVideoLeaveRequest>(), hasLength(1));
      expect(factory.created.map((pc) => pc.closes), [1, 1]);
      expect(media.released, hasLength(1));
      expect(media.microphoneLive, isFalse, reason: 'the camera stream held the shared microphone too');
    });

    test('a teardown tells the room nothing', () async {
      await session.subscribe();
      await session.publish();

      await session.teardown();

      expect(signaling.sent.whereType<ConferenceVideoLeaveRequest>(), isEmpty);
      expect(session.isSubscribed, isFalse);
      expect(session.isPublishing, isFalse);
    });

    test('after a signalling reconnect the subscription is remade and the publisher restarts ICE', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.publish();

      await session.reconnected();

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));
      expect(factory.created.first.closes, 1, reason: 'the old subscriber goes, the next offer gets a new one');
      final publishes = signaling.of<ConferenceVideoPublishRequest>();
      expect(publishes, hasLength(2));
      expect(factory.created[1].offerConstraints.last, {'iceRestart': true});
    });

    test('a refused publication of an invited far end closes the publisher for good', () async {
      // Protocol section 19: the host's controller refused it after this
      // client's own had taken it.
      await session.publish();

      await session.handleRefused('conference_video_publish', reason: 'not_in_conference');

      expect(session.isPublishing, isFalse);
      expect(factory.created.single.closes, 1);
      expect(media.released, hasLength(1));
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(1), reason: 'not asked for again');
    });

    test('an answer refused for no subscription subscribes again', () async {
      // Protocol section 10: not_subscribed - send conference_video_subscribe
      // first. The subscription goes on, on a new connection.
      await session.subscribe();
      await session.handleOffer(_offer);

      await session.handleRefused('conference_video_answer', reason: 'not_subscribed');
      await _settled();

      expect(session.isSubscribed, isTrue);
      expect(factory.created.single.closes, 1);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));
      await session.handleOffer(_offer);
      expect(factory.created, hasLength(2), reason: 'the new subscription gets a new connection');
    });

    test('an invited far end no longer in the conference ends the subscription', () async {
      await session.subscribe();
      await session.handleOffer(_offer);

      await session.handleRefused('conference_video_answer', reason: 'not_in_conference');
      await _settled();

      expect(session.isSubscribed, isFalse);
      expect(factory.created.single.closes, 1);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(1), reason: 'not asked for again');
      await session.handleOffer(_offer);
      expect(factory.created, hasLength(1), reason: 'an offer after the refusal is not answered');
    });

    test('a publication the room could not take yet is asked for once more, later', () async {
      // attach_failed: Janus refused a VideoRoom handle - retry later.
      await session.publish();

      await session.handleRefused('conference_video_publish', reason: 'attach_failed');
      await _settled();
      expect(session.isPublishing, isTrue);
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
      expect(factory.created, hasLength(2), reason: 'on a new connection');

      await session.handleRefused('conference_video_publish', reason: 'attach_failed');
      await _settled();
      expect(session.isPublishing, isFalse, reason: 'once, not for ever');
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
    });

    test('a retry waiting for later is dropped when the video is left', () async {
      session = ConferenceVideoSession(
        factory: factory,
        userMediaBuilder: media,
        send: signaling.send,
        onFeedsChanged: reported.add,
        retryDelay: const Duration(milliseconds: 20),
      );
      signaling.answers[ConferenceVideoSubscribeRequest] = const ConferenceRequestResult.refused('attach_failed');
      await session.subscribe();
      await session.leave();

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(1));
    });

    test('a refusal of a request of neither connection closes nothing', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.publish();

      await session.handleRefused('conference_video_leave', reason: 'not_in_conference');

      expect(session.isSubscribed, isTrue);
      expect(session.isPublishing, isTrue);
      expect(factory.created.map((pc) => pc.closes), [0, 0]);
    });

    test('an offer after leaving is not answered', () async {
      await session.subscribe();
      await session.leave();

      await session.handleOffer(_offer);

      expect(factory.created, isEmpty);
    });
  });

  group('what the owner asks, in order', () {
    test('leaving right after subscribing leaves no subscription with Core', () async {
      // The subscribe is still queued when the leave comes: it must not reach
      // Core after the leave, and the room is told.
      final subscribed = session.subscribe();
      final left = session.leave();
      await Future.wait([subscribed, left]);

      final kinds = signaling.sent.map((r) => r.runtimeType).toList();
      expect(kinds.last, ConferenceVideoLeaveRequest);
      expect(kinds.skipWhile((k) => k != ConferenceVideoLeaveRequest).skip(1), isEmpty);
      expect(session.isSubscribed, isFalse);
    });

    test('a reconnect after leaving does not subscribe again', () async {
      await session.subscribe();
      final left = session.leave();
      await session.reconnected();
      await left;

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(session.isSubscribed, isFalse);
    });
  });

  group('requests that went unanswered', () {
    test('a subscribe that went unanswered is asked once more', () async {
      // It may have been taken; a subscribe remakes the subscription anyway.
      signaling.answers[ConferenceVideoSubscribeRequest] = const ConferenceRequestResult.unanswered();

      expect(await session.subscribe(), isFalse);

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));
      expect(session.isSubscribed, isTrue, reason: 'still wanted: an offer is answered, a reconnect asks again');
      signaling.answers.remove(ConferenceVideoSubscribeRequest);
      await session.handleOffer(_offer);
      expect(signaling.of<ConferenceVideoAnswerRequest>(), hasLength(1));
    });

    test('a first publication that went unanswered twice is undone, not left with Core', () async {
      signaling.answers[ConferenceVideoPublishRequest] = const ConferenceRequestResult.unanswered();

      expect(await session.publish(), isA<CameraNotPublished>());

      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
      expect(signaling.sent.last, isA<ConferenceVideoUnpublishRequest>());
      expect(session.isPublishing, isFalse);
      expect(factory.created.single.closes, 1);
      expect(media.released, hasLength(1));
    });

    test('a publication the session could not send waits for the reconnect', () async {
      signaling.answers[ConferenceVideoPublishRequest] = const ConferenceRequestResult.notSent();
      expect(await session.publish(), isA<CameraNotPublished>());
      expect(session.isPublishing, isTrue);
      expect(factory.created.single.closes, 1);

      signaling.answers.remove(ConferenceVideoPublishRequest);
      await session.reconnected();

      expect(factory.created, hasLength(2), reason: 'published again on a new connection');
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
    });
  });

  group('candidates', () {
    test('the waiting candidates go out at once, ahead of any gathered after', () async {
      signaling.gates[ConferenceVideoPublishRequest] = Completer<void>();
      final published = session.publish();
      final peerConnection = await _created(factory);
      await _settled();
      peerConnection.onIceCandidate!(RTCIceCandidate('candidate:1', '0', 0));
      peerConnection.onIceCandidate!(RTCIceCandidate('candidate:2', '0', 0));
      // The trickles' acknowledgements take their time: the flush must not
      // wait for them.
      signaling.gates[ConferenceVideoIceTrickleRequest] = Completer<void>();

      signaling.gates[ConferenceVideoPublishRequest]!.complete();
      await published;
      peerConnection.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateComplete);

      final candidates = signaling.of<ConferenceVideoIceTrickleRequest>().map((t) => t.candidate?['candidate']);
      expect(candidates, ['candidate:1', 'candidate:2', null]);
      signaling.gates[ConferenceVideoIceTrickleRequest]!.complete();
    });

    test("a restart's candidates wait for its offer", () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      final peerConnection = factory.created.single;

      await session.restartSubscriber();
      await session.handleRemoteCandidate(ConferenceVideoPc.subscriber, {
        'candidate': 'candidate:9 1 udp 1 10.0.0.9 9 typ host',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });
      expect(peerConnection.candidates, isEmpty, reason: 'it belongs to the next ICE generation');

      await session.handleOffer(_offer);
      expect(peerConnection.candidates, hasLength(1));
    });
  });

  group('the camera', () {
    test('a call that had the camera off gets it back off', () async {
      media.cameraEnabled = false;
      await session.publish();
      final track = session.cameraTrack!;
      expect(track.enabled, isTrue);

      await session.unpublish();

      expect(track.enabled, isFalse);
    });

    test('publishing again renegotiates the same publication', () async {
      await session.publish();

      await session.publish();

      expect(factory.created, hasLength(1));
      expect(signaling.of<ConferenceVideoPublishRequest>(), hasLength(2));
      expect(signaling.of<ConferenceVideoUnpublishRequest>(), isEmpty);
    });

    test('a publication made again after a failure keeps the camera asked for', () async {
      await session.publish(frontCamera: false);

      await session.handleFailed(ConferenceVideoPc.publisher);

      expect(media.frontCameras, [false, false]);
    });

    test('a fresh publication gets its retry again', () async {
      await session.publish();
      await session.handleFailed(ConferenceVideoPc.publisher);
      await session.handleFailed(ConferenceVideoPc.publisher);
      expect(session.isPublishing, isFalse);

      await session.publish();
      await session.handleFailed(ConferenceVideoPc.publisher);

      expect(session.isPublishing, isTrue, reason: 'retried once more');
    });
  });

  group('a new subscription', () {
    String offerOfSession(String id) => 'v=0\r\no=- $id 2 IN IP4 127.0.0.1\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n';

    test('an offer of a new session gets a new connection while the old one still looks up', () async {
      // Core sends it unasked after Janus hung the subscriber up; the old
      // connection's state tells only later.
      await session.subscribe();
      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('111')});

      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('111')});
      expect(factory.created, hasLength(1), reason: 'the same session renegotiates');

      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('222')});
      expect(factory.created, hasLength(2));
      expect(factory.created.first.closes, 1);
    });

    test('a subscriber the room keeps failing is subscribed once more, then left', () async {
      await session.subscribe();
      await session.handleOffer(_offer);

      await session.handleFailed(ConferenceVideoPc.subscriber);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));
      await session.handleFailed(ConferenceVideoPc.subscriber);

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2), reason: 'no loop');
      expect(session.isSubscribed, isFalse);
    });
  });

  group('an ICE restart', () {
    RTCIceCandidate candidate(String id) => RTCIceCandidate('candidate:$id', '0', 0);

    test("the publisher's new candidates wait for the publish that carries the restart", () async {
      await session.publish();
      await session.handlePublisherAnswer(_answer);
      final peerConnection = factory.created.single;
      signaling.gates[ConferenceVideoPublishRequest] = Completer<void>();

      final restarted = session.restartPublisher();
      await _settled();
      peerConnection.onIceCandidate!(candidate('new'));
      expect(
        signaling.of<ConferenceVideoIceTrickleRequest>(),
        isEmpty,
        reason: 'Janus still holds the old credentials',
      );

      signaling.gates[ConferenceVideoPublishRequest]!.complete();
      await restarted;
      expect(signaling.of<ConferenceVideoIceTrickleRequest>().single.candidate?['candidate'], 'candidate:new');
    });

    test("the subscriber's new candidates wait for the answer to the restart's offer", () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      final peerConnection = factory.created.single;

      await session.restartSubscriber();
      peerConnection.onIceCandidate!(candidate('new'));
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), isEmpty);

      await session.handleOffer(_offer);
      expect(signaling.of<ConferenceVideoIceTrickleRequest>().single.candidate?['candidate'], 'candidate:new');
    });

    test("the restart's offer is answered on the same connection, failed ICE and all", () async {
      // The restart is the remedy for the failure (protocol section 18.7).
      await session.subscribe();
      await session.handleOffer(_offer);
      factory.created.single.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;

      await session.restartSubscriber();
      await session.handleOffer(_offer);

      expect(factory.created, hasLength(1));
      expect(factory.created.single.closes, 0);
    });

    test('a refused restart of the publication ends it, as a refused first one does', () async {
      await session.publish();
      signaling.answers[ConferenceVideoPublishRequest] = const ConferenceRequestResult.refused('not_in_conference');

      expect(
        await session.restartPublisher(),
        isA<CameraRefused>().having((it) => it.reason, 'reason', 'not_in_conference'),
      );

      expect(session.isPublishing, isFalse);
      expect(factory.created.single.closes, 1);
      expect(media.released, hasLength(1));
    });
  });

  group('answers', () {
    test('an answer that went unanswered lets the candidates go all the same', () async {
      signaling.answers[ConferenceVideoAnswerRequest] = const ConferenceRequestResult.unanswered();
      await session.subscribe();
      await session.handleOffer(_offer);

      factory.created.single.onIceCandidate!(RTCIceCandidate('candidate:1', '0', 0));

      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), hasLength(1));
    });

    test('a second answer to one publication is ignored', () async {
      // A publish sent twice after going unanswered may be answered twice.
      await session.publish();

      await session.handlePublisherAnswer(_answer);
      await session.handlePublisherAnswer(_answer);

      expect(factory.created.single.remoteDescriptions, hasLength(1));
    });

    test('publishing over a spent publisher lets go of the old publication first', () async {
      await session.publish();
      factory.created.single.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;

      await session.publish();

      final kinds = signaling.sent.map((r) => r.runtimeType).toList();
      expect(kinds, [ConferenceVideoPublishRequest, ConferenceVideoUnpublishRequest, ConferenceVideoPublishRequest]);
      expect(factory.created, hasLength(2));
    });

    test('a camera that cannot be opened says so, and nothing is published', () async {
      media.buildError = StateError('camera in use');

      expect(await session.publish(), isA<CameraUnavailable>());

      expect(session.isPublishing, isFalse);
      expect(signaling.sent, isEmpty);
    });

    test('an offer the platform cannot make gives the camera back', () async {
      factory.offerError = StateError('no codecs');

      expect(await session.publish(), isA<CameraNotPublished>());

      expect(session.isPublishing, isFalse);
      expect(factory.created.single.closes, 1);
      expect(media.released, hasLength(1));
    });
  });

  group('an invited far end', () {
    test('an acknowledged answer does not earn another retry: a connected subscriber does', () async {
      // Its own controller acknowledges every answer, ahead of the host's.
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.handleRefused('conference_video_answer', reason: 'not_subscribed');
      await _settled();
      await session.handleOffer(_offer);
      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2));

      await session.handleRefused('conference_video_answer', reason: 'not_subscribed');
      await _settled();

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(2), reason: 'no loop');
      expect(session.isSubscribed, isFalse);
    });

    test('a subscriber that connected is retried again when refused later', () async {
      await session.subscribe();
      await session.handleOffer(_offer);
      await session.handleRefused('conference_video_answer', reason: 'not_subscribed');
      await _settled();
      await session.handleOffer(_offer);
      factory.created.last.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateConnected);

      await session.handleRefused('conference_video_answer', reason: 'not_subscribed');
      await _settled();

      expect(signaling.of<ConferenceVideoSubscribeRequest>(), hasLength(3));
      expect(session.isSubscribed, isTrue);
    });

    test('candidates refused ahead of the connection are sent once more when it is there', () async {
      await session.publish();
      factory.created.single.onIceCandidate!(RTCIceCandidate('candidate:1', '0', 0));
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), hasLength(1));

      await session.handleRefused('conference_video_ice_trickle', reason: 'no_peer_connection');
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), hasLength(1), reason: 'not before the answer');

      await session.handlePublisherAnswer(_answer);
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), hasLength(2));

      await session.handleRefused('conference_video_ice_trickle', reason: 'no_peer_connection');
      expect(signaling.of<ConferenceVideoIceTrickleRequest>(), hasLength(2), reason: 'once per connection');
    });
  });

  group('names and the shared camera', () {
    String offerOfSession(String id) => 'v=0\r\no=- $id 2 IN IP4 127.0.0.1\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n';

    void track(FakePeerConnection peerConnection) => peerConnection.onTrack!(
      RTCTrackEvent(
        track: FakeMediaStreamTrack(kind: 'video', id: 'v0'),
        streams: [
          FakeMediaStream(
            'remote',
            tracks: [FakeMediaStreamTrack(kind: 'video', id: 'v0')],
          ),
        ],
        transceiver: _Transceiver('0'),
      ),
    );

    test("a new subscription's streams are not named by the old one's list", () async {
      await session.subscribe();
      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('111')});
      await session.handleUpdated(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '0', feed: 2, kind: ConferenceVideoKind.camera)],
        ),
      );
      track(factory.created.single);
      expect(reported.last.single.feed, 2);

      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('222')});
      track(factory.created.last);

      expect(reported.last, isEmpty, reason: 'mid 0 of the new subscription may be somebody else');
    });

    test("a new subscription's list that arrives while its offer is being taken names its streams", () async {
      // Core sends the offer of a new subscription and its list 9 ms apart;
      // the list is taken after the offer, not before it, so the offer does
      // not drop the names the list has just given.
      await session.subscribe();
      await session.handleOffer({'type': 'offer', 'sdp': offerOfSession('111')});
      await session.handleUpdated(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '1', feed: 3, kind: ConferenceVideoKind.camera)],
        ),
      );

      final offer = session.handleOffer({'type': 'offer', 'sdp': offerOfSession('222')});
      final updated = session.handleUpdated(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '0', feed: 3, kind: ConferenceVideoKind.camera)],
        ),
      );
      await offer;
      await updated;
      track(factory.created.last);

      expect(reported.last.single.feed, 3);
    });

    test('the camera goes back as the calls want it now, not as the room found it', () async {
      // The call turned its camera on while the room held the track.
      session = ConferenceVideoSession(
        factory: factory,
        userMediaBuilder: media,
        send: signaling.send,
        onFeedsChanged: reported.add,
        callsWantCamera: () => true,
      );
      media.cameraEnabled = false;
      await session.publish();
      final cameraTrack = session.cameraTrack!;

      await session.unpublish();

      expect(cameraTrack.enabled, isTrue);
    });
  });
}

/// Lets queued operations and zero-delay retries run.
Future<void> _settled() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// The next connection the factory makes.
Future<FakePeerConnection> _created(FakePeerConnectionFactory factory) async {
  final before = factory.created.length;
  while (factory.created.length == before) {
    await Future<void>.delayed(Duration.zero);
  }
  return factory.created.last;
}
