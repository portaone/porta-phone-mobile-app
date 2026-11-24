import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// The screen of the phone shown in an ordinary call: it takes the call's video sender in place of
/// the camera and gives the camera back when it stops - whatever stops it: the person, the system,
/// a hold, a merge, the end of the call. The platform side (consent, service, capture) is the
/// harness's [FakeScreenCapturer]; what a real phone and a far end make of it is not modelled.
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isPeerMessageEnabled: true)));
  tearDown(() => h.close());

  /// An answered call with its camera, from its local stream, on the connection's video sender.
  ({FakePeerConnection peer, FakeMediaStreamTrack camera}) seedVideoCall(String callId, {int line = 0}) {
    final peer = h.seedEstablishedCall(callId, line: line, video: true);
    final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera-$callId');
    unawaited(h.bloc.state.retrieveActiveCall(callId)!.localStream!.addTrack(camera));
    unawaited(peer.addTrack(camera));
    return (peer: peer, camera: camera);
  }

  /// The camera the share opened again for the call when it stopped.
  FakeMediaStreamTrack reopenedCamera() => h.media.camerasOpened.single;

  ActiveCall call(String callId) => h.bloc.state.retrieveActiveCall(callId)!;

  Future<void> share(String callId) async {
    h.bloc.add(CallControlEvent.screenShareStarted(callId));
    await h.settle(() => h.bloc.state.screenShareOf(callId) == ScreenShareStatus.sharing);
  }

  Iterable<MediaStatePeerMessageRequest> mediaStates() =>
      h.signaling.requests.whereType<MediaStatePeerMessageRequest>();

  test('the screen goes out on the camera\'s sender and is announced as video', () async {
    final (:peer, camera: _) = seedVideoCall('a');

    await share('a');

    expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
    expect(peer.fakeSenders.last.track?.id, 'screen-1');
    expect(h.screen.steps, ['consent', 'start service', 'capture']);
    expect(mediaStates().last.video, isTrue);
  });

  test('the camera is let go while the screen is out', () async {
    final (peer: _, :camera) = seedVideoCall('a');

    await share('a');

    expect(camera.stopped, isTrue);
    expect(call('a').localStream!.getVideoTracks(), isEmpty);
  });

  test('stopping gives the camera back and releases the capture and its service', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    await share('a');

    h.bloc.add(const CallControlEvent.screenShareStopped('a'));
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);

    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(peer.fakeSenders.last.track, same(reopenedCamera()));
    expect(call('a').isCameraActive, isTrue);
    expect(mediaStates().last.video, isTrue);
    expect((h.screen.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
    expect(h.screen.serviceRunning, isFalse);
    expect(h.notifications, isEmpty);
  });

  test('the end of the capture outside the app stops the share', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    await share('a');

    h.screen.endOutside();
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);

    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(peer.fakeSenders.last.track, same(reopenedCamera()));
  });

  test('a camera that does not open again after the share turns the call\'s video off', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    await share('a');
    h.media.cameraError = Exception('camera in use');

    h.bloc.add(const CallControlEvent.screenShareStopped('a'));
    await h.settle(() => h.bloc.state.screenShareOf('a') == null && h.notifications.isNotEmpty);

    expect(peer.fakeSenders.last.track, isNull);
    expect(call('a').video, isFalse);
    expect(h.notifications.single, isA<CallUserMediaErrorNotification>());
    expect(mediaStates().last.video, isFalse);
  });

  test('a hold stops the share before the call is held', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    await share('a');

    await h.bloc.performSetHeld('a', true);
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);

    expect(call('a').held, isTrue);
    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(peer.fakeSenders.last.track, same(reopenedCamera()));
    expect(h.screen.serviceRunning, isFalse);
  });

  test('the end of the call releases the capture and its service', () async {
    seedVideoCall('a');
    await share('a');

    h.bloc.add(const CallControlEvent.ended('a'));
    await h.settle(() => !h.screen.serviceRunning);

    expect(h.screen.serviceRunning, isFalse);
    expect((h.screen.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
  });

  test('a merge stops the share first', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    h.seedEstablishedCall('b', line: 1, held: true);
    await share('a');

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);

    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(h.screen.serviceRunning, isFalse);
    expect(peer.fakeSenders.last.track?.id, isNot('screen-1'), reason: 'the screen left before the room came');
  });

  test('the transfer picker leaves the share running', () async {
    seedVideoCall('a');
    await share('a');

    h.bloc.add(const CallControlEvent.blindTransferInitiated('a'));
    await h.settle(() => call('a').transfer != null);
    await pumpEventQueue();

    expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
    expect(ScreenShareCoordinator.stands(h.bloc.state, const CallScreenShareTarget('a')), isTrue);
  });

  test('a transfer under way cannot share', () async {
    seedVideoCall('a');
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(
      h.bloc.state.copyWithMappedActiveCall(
        'a',
        (call) => call.copyWith(transfer: const Transfer.blindTransferTransferSubmitted(toNumber: '200')),
      ),
    );

    expect(h.bloc.state.canShareScreen('a'), isFalse);
  });

  test('the camera control is left alone while the screen is shared', () async {
    final (:peer, camera: _) = seedVideoCall('a');
    await share('a');

    h.bloc.add(const CallControlEvent.cameraEnabled('a', false));
    await pumpEventQueue();

    expect(peer.fakeSenders.last.track?.id, 'screen-1');
    expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
  });

  test('a refused consent changes nothing and says nothing', () async {
    final (:peer, :camera) = seedVideoCall('a');
    h.screen.consent = false;

    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await h.settle(() => h.screen.steps.isNotEmpty && h.bloc.state.screenShareOf('a') == null);
    await pumpEventQueue();

    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(peer.fakeSenders.last.track, same(camera));
    expect(h.screen.steps, ['consent']);
    expect(h.notifications, isEmpty);
  });

  test('a stop while the capture starts says nothing of a failure', () async {
    seedVideoCall('a');
    h.screen.captureGate = Completer<void>();
    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await h.settle(() => h.screen.steps.contains('capture'));

    // The person stops it; the capture under way then throws, its service taken away.
    h.bloc.add(const CallControlEvent.screenShareStopped('a'));
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);
    h.screen.captureError = Exception('no foreground service');
    h.screen.captureGate!.complete();
    await pumpEventQueue();

    expect(h.notifications, isEmpty);
    expect(h.screen.serviceRunning, isFalse);
  });

  test('the screen follows a refused consent while the call is busy with something else', () async {
    seedVideoCall('a');
    h.screen.consentGate = Completer<void>();
    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await h.settle(() => h.bloc.state.screenShareOf('a') == ScreenShareStatus.starting);

    h.screen.consent = false;
    h.screen.consentGate!.complete();
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);

    expect(h.bloc.state.screenShareOf('a'), isNull);
  });

  test('a phone that cannot share starts nothing', () async {
    await h.close();
    h = CallBlocHarness(
      capabilities: const CallCapabilitiesConfig(isPeerMessageEnabled: true),
      screenShareSupported: false,
    );
    seedVideoCall('a');

    expect(h.bloc.state.canShareScreen('a'), isFalse);
    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await pumpEventQueue();

    expect(h.screen.steps, isEmpty);
    expect(h.bloc.state.screenShareOf('a'), isNull);
  });

  test('a refused service is told and leaves the camera on', () async {
    final (:peer, :camera) = seedVideoCall('a');
    h.screen.serviceError = Exception('mediaProjection refused');

    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await h.settle(() => h.notifications.isNotEmpty && h.bloc.state.screenShareOf('a') == null);

    expect(h.notifications.single, isA<ScreenShareFailedNotification>());
    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(peer.fakeSenders.last.track, same(camera));
    expect(camera.stopped, isFalse);
  });

  test('a held call does not share', () async {
    seedVideoCall('a');
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(h.bloc.state.copyWithMappedActiveCall('a', (call) => call.copyWith(held: true)));

    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await pumpEventQueue();

    expect(h.screen.steps, isEmpty);
    expect(h.bloc.state.screenShareOf('a'), isNull);
  });

  test('a hold during the consent cancels the share', () async {
    seedVideoCall('a');
    h.screen.consentGate = Completer<void>();
    h.bloc.add(const CallControlEvent.screenShareStarted('a'));
    await h.settle(() => h.bloc.state.screenShareOf('a') == ScreenShareStatus.starting);

    await h.bloc.performSetHeld('a', true);
    await h.settle(() => h.bloc.state.screenShareOf('a') == null);
    h.screen.consentGate!.complete();
    await pumpEventQueue();

    expect(h.bloc.state.screenShareOf('a'), isNull);
    expect(h.screen.steps, ['consent']);
    expect(h.screen.serviceRunning, isFalse);
  });

  group('an audio call', () {
    test('gets a video sender for the screen and keeps it empty with the camera off after', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');

      expect(peer.addedTracks.single.id, 'screen-1');
      h.bloc.add(const CallControlEvent.screenShareStopped('a'));
      await h.settle(() => h.bloc.state.screenShareOf('a') == null);

      expect(peer.fakeSenders.last.track, isNull);
      expect(call('a').video, isFalse, reason: 'the camera stays off');
      expect(mediaStates().last.video, isFalse);
    });

    test('stops the share when the far end refuses the video', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');
      // The offer that added the video line is out, and the answer refuses the line.
      peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.Inactive;

      h.signaling.emit(const AcceptedEvent(line: 0, callId: 'a', jsep: {'type': 'answer', 'sdp': 'v=0\r\n'}));
      await h.settle(() => h.bloc.state.screenShareOf('a') == null);

      expect(h.bloc.state.screenShareOf('a'), isNull);
      expect(h.notifications.single, isA<ScreenShareVideoRefusedNotification>());
      expect(h.screen.serviceRunning, isFalse);
    });

    test('keeps sharing when the answer is to an offer made before the screen\'s video', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');
      // An offer was out before the share added its line: the answer that comes says nothing
      // of the line, which no offer has carried yet.
      peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      peer.fakeTransceivers.last
        ..mid = ''
        ..negotiatedDirection = null;

      h.signaling.emit(const AcceptedEvent(line: 0, callId: 'a', jsep: {'type': 'answer', 'sdp': 'v=0\r\n'}));
      await h.settle(() => peer.remoteDescriptions.isNotEmpty);
      await pumpEventQueue();

      expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
      expect(h.notifications, isEmpty);
    });

    test('stops the share when the offer carrying the screen\'s video is refused', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');
      peer.fakeTransceivers.last
        ..mid = '1'
        ..negotiatedDirection = null;

      h.signaling.emit(const DecliningEvent(line: 0, callId: 'a', code: 488));
      await h.settle(() => h.bloc.state.screenShareOf('a') == null);

      expect(h.notifications.whereType<ScreenShareVideoRefusedNotification>(), hasLength(1));
    });

    test('keeps sharing when a refused offer was made before the screen\'s video', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');
      peer.fakeTransceivers.last
        ..mid = ''
        ..negotiatedDirection = null;

      h.signaling.emit(const DecliningEvent(line: 0, callId: 'a', code: 491));
      await pumpEventQueue();

      expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
      expect(h.notifications.whereType<ScreenShareVideoRefusedNotification>(), isEmpty);
    });

    test('keeps sharing when the far end takes the video', () async {
      final peer = h.seedEstablishedCall('a');
      await share('a');
      peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.SendOnly;

      h.signaling.emit(const AcceptedEvent(line: 0, callId: 'a', jsep: {'type': 'answer', 'sdp': 'v=0\r\n'}));
      await h.settle(() => peer.remoteDescriptions.isNotEmpty);
      await pumpEventQueue();

      expect(h.bloc.state.screenShareOf('a'), ScreenShareStatus.sharing);
      expect(h.notifications, isEmpty);
    });
  });
}
