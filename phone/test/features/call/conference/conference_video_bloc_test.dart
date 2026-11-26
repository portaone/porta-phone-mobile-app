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

/// Waits in real time for [done]: a call's camera turned on in a voice call waits up to two
/// seconds of its own before it goes on.
Future<void> _untilReal(bool Function() done) async {
  for (var waited = 0; waited < 200 && !done(); waited++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
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

      expect(h.bloc.state.conference.videoOfLine(0), ParticipantCamera(stream: stream, trackId: 'v0'));
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
      // Behind a camera given to a voice leg, which waits a moment of its own first.
      await _untilReal(() => h.bloc.state.linkedCall != null);
      return h.bloc.state.retrieveActiveCall(h.bloc.state.linkedCall!.callId)!;
    }

    test('is called with video when the room carries it, the legs being audio calls', () async {
      // A participant called without video would never get the room's.
      await _roomUp(h);
      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(true));
      await h.settle(() => h.bloc.state.conference.selfVideo != null);
      // The legs are given the camera first, each after a moment against a crossing upgrade.
      await _untilReal(() => ['a', 'b'].every((id) => h.bloc.state.retrieveActiveCall(id)!.video));

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

    test('a room that starts in the background publishes the camera when the app returns', () async {
      // The bloc starts where the app is - a call push in the background -
      // and no change of the lifecycle follows for it to hear.
      await h.close();
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(() => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      h = _harness();
      h.bloc.add(const CallStarted());
      await pumpEventQueue();

      await _roomUp(h, videoLeg: true);
      expect(sent<ConferenceVideoPublishRequest>(), isEmpty);
      expect(h.notifications.whereType<CallUserMediaErrorNotification>(), isEmpty);

      h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1));
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

    test('voice calls: turned on, it reaches every participant, their calls given video', () async {
      final legA = h.seedEstablishedCall('a', line: 0);
      final legB = h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
      );
      await pumpEventQueue();

      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(true));
      // A call's camera turned on in a voice call waits a moment, against a crossing upgrade.
      await _untilReal(() => legA.addedTracks.isNotEmpty && legB.addedTracks.isNotEmpty);

      expect(legA.addedTracks.single.kind, 'video');
      expect(legB.addedTracks.single.kind, 'video');
      expect(h.bloc.state.retrieveActiveCall('a')!.video, isTrue);
      expect(h.bloc.state.retrieveActiveCall('b')!.video, isTrue);
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

  group('the screen in the room', () {
    Future<void> shareFromLeg(String callId) async {
      h.bloc.add(CallControlEvent.screenShareStarted(callId));
      await h.settle(
        () =>
            h.bloc.state.roomScreenShare == ScreenShareStatus.sharing &&
            sent<ConferenceVideoPublishRequest>().isNotEmpty,
      );
    }

    test('a leg shares for the room: the screen is published there, named a screen', () async {
      await _roomUp(h);

      await shareFromLeg('a');

      final publish = sent<ConferenceVideoPublishRequest>().single;
      expect(publish.descriptions.single.kind, ConferenceVideoKind.screen);
      expect(h.bloc.state.roomScreenShare, ScreenShareStatus.sharing);
      expect(h.bloc.state.screenShareOf('b'), ScreenShareStatus.sharing, reason: 'the room\'s, whichever leg shows it');
      expect(h.bloc.state.screenShare?.target, const RoomScreenShareTarget(), reason: 'one share of the room');
      expect(h.screen.steps, ['consent', 'start service', 'capture']);
    });

    test('the screen takes the place of the camera the room had', () async {
      await _roomUp(h, videoLeg: true);
      expect(h.bloc.state.conference.selfVideo, isNotNull);

      await shareFromLeg('a');
      await h.settle(() => sent<ConferenceVideoPublishRequest>().length == 2);

      expect(sent<ConferenceVideoPublishRequest>().last.descriptions.single.kind, ConferenceVideoKind.screen);
      expect(h.bloc.state.conference.selfVideo, isNull, reason: 'the camera is let go while the screen is out');
    });

    test('the participants get the screen by their calls with the host, and the camera after it', () async {
      // Each participant sees the host by the video of its own call with him.
      final videoLeg = h.seedEstablishedCall('a', line: 0, video: true);
      final legStream = h.bloc.state.retrieveActiveCall('a')!.localStream!;
      final camera = (await h.media.ensureVideoTrack(legStream))!;
      final legSender = await videoLeg.addTrack(camera, legStream) as FakeRtpSender;
      final audioLeg = h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
      );
      await pumpEventQueue();

      await shareFromLeg('a');
      await h.settle(() => legSender.track?.id == h.screen.lastCapture?.getVideoTracks().single.id);

      final screen = h.screen.lastCapture!.getVideoTracks().single;
      expect(legSender.track?.id, screen.id, reason: 'the screen in the camera\'s place on the call');
      expect(audioLeg.addedTracks.single.id, screen.id, reason: 'a voice leg is given video for it');

      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await h.settle(() => !h.screen.serviceRunning);

      expect(legSender.track, isNotNull);
      expect(legSender.track!.id, isNot(screen.id));
      expect(legSender.track!.kind, 'video', reason: 'the camera back on the call');
    });

    test('voice calls: the host\'s share reaches every participant, given video for it', () async {
      // The camera never on: each participant's call gets a video line for the screen.
      final legA = h.seedEstablishedCall('a', line: 0);
      final legB = h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
      );
      await pumpEventQueue();

      await shareFromLeg('a');
      final screen = h.screen.lastCapture!.getVideoTracks().single;
      await h.settle(() => legA.addedTracks.isNotEmpty && legB.addedTracks.isNotEmpty);

      expect(legA.addedTracks.single.id, screen.id);
      expect(legB.addedTracks.single.id, screen.id);

      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await h.settle(() => !h.screen.serviceRunning);

      for (final leg in [legA, legB]) {
        final senders = await leg.getSenders();
        expect(senders, hasLength(2), reason: 'the voice line kept, the video line added');
        expect(senders.last.track, isNull, reason: 'nothing on the added video after');
      }
    });

    test('voice calls: a camera turned on during the share reaches the participants after it', () async {
      final legA = h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
      );
      await pumpEventQueue();
      await shareFromLeg('a');
      final screen = h.screen.lastCapture!.getVideoTracks().single;
      await h.settle(() => legA.addedTracks.isNotEmpty);

      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(true));
      await pumpEventQueue();
      final videoSender = (await legA.getSenders()).last;
      expect(videoSender.track?.id, screen.id, reason: 'the screen stays on the call while it is out');

      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await _untilReal(() => videoSender.track != null && videoSender.track!.id != screen.id);

      expect(videoSender.track?.kind, 'video', reason: 'the camera on the call after the screen');
      expect(h.bloc.state.retrieveActiveCall('a')!.video, isTrue);
    });

    test('stopping takes the screen off the room and releases the capture and its service', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      h.bloc.add(const CallControlEvent.screenShareStopped('b'));
      await h.settle(() => !h.screen.serviceRunning);

      expect(h.bloc.state.roomScreenShare, isNull);
      expect(sent<ConferenceVideoUnpublishRequest>(), hasLength(1), reason: 'no camera to go back to');
      expect((h.screen.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
      expect(h.notifications, isEmpty);
    });

    test('the camera comes back after the screen facing the way the room showed it', () async {
      // A camera opened without a facing is the platform's default one: the rear on an iPhone.
      await _roomUp(h, videoLeg: true);
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      h.bloc.emit(h.bloc.state.copyWithMappedActiveCall('a', (call) => call.copyWith(frontCamera: true)));
      await shareFromLeg('a');
      await h.settle(() => sent<ConferenceVideoPublishRequest>().length == 2);
      final opened = h.media.frontCameras.length;

      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await h.settle(() => sent<ConferenceVideoPublishRequest>().length == 3);

      expect(sent<ConferenceVideoPublishRequest>().last.descriptions.single.kind, ConferenceVideoKind.camera);
      expect(h.media.frontCameras.skip(opened), [true], reason: 'the front camera, as before the screen');
    });

    test('the camera asked for while the screen is out comes back after it', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      h.bloc.add(const CallControlEvent.conferenceCameraEnabled(true));
      await pumpEventQueue();
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1), reason: 'the screen holds the line');
      expect(h.media.built.where((stream) => stream.getVideoTracks().isNotEmpty), isEmpty);

      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await h.settle(() => sent<ConferenceVideoPublishRequest>().length == 2);

      expect(sent<ConferenceVideoPublishRequest>().last.descriptions.single.kind, ConferenceVideoKind.camera);
      expect(sent<ConferenceVideoUnpublishRequest>(), isEmpty);
    });

    test('a call outside the room the room stands aside for stops the room share', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      // The person answers somebody else: the room is parked and must not go on showing the screen.
      h.seedEstablishedCall('c', line: 2);
      await h.settle(() => !h.screen.serviceRunning);

      expect(h.bloc.state.conferenceMustPark, isTrue);
      expect(h.bloc.state.roomScreenShare, isNull);
      expect(h.screen.serviceRunning, isFalse);
      expect(h.bloc.state.canShareScreen('c'), isTrue, reason: 'the call outside can share now');
    });

    test('the host\'s way back into the room keeps the share', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      h.bloc.emit(
        h.bloc.state.copyWith(conference: h.bloc.state.conference.copyWith(phase: ConferencePhase.rejoining)),
      );
      await pumpEventQueue();

      expect(h.bloc.state.roomScreenShare, ScreenShareStatus.sharing);
      expect(h.screen.serviceRunning, isTrue);
      expect(h.bloc.state.canShareScreen('a'), isFalse, reason: 'a new share waits for the room to be up');
    });

    test('a screen refused over the room\'s camera puts the camera back', () async {
      await _roomUp(h, videoLeg: true);
      expect(sent<ConferenceVideoPublishRequest>(), hasLength(1));
      // The room refuses the screen's publish once; the camera's after it is taken.
      var refusals = 0;
      h.signaling.failureFor = (request) => request is ConferenceVideoPublishRequest && refusals++ == 0
          ? SignalingErrorException(1, 0, 'invalid_descriptions')
          : null;

      h.bloc.add(const CallControlEvent.screenShareStarted('a'));
      await h.settle(
        () =>
            h.notifications.whereType<ScreenShareFailedNotification>().isNotEmpty &&
            h.bloc.state.conference.selfVideo != null,
      );

      expect(h.bloc.state.roomScreenShare, isNull);
      expect(h.bloc.state.conference.selfVideo, isNotNull, reason: 'the person still wants the camera');
    });

    test('a screen the room refuses stops the share and is said', () async {
      h.signaling.failureFor = _refuse<ConferenceVideoPublishRequest>('invalid_descriptions');
      await _roomUp(h);

      h.bloc.add(const CallControlEvent.screenShareStarted('a'));
      await h.settle(
        () => h.notifications.whereType<ScreenShareFailedNotification>().isNotEmpty && !h.screen.serviceRunning,
      );

      expect(h.bloc.state.roomScreenShare, isNull);
      expect(h.notifications.whereType<ScreenShareFailedNotification>(), hasLength(1));
      expect(h.screen.serviceRunning, isFalse);
    });

    test('the end of the room ends the share', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
      await h.settle(() => !h.screen.serviceRunning);

      expect(h.screen.serviceRunning, isFalse);
      expect((h.screen.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
    });

    test('in the background the screen stays in the room', () async {
      await _roomUp(h);
      await shareFromLeg('a');

      h.bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(sent<ConferenceVideoUnpublishRequest>(), isEmpty, reason: 'the person shares what they look at elsewhere');
      expect(h.bloc.state.roomScreenShare, ScreenShareStatus.sharing);
      h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
    });

    test('a screen the room sends reaches the state with its presenter', () async {
      await _roomUp(h);
      h.signaling.emit(const ConferenceVideoOfferEvent(jsep: _videoOffer));
      await pumpEventQueue();
      final stream = FakeMediaStream(
        'remote',
        tracks: [FakeMediaStreamTrack(kind: 'video', id: 'v1')],
      );
      h.peerFactory.created.last.onTrack!(
        RTCTrackEvent(
          track: FakeMediaStreamTrack(kind: 'video', id: 'v1'),
          streams: [stream],
          transceiver: _Transceiver('1'),
        ),
      );
      h.signaling.emit(
        const ConferenceVideoUpdatedEvent(
          room: 7,
          self: 1,
          streams: [ConferenceVideoStream(mid: '1', feed: 3, kind: ConferenceVideoKind.screen)],
          presenter: 3,
        ),
      );
      await pumpEventQueue();

      final conference = h.bloc.state.conference;
      expect(conference.presenter, 3);
      expect(conference.mainScreen, ParticipantCamera(stream: stream, trackId: 'v1'));
      expect(conference.videoOfLine(1), isNull, reason: 'a screen is not the participant\'s camera');
      expect(conference.hasVideo, isTrue);
    });

    test('whoever the room says speaks reaches the state', () async {
      await _roomUp(h);
      h.signaling.emit(const ConferenceVideoOfferEvent(jsep: _videoOffer));
      await pumpEventQueue();

      h.signaling.emit(const ConferenceVideoUpdatedEvent(room: 7, self: 1, speaker: 3));
      await pumpEventQueue();

      expect(h.bloc.state.conference.speaker, 3);
      expect(h.bloc.state.conference.speaks(1), isTrue, reason: 'the far end of line 1 is feed 3');
      expect(h.bloc.state.conference.hostSpeaks, isFalse);
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

    test('the end of the call the invitation came through ends the invitation', () async {
      // Whether or not conference_video_terminated arrives for it.
      await invited();

      h.signaling.emit(const HangupEvent(line: 0, callId: 'a', code: 200, reason: 'Normal Clearing'));
      await pumpEventQueue();

      expect(h.bloc.state.invitedVideo, isNull);
    });

    test('a reset of every call ends the invitation', () async {
      await invited();

      h.signaling.emitHandshake(
        StateHandshake(
          keepaliveInterval: const Duration(seconds: 30),
          timestamp: 0,
          registration: const Registration(status: RegistrationStatus.unregistered),
          lines: const [null],
          presenceInfos: const [],
          dialogInfos: const [],
          guestLine: null,
        ),
      );
      await pumpEventQueue();

      expect(h.bloc.state.invitedVideo, isNull);
    });

    test('a signalling reconnect with the invitation standing remakes its video', () async {
      await invited();
      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(1));

      h.signaling.emitHandshake(
        StateHandshake(
          keepaliveInterval: const Duration(seconds: 30),
          timestamp: 0,
          registration: const Registration(status: RegistrationStatus.registered),
          lines: [
            Line(
              callId: 'a',
              callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 0, callId: 'a'))],
            ),
          ],
          presenceInfos: const [],
          dialogInfos: const [],
          guestLine: null,
        ),
      );
      await pumpEventQueue();

      expect(sent<ConferenceVideoSubscribeRequest>(), hasLength(2));
    });

    test('shares its screen in the room, not in its call', () async {
      final callPeer = h.seedEstablishedCall('a', line: 0);
      h.signaling.emit(const ConferenceVideoInviteEvent(room: 4242, line: 0, host: 'Alice'));
      await pumpEventQueue();

      h.bloc.add(const CallControlEvent.screenShareStarted('a'));
      await h.settle(() => sent<ConferenceVideoPublishRequest>().isNotEmpty);

      expect(sent<ConferenceVideoPublishRequest>().single.descriptions.single.kind, ConferenceVideoKind.screen);
      expect(callPeer.addedTracks.where((track) => track.id?.startsWith('screen') ?? false), isEmpty);
      expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
    });

    test('the host\'s screen is kept as the host\'s video', () async {
      // Core lists the host's screen on its feed 1 with kind screen; the invited view has no room
      // of its own, and the host's video there is the screen.
      await invited(video: false);
      h.signaling.emit(const ConferenceVideoOfferEvent(jsep: _videoOffer));
      await pumpEventQueue();
      final stream = FakeMediaStream(
        'remote',
        tracks: [FakeMediaStreamTrack(kind: 'video', id: 'v0')],
      );
      h.peerFactory.created.last.onTrack!(
        RTCTrackEvent(
          track: FakeMediaStreamTrack(kind: 'video', id: 'v0'),
          streams: [stream],
          transceiver: _Transceiver('0'),
        ),
      );
      h.signaling.emit(
        const ConferenceVideoUpdatedEvent(
          room: 4242,
          self: 2,
          streams: [ConferenceVideoStream(mid: '0', feed: 1, kind: ConferenceVideoKind.screen)],
          presenter: 1,
        ),
      );
      await pumpEventQueue();

      expect(h.bloc.state.invitedVideo?.feeds[1], ParticipantCamera(stream: stream, trackId: 'v0'));
    });

    test('a share of the call stops when its far end invites it to a room', () async {
      // The call's own video is not used by the room: the share would show nothing there.
      final peer = h.seedEstablishedCall('a', line: 0, video: true);
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera-a');
      await h.bloc.state.retrieveActiveCall('a')!.localStream!.addTrack(camera);
      await peer.addTrack(camera);
      h.bloc.add(const CallControlEvent.screenShareStarted('a'));
      await h.settle(() => h.bloc.state.screenShareOf('a') == ScreenShareStatus.sharing);

      h.signaling.emit(const ConferenceVideoInviteEvent(room: 4242, line: 0, host: 'Alice'));
      await h.settle(() => !h.screen.serviceRunning);

      expect(h.bloc.state.screenShareOf('a'), isNull);
      expect(h.screen.serviceRunning, isFalse);
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
