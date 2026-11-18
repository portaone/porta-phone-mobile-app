import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc_harness.dart';

/// The room's video as `CallBloc` runs it: when the session is asked for the
/// video and the camera, what a reconnect, a refusal and the background do to
/// it, and what reaches the state. The session's own protocol is in
/// conference_video_session_test.dart.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};
const _videoOffer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 2 IN IP4 127.0.0.1\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\n'};

ConferenceParticipant _participant(String callId, int line) => ConferenceParticipant(line: line, callId: callId);

CallBlocHarness _harness({UserMediaBuilder? media}) => CallBlocHarness(
  userMediaBuilder: media,
  lines: 3,
  capabilities: const CallCapabilitiesConfig(
    isConferenceEnabled: true,
    isConferenceVideoEnabled: true,
    isVideoCallEnabled: true,
  ),
);

/// Room 7 of legs a and b, the mixer's offer answered: the host is in.
Future<void> _roomUp(CallBlocHarness h, {bool videoLeg = false}) async {
  h.seedEstablishedCall('a', line: 0, video: videoLeg);
  h.seedEstablishedCall('b', line: 1);
  h.bloc.add(const CallControlEvent.merged(['a', 'b']));
  await pumpEventQueue();
  h.signaling.emit(
    ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
  );
  await pumpEventQueue();
}

StateHandshake _handshakeWithRoom() => StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 0,
  registration: const Registration(status: RegistrationStatus.registered),
  lines: [
    Line(
      callId: 'a',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 0, callId: 'a'))],
    ),
    Line(
      callId: 'b',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 1, callId: 'b'))],
    ),
  ],
  presenceInfos: const [],
  dialogInfos: const [],
  guestLine: null,
  conference: ConferenceInfo(room: 7, participants: [_participant('a', 0), _participant('b', 1)]),
);

Object? Function(Request) _refuse<T extends Request>(String reason) =>
    (request) => request is T ? SignalingErrorException(1, 0, reason) : null;

class _Transceiver extends Fake implements RTCRtpTransceiver {
  _Transceiver(this.mid);

  @override
  final String mid;
}

/// A device whose camera cannot be opened.
class _NoCamera extends FakeUserMediaBuilder {
  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) {
    if (video) throw StateError('camera permission denied');
    return super.build(video: video, frontCamera: frontCamera, allowAudioFallback: allowAudioFallback);
  }
}

