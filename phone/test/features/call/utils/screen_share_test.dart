import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/features/call/utils/utils.dart';

import '../bloc/call_bloc_harness.dart';

void main() {
  late FakeScreenCapturer capturer;
  late FakeUserMediaBuilder media;
  late List<String> endedOutside;
  late List<(String, ScreenShareStatus?)> changes;
  late ScreenShare share;

  setUp(() {
    capturer = FakeScreenCapturer();
    media = FakeUserMediaBuilder();
    endedOutside = [];
    changes = [];
    share = ScreenShare(
      capturer: capturer,
      userMedia: media,
      onEndedOutside: endedOutside.add,
      onChanged: (callId) => changes.add((callId, share.statusOf(callId))),
    );
  });

  tearDown(() => share.dispose());

  /// A call with its microphone and, when [camera] is given, a camera on its video sender.
  FakePeerConnection connection({MediaStreamTrack? camera}) {
    final peer = FakePeerConnection(
      audioTrack: FakeMediaStreamTrack(kind: 'audio', id: 'mic'),
      remoteDescribed: true,
    );
    if (camera != null) unawaited(peer.addTrack(camera));
    return peer;
  }

  Future<Object> captured(String callId) async {
    final attempt = share.begin(callId)!;
    expect(await share.capture(callId, attempt), ScreenShareCaptureResult.captured);
    return attempt;
  }

  test('the consent comes first, the service before the capture', () async {
    await captured('a');

    expect(capturer.steps, ['consent', 'start service', 'capture']);
    expect(share.statusOf('a'), ScreenShareStatus.starting);
  });

  test('the screen takes the camera\'s sender and the stop gives the camera back', () async {
    final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
    final peer = connection(camera: camera);
    final attempt = await captured('a');

    final result = await share.attach('a', attempt, peerConnection: peer, localStream: null);

    final videoSender = peer.fakeSenders.last;
    expect(result, ScreenShareAttachResult.attached);
    expect(videoSender.track?.id, 'screen-1');
    expect(peer.addedTracks, [camera], reason: 'no second video line');
    expect(share.statusOf('a'), ScreenShareStatus.sharing);

    final stopped = await share.stop('a', peerConnection: peer);

    expect(stopped?.attached, isTrue);
    expect(videoSender.track, same(camera));
    expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
    expect(capturer.serviceRunning, isFalse);
    expect(share.statusOf('a'), isNull);
  });

  group('the call\'s own camera', () {
    /// A call whose camera, from its local stream, is on the video sender.
    ({FakePeerConnection peer, FakeMediaStream localStream, FakeMediaStreamTrack camera}) videoCall({
      bool enabled = true,
    }) {
      final localStream = media.buildSync();
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera')..enabled = enabled;
      unawaited(localStream.addTrack(camera));
      return (peer: connection(camera: camera), localStream: localStream, camera: camera);
    }

    test('is let go while the screen is out and opened again, as it was, after', () async {
      final (:peer, :localStream, :camera) = videoCall(enabled: false);
      final attempt = await captured('a');

      await share.attach('a', attempt, peerConnection: peer, localStream: localStream);

      expect(camera.stopped, isTrue, reason: 'nothing captures the camera behind the screen');
      expect(localStream.getVideoTracks(), isEmpty);

      final stopped = await share.stop('a', peerConnection: peer, frontCamera: false);

      final reopened = media.camerasOpened.single;
      expect(stopped?.cameraLost, isFalse);
      expect(peer.fakeSenders.last.track, same(reopened));
      expect(reopened.enabled, isFalse, reason: 'a soft-muted camera comes back soft-muted');
      expect(localStream.getVideoTracks(), [reopened]);
      expect(media.reopenFrontCameras.last, isFalse);
    });

    test('that does not open again leaves the sender empty and says so', () async {
      final (:peer, :localStream, camera: _) = videoCall();
      final attempt = await captured('a');
      await share.attach('a', attempt, peerConnection: peer, localStream: localStream);
      media.cameraError = Exception('camera in use');

      final stopped = await share.stop('a', peerConnection: peer);

      expect(stopped?.cameraLost, isTrue);
      expect(peer.fakeSenders.last.track, isNull);
    });

    test('is not opened again for a call going away', () async {
      final (:peer, :localStream, camera: _) = videoCall();
      final attempt = await captured('a');
      await share.attach('a', attempt, peerConnection: peer, localStream: localStream);

      await share.stop('a');

      expect(media.camerasOpened, isEmpty);
    });
  });

  test('an audio call gets a video sender for the screen, empty again after the stop', () async {
    final peer = connection();
    final attempt = await captured('a');

    final result = await share.attach('a', attempt, peerConnection: peer, localStream: null);

    expect(result, ScreenShareAttachResult.attachedWithNewVideo);
    expect(share.awaitsVideo('a'), isTrue);
    await share.stop('a', peerConnection: peer);

    final videoSender = peer.fakeSenders.last;
    expect(videoSender.track, isNull, reason: 'the camera was off: nothing goes back');
    expect(await peer.videoSender(), same(videoSender), reason: 'the camera turned on later finds this sender');
  });

  test('the far end refusing the added video is seen in the answer', () async {
    final peer = connection();
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);

    peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.Inactive;

    expect(await share.videoAnswer('a', peer), ScreenShareVideoAnswer.refused);
    expect(share.awaitsVideo('a'), isTrue);
  });

  test('an answer that takes the added video settles the wait', () async {
    final peer = connection();
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);

    peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.SendOnly;

    expect(await share.videoAnswer('a', peer), ScreenShareVideoAnswer.sends);
    expect(share.awaitsVideo('a'), isFalse);
  });

  test('an answer to an offer made before the added video decides nothing', () async {
    final peer = connection();
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);

    // The line was in no offer the answer answered: it has no negotiated direction yet.
    peer.fakeTransceivers.last
      ..mid = ''
      ..negotiatedDirection = null;

    expect(await share.videoAnswer('a', peer), ScreenShareVideoAnswer.pending);
    expect(share.awaitsVideo('a'), isTrue);
  });

  test('a refused offer counts only when it carried the added video', () async {
    final peer = connection();
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);
    final line = peer.fakeTransceivers.last..negotiatedDirection = null;

    line.mid = '';
    expect(await share.videoOffered('a', peer), isFalse, reason: 'an earlier offer, without the line');

    line.mid = '1';
    expect(await share.videoOffered('a', peer), isTrue, reason: 'the line is in the offer out now');
  });

  test('a refused consent leaves no share and starts no service', () async {
    capturer.consent = false;
    final attempt = share.begin('a')!;

    expect(await share.capture('a', attempt), ScreenShareCaptureResult.refused);

    expect(capturer.steps, ['consent']);
    expect(share.statusOf('a'), isNull);
  });

  test('a refused service fails the share before any capture, and is stopped', () async {
    capturer.serviceError = Exception('mediaProjection refused');
    final attempt = share.begin('a')!;

    expect(await share.capture('a', attempt), ScreenShareCaptureResult.failed);

    // The start may have failed only on this side, by its timeout, with the service on its way.
    expect(capturer.steps, ['consent', 'start service', 'stop service']);
    expect(share.statusOf('a'), isNull);
  });

  test('a capture that fails because the share was stopped meanwhile is cancelled, not failed', () async {
    capturer.captureGate = Completer<void>();
    final attempt = share.begin('a')!;
    final capturing = share.capture('a', attempt);
    await pumpEventQueue();

    // The stop takes the service away, and the capture under way throws for it.
    await share.stop('a');
    capturer.captureError = Exception('no foreground service');
    capturer.captureGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
    expect(capturer.serviceRunning, isFalse);
  });

  test('a capture that fails with a stop asked for and not yet run is cancelled', () async {
    capturer.captureError = Exception('no foreground service');
    final attempt = share.begin('a')!;
    share.markStopping('a');

    expect(await share.capture('a', attempt), ScreenShareCaptureResult.cancelled);
  });

  test('a consent that fails for a share stopped meanwhile is cancelled', () async {
    capturer.consentGate = Completer<void>();
    capturer.consentError = Exception('activity gone');
    final attempt = share.begin('a')!;
    final capturing = share.capture('a', attempt);

    await share.stop('a');
    capturer.consentGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
  });

  test('a failed capture stops the service it started', () async {
    capturer.captureError = Exception('no projection');
    final attempt = share.begin('a')!;

    expect(await share.capture('a', attempt), ScreenShareCaptureResult.failed);

    expect(capturer.steps, ['consent', 'start service', 'capture', 'stop service']);
    expect(share.statusOf('a'), isNull);
  });

  test('a stop while the consent is open cancels the share without a service', () async {
    capturer.consentGate = Completer<void>();
    final attempt = share.begin('a')!;
    final capturing = share.capture('a', attempt);

    expect((await share.stop('a'))?.attached, isFalse);
    capturer.consentGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
    expect(capturer.steps, ['consent']);
    expect(capturer.serviceRunning, isFalse);
  });

  test('a stop after the capture and before the attach releases both', () async {
    final attempt = await captured('a');

    await share.stop('a');

    expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
    expect(capturer.serviceRunning, isFalse);
    expect(
      await share.attach('a', attempt, peerConnection: connection(), localStream: null),
      ScreenShareAttachResult.cancelled,
    );
  });

  test('a stop for an earlier attempt leaves the newer one alone', () async {
    final first = share.begin('a')!;
    await share.stop('a');
    await captured('a');

    expect(await share.stop('a', attempt: first), isNull);
    expect(share.statusOf('a'), ScreenShareStatus.starting);
    expect(capturer.serviceRunning, isTrue);
  });

  test('one share at a time', () async {
    expect(share.begin('a'), isNotNull);
    expect(share.begin('b'), isNull);
    expect(share.begin('a'), isNull);
  });

  test('a stop is asked for once', () async {
    share.begin('a');

    expect(share.markStopping('a'), isTrue);
    expect(share.markStopping('a'), isFalse);
    expect(share.markStopping('b'), isFalse);
  });

  test('every change of a share is reported as it happens', () async {
    final peer = connection();
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);
    await share.stop('a', peerConnection: peer);

    expect(changes, [('a', ScreenShareStatus.starting), ('a', ScreenShareStatus.sharing), ('a', null)]);
  });

  test('a stop is reported once the camera is back on the sender', () async {
    final localStream = media.buildSync();
    final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
    unawaited(localStream.addTrack(camera));
    final peer = connection(camera: camera);
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: localStream);
    final sender = peer.fakeSenders.last..gate = Completer<void>();

    final stopping = share.stop('a', peerConnection: peer);
    await pumpEventQueue();
    expect(changes.last, ('a', ScreenShareStatus.sharing), reason: 'the preview that follows must find the camera');

    sender.gate!.complete();
    await stopping;
    expect(changes.last, ('a', null));
    expect(localStream.getVideoTracks(), hasLength(1));
  });

  test('a refused consent is reported the moment it is known', () async {
    capturer.consent = false;
    final attempt = share.begin('a')!;

    await share.capture('a', attempt);

    expect(changes.last, ('a', null));
  });

  test('an end outside the app is reported for the call sharing', () async {
    await captured('a');

    capturer.endOutside();
    await pumpEventQueue();

    expect(endedOutside, ['a']);
  });

  test('dispose releases a running share', () async {
    final peer = connection(
      camera: FakeMediaStreamTrack(kind: 'video', id: 'camera'),
    );
    final attempt = await captured('a');
    await share.attach('a', attempt, peerConnection: peer, localStream: null);

    await share.dispose();

    expect(capturer.serviceRunning, isFalse);
    expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
  });
}