void main() {
  late CallBlocHarness h;

  setUp(() => h = _harness());
  tearDown(() => h.close());

  List<T> sent<T>() => h.signaling.requests.whereType<T>().toList();

  group('the host', () {
    test('asks for the room\'s video once in the room, and sends no camera for audio calls', () async {
      await _roomUp(h);

      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(sent<ConferenceVideoPublishRequest>(), isEmpty);
    });

    test('sends his camera when one of the merged calls was a video call', () async {
      await _roomUp(h, videoLeg: true);

      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1));
    });

    test('the cameras the room sends reach the state, by participant', () async {
      await _roomUp(h);
      h.signaling.emit(const ConferenceVideoOfferEvent(jsep: _videoOffer));
      await pumpEventQueue();
      final subscriber = h.peerFactory.created.last;
      final stream = FakeMediaStream(
        'remote',
        tracks: [FakeMediaStreamTrack(kind: 'video', id: 'v0')],
      );
      subscriber.onTrack!(
        RTCTrackEvent(
          track: FakeMediaStreamTrack(kind: 'video', id: 'v0'),
          streams: [stream],
          transceiver: _Transceiver('0'),
        ),
      );
      h.signaling.emit(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '0', feed: 2, kind: ConferenceVideoKind.camera)],
        ),
      );
      await pumpEventQueue();

      expect(h.bloc.state.conference.videoOfLine(0), same(stream));
      expect(h.bloc.state.conference.hasVideo, isTrue);
    });

    test('a signalling reconnect with the room standing remakes its video', () async {
      // Events sent while the socket was down are lost and the video is not
      // in the handshake (protocol section 18.7).
      await _roomUp(h, videoLeg: true);
      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(1));

      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(2));
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(2), reason: 'the publisher restarts ICE');
    });

    test('a room refused its video takes no video call afterwards', () async {
      h.signaling.failureFor = _refuse<ConferenceVideoSubscribeRequest>('video_disabled');
      await _roomUp(h);
      h.seedEstablishedCall('c', line: 2, video: true);
      await pumpEventQueue();

      expect(h.bloc.state.conference.videoDisabled, isTrue);
      expect(h.bloc.state.roomTakesVideo, isFalse);
      expect(
        h.bloc.state.mergeableCallIds,
        isNot(contains('c')),
        reason: 'the server would end the conference over it',
      );
    });

    test('the room\'s end takes the refusal with it', () async {
      h.signaling.failureFor = _refuse<ConferenceVideoSubscribeRequest>('video_disabled');
      await _roomUp(h);
      expect(h.bloc.state.conference.videoDisabled, isTrue);

      h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
      await pumpEventQueue();

      expect(h.bloc.state.roomTakesVideo, isTrue);
    });
  });

  group('a participant called in', () {
    Future<ActiveCall> callIn() async {
      h.bloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'a', number: '200'));
      await h.settle(() => h.bloc.state.linkedCall != null);
      return h.bloc.state.retrieveActiveCall(h.bloc.state.linkedCall!.callId)!;
    }

    test('is called with video when the room carries it, the legs being audio calls', () async {
      // A participant called without video would never get the room's.
      await _roomUp(h);
      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(true));
      await h.settle(() => h.bloc.state.conference.selfVideo != null);

      expect((await callIn()).video, isTrue);
    });

    test('is called without video into a room that carries none', () async {
      await _roomUp(h);

      expect((await callIn()).video, isFalse);
    });
  });

  group('the camera of the room', () {
    test('a camera the room refuses is said to the user and not asked for again', () async {
      h.signaling.failureFor = _refuse<ConferenceVideoPublishRequest>('invalid_descriptions');
      await _roomUp(h, videoLeg: true);

      expect(h.notifications.whereType<ConferenceRefusedNotification>(), hasLength(1));
      final asked = sent<ConferenceVideoPublishRequest>().length;
      h.bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
      h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(asked), reason: 'the camera is not wanted any more');
    });

    test('a camera that cannot be opened is said to the user', () async {
      await h.close();
      h = _harness(media: _NoCamera());
      await _roomUp(h, videoLeg: true);

      expect(h.notifications.whereType<CallUserMediaErrorNotification>(), hasLength(1));
      expect(sent<ConferenceVideoPublishRequest>(), isEmpty);
    });

    test('in the background the camera leaves the room and comes back with the app', () async {
      await _roomUp(h, videoLeg: true);
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1));

      h.bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(sent<ConferenceVideoUnpublishRequest>(), hasLength(1));

      h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(2));
    });

    test('turned off, it leaves the camera of a video call outside the room on', () async {
      // The camera is one track every call shares.
      await _roomUp(h, videoLeg: true);
      final shared = h.media.buildSync(video: true);
      h.seedEstablishedCall('c', line: 2, video: true, held: true);
      for (final callId in ['a', 'c']) {
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        h.bloc.emit(h.bloc.state.copyWithMappedActiveCall(callId, (call) => call.copyWith(localStream: shared)));
      }
      final camera = shared.getVideoTracks().single;

      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(false));
      await pumpEventQueue();

      expect(sent<ConferenceVideoUnpublishRequest>(), hasLength(1));
      expect(h.bloc.state.retrieveActiveCall('a')!.video, isFalse, reason: 'the leg follows the room');
      expect(h.bloc.state.retrieveActiveCall('c')!.video, isTrue);
      expect(camera.enabled, isTrue, reason: 'the outside call still sends it');
    });
  });

  group('an invited far end', () {
    Future<void> invited({bool video = true}) async {
      h.seedEstablishedCall('a', line: 0, video: video);
      h.signaling.emit(const ConferenceVideoInviteEvent(room: 4242, line: 0, host: 'Alice'));
      await pumpEventQueue();
    }

    test('joins the video through the call the invitation names, and the state says so at once', () async {
      await invited(video: false);

      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(sent<ConferenceVideoPublishRequest>(), isEmpty);
      expect(h.bloc.state.invitedVideo?.line, 0, reason: 'the camera control of that call is the room\'s from here');
    });

    test('a camera turned off stays off after the background', () async {
      await invited();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1));

      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(false));
      await pumpEventQueue();
      expect(sent<ConferenceVideoUnpublishRequest>(), hasLength(1));

      h.bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
      h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1), reason: 'the user turned it off');
    });

    test('the end of the room\'s video ends the invitation', () async {
      await invited();

      h.signaling.emit(const ConferenceVideoTerminatedEvent(room: 4242));
      await pumpEventQueue();

      expect(h.bloc.state.invitedVideo, isNull);
    });

    test('a room of its own ends the invitation first, and gets its own video', () async {
      await invited(video: false);
      h.seedEstablishedCall('b', line: 1);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
      );
      await pumpEventQueue();

      final kinds = h.signaling.requests.map((r) => r.runtimeType).toList();
      expect(kinds.indexOf(ConferenceVideoLeaveRequest), lessThan(kinds.indexOf(MergeRequest)));
      expect(h.bloc.state.invitedVideo, isNull);
      expect(
        sent<ConferenceVideoSubscribeRequest>(),
        hasLength(2),
        reason: 'one for the invitation, one for its own room',
      );
    });
  });
}
