import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/features/call/utils/utils.dart';

import '../bloc/call_bloc_harness.dart';

/// A destination that records what was asked of it.
class _Destination implements ScreenShareDestination {
  final List<String> steps = [];
  ScreenShareAttachResult result = ScreenShareAttachResult.attached;
  Future<void> Function()? onDetach;
  bool cameraLost = false;

  @override
  Future<ScreenShareAttachResult> attach(MediaStream screen) async {
    steps.add('attach ${screen.getVideoTracks().single.id}');
    return result;
  }

  @override
  Future<bool> detach() async {
    steps.add('detach');
    await onDetach?.call();
    return cameraLost;
  }
}

void main() {
  late FakeScreenCapturer capturer;
  late FakeUserMediaBuilder media;
  late int endedOutside;
  late List<ScreenShareState?> changes;
  late ScreenShare share;

  const call = CallScreenShareTarget('a');

  setUp(() {
    capturer = FakeScreenCapturer();
    media = FakeUserMediaBuilder();
    endedOutside = 0;
    changes = [];
    share = ScreenShare(
      capturer: capturer,
      onEndedOutside: () => endedOutside++,
      onChanged: () => changes.add(share.state),
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

  Future<Object> captured([ScreenShareTarget target = call]) async {
    final attempt = share.begin(target)!;
    expect(await share.capture(attempt), ScreenShareCaptureResult.captured);
    return attempt;
  }

  CallSenderDestination sender(FakePeerConnection peer, {MediaStream? localStream, bool? frontCamera}) =>
      CallSenderDestination(
        peerConnection: peer,
        localStream: localStream,
        userMedia: media,
        frontCamera: () => frontCamera,
      );

  test('the consent comes first, the service before the capture', () async {
    await captured();

    expect(capturer.steps, ['consent', 'start service', 'capture']);
    expect(share.state, const ScreenShareState(target: call, status: ScreenShareStatus.starting));
  });

  group('the destination', () {
    test('gets the screen, and lets it go before the capture is released', () async {
      final destination = _Destination();
      final attempt = await captured(const RoomScreenShareTarget());
      final track = capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack;
      destination.onDetach = () async => destination.steps.add('capture stopped: ${track.stopped}');

      expect(await share.attach(attempt, destination), ScreenShareAttachResult.attached);
      expect(share.state?.status, ScreenShareStatus.sharing);
      final stopped = await share.stop();

      expect(destination.steps, ['attach screen-1', 'detach', 'capture stopped: false']);
      expect(stopped?.attached, isTrue);
      expect(track.stopped, isTrue);
      expect(capturer.serviceRunning, isFalse);
    });

    test('the share is said gone once the destination has put the camera back', () async {
      final destination = _Destination();
      final detach = Completer<void>();
      destination.onDetach = () => detach.future;
      final attempt = await captured();
      await share.attach(attempt, destination);
      final reported = changes.length;

      final stopping = share.stop();
      await pumpEventQueue();

      expect(changes, hasLength(reported), reason: 'the preview that follows must find the camera');
      expect(share.begin(const CallScreenShareTarget('b')), isNull, reason: 'the slot is not free while it stops');
      detach.complete();
      await stopping;
      expect(changes.last, isNull);
    });

    test('that refuses the screen leaves the share starting, for the coordinator to stop', () async {
      final destination = _Destination()..result = ScreenShareAttachResult.failed;
      final attempt = await captured();

      expect(await share.attach(attempt, destination), ScreenShareAttachResult.failed);
      expect(share.state?.status, ScreenShareStatus.starting);
    });

    test('a detach that throws still releases the capture', () async {
      final destination = _Destination()..onDetach = () async => throw StateError('room gone');
      final attempt = await captured();
      await share.attach(attempt, destination);

      await share.stop();

      expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
      expect(capturer.serviceRunning, isFalse);
    });

    test('a camera that does not come back is said by the stop', () async {
      final destination = _Destination()..cameraLost = true;
      final attempt = await captured();
      await share.attach(attempt, destination);

      expect((await share.stop())?.cameraLost, isTrue);
    });
  });

  group('a call\'s sender', () {
    test('takes the screen in place of the camera, and the stop gives the camera back', () async {
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
      final peer = connection(camera: camera);
      final attempt = await captured();

      final result = await share.attach(attempt, sender(peer));

      final videoSender = peer.fakeSenders.last;
      expect(result, ScreenShareAttachResult.attached);
      expect(videoSender.track?.id, 'screen-1');
      expect(peer.addedTracks, [camera], reason: 'no second video line');

      final stopped = await share.stop();

      expect(stopped?.attached, isTrue);
      expect(videoSender.track, same(camera), reason: 'not the call\'s own camera: kept as it was');
    });

    test('lets the call\'s own camera go while the screen is out and opens it again, as it was', () async {
      final localStream = media.buildSync();
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera')..enabled = false;
      unawaited(localStream.addTrack(camera));
      final peer = connection(camera: camera);
      final attempt = await captured();

      await share.attach(attempt, sender(peer, localStream: localStream, frontCamera: false));
      expect(camera.stopped, isTrue, reason: 'nothing captures the camera behind the screen');
      expect(localStream.getVideoTracks(), isEmpty);

      final stopped = await share.stop();

      final reopened = media.camerasOpened.single;
      expect(stopped?.cameraLost, isFalse);
      expect(peer.fakeSenders.last.track, same(reopened));
      expect(reopened.enabled, isFalse, reason: 'a soft-muted camera comes back soft-muted');
      expect(media.reopenFrontCameras.last, isFalse);
    });

    test('a camera that does not open again leaves the sender empty and says so', () async {
      final localStream = media.buildSync();
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
      unawaited(localStream.addTrack(camera));
      final peer = connection(camera: camera);
      final attempt = await captured();
      await share.attach(attempt, sender(peer, localStream: localStream));
      media.cameraError = Exception('camera in use');

      final stopped = await share.stop();

      expect(stopped?.cameraLost, isTrue);
      expect(peer.fakeSenders.last.track, isNull);
    });

    test('a call going away gets no camera back', () async {
      final localStream = media.buildSync();
      final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
      unawaited(localStream.addTrack(camera));
      final peer = connection(camera: camera);
      final attempt = await captured();
      await share.attach(attempt, sender(peer, localStream: localStream));
      peer.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateClosed;

      await share.stop();

      expect(media.camerasOpened, isEmpty);
    });

    test('an audio call gets a video sender for the screen, empty again after the stop', () async {
      final peer = connection();
      final attempt = await captured();
      final destination = sender(peer);

      expect(await share.attach(attempt, destination), ScreenShareAttachResult.attachedWithNewVideo);
      expect(destination.awaitsVideo, isTrue);
      await share.stop();

      final videoSender = peer.fakeSenders.last;
      expect(videoSender.track, isNull, reason: 'the camera was off: nothing goes back');
      expect(await peer.videoSender(), same(videoSender), reason: 'the camera turned on later finds this sender');
    });

    test('the far end refusing the added video is seen in the answer', () async {
      final peer = connection();
      final destination = sender(peer);
      await share.attach(await captured(), destination);

      peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.Inactive;

      expect(await destination.videoAnswer(), ScreenShareVideoAnswer.refused);
      expect(destination.awaitsVideo, isTrue);
    });

    test('an answer that takes the added video settles the wait', () async {
      final peer = connection();
      final destination = sender(peer);
      await share.attach(await captured(), destination);

      peer.fakeTransceivers.last.negotiatedDirection = TransceiverDirection.SendOnly;

      expect(await destination.videoAnswer(), ScreenShareVideoAnswer.sends);
      expect(destination.awaitsVideo, isFalse);
    });

    test('an answer to an offer made before the added video decides nothing', () async {
      final peer = connection();
      final destination = sender(peer);
      await share.attach(await captured(), destination);

      // The line was in no offer the answer answered: it has no negotiated direction yet.
      peer.fakeTransceivers.last
        ..mid = ''
        ..negotiatedDirection = null;

      expect(await destination.videoAnswer(), ScreenShareVideoAnswer.pending);
      expect(destination.awaitsVideo, isTrue);
    });

    test('a refused offer counts only when it carried the added video', () async {
      final peer = connection();
      final destination = sender(peer);
      await share.attach(await captured(), destination);
      final line = peer.fakeTransceivers.last..negotiatedDirection = null;

      line.mid = '';
      expect(await destination.videoOffered(), isFalse, reason: 'an earlier offer, without the line');

      line.mid = '1';
      expect(await destination.videoOffered(), isTrue, reason: 'the line is in the offer out now');
    });
  });

  test('a refused consent leaves no share and starts no service', () async {
    capturer.consent = false;
    final attempt = share.begin(call)!;

    expect(await share.capture(attempt), ScreenShareCaptureResult.refused);

    expect(capturer.steps, ['consent']);
    expect(share.state, isNull);
  });

  test('a refused service fails the share before any capture, and is stopped', () async {
    capturer.serviceError = Exception('mediaProjection refused');
    final attempt = share.begin(call)!;

    expect(await share.capture(attempt), ScreenShareCaptureResult.failed);

    // The start may have failed only on this side, by its timeout, with the service on its way.
    expect(capturer.steps, ['consent', 'start service', 'stop service']);
    expect(share.state, isNull);
  });

  test('a capture that fails because the share was stopped meanwhile is cancelled, not failed', () async {
    capturer.captureGate = Completer<void>();
    final attempt = share.begin(call)!;
    final capturing = share.capture(attempt);
    await pumpEventQueue();

    // The stop takes the service away, and the capture under way throws for it.
    await share.stop();
    capturer.captureError = Exception('no foreground service');
    capturer.captureGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
    expect(capturer.serviceRunning, isFalse);
  });

  test('a capture that fails with a stop asked for and not yet run is cancelled', () async {
    capturer.captureError = Exception('no foreground service');
    final attempt = share.begin(call)!;
    share.markStopping();

    expect(await share.capture(attempt), ScreenShareCaptureResult.cancelled);
  });

  test('a consent that fails for a share stopped meanwhile is cancelled', () async {
    capturer.consentGate = Completer<void>();
    capturer.consentError = Exception('activity gone');
    final attempt = share.begin(call)!;
    final capturing = share.capture(attempt);

    await share.stop();
    capturer.consentGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
  });

  test('a failed capture stops the service it started', () async {
    capturer.captureError = Exception('no projection');
    final attempt = share.begin(call)!;

    expect(await share.capture(attempt), ScreenShareCaptureResult.failed);

    expect(capturer.steps, ['consent', 'start service', 'capture', 'stop service']);
    expect(share.state, isNull);
  });

  test('a stop while the consent is open cancels the share without a service', () async {
    capturer.consentGate = Completer<void>();
    final attempt = share.begin(call)!;
    final capturing = share.capture(attempt);

    expect((await share.stop())?.attached, isFalse);
    capturer.consentGate!.complete();

    expect(await capturing, ScreenShareCaptureResult.cancelled);
    expect(capturer.steps, ['consent']);
    expect(capturer.serviceRunning, isFalse);
  });

  test('a stop after the capture and before the attach releases both', () async {
    final attempt = await captured();

    await share.stop();

    expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
    expect(capturer.serviceRunning, isFalse);
    expect(await share.attach(attempt, _Destination()), ScreenShareAttachResult.cancelled);
  });

  test('a stop asked for before the attach leaves the screen out of the destination', () async {
    final attempt = await captured();
    share.markStopping();
    final destination = _Destination();

    expect(await share.attach(attempt, destination), ScreenShareAttachResult.cancelled);
    expect(destination.steps, isEmpty);
  });

  test('a stop for an earlier attempt leaves the newer one alone', () async {
    final first = share.begin(call)!;
    await share.stop();
    await captured();

    expect(await share.stop(attempt: first), isNull);
    expect(share.state?.status, ScreenShareStatus.starting);
    expect(capturer.serviceRunning, isTrue);
  });

  test('one share at a time', () async {
    expect(share.begin(call), isNotNull);
    expect(share.begin(const CallScreenShareTarget('b')), isNull);
    expect(share.begin(const RoomScreenShareTarget()), isNull);
  });

  test('a stop is asked for once', () async {
    expect(share.markStopping(), isFalse, reason: 'no share');
    share.begin(call);

    expect(share.markStopping(), isTrue);
    expect(share.markStopping(), isFalse);
  });

  test('every change of the share is reported as it happens', () async {
    final attempt = await captured();
    await share.attach(attempt, _Destination());
    await share.stop();

    expect(changes, [
      const ScreenShareState(target: call, status: ScreenShareStatus.starting),
      const ScreenShareState(target: call, status: ScreenShareStatus.sharing),
      null,
    ]);
  });

  test('a refused consent is reported the moment it is known', () async {
    capturer.consent = false;
    final attempt = share.begin(call)!;

    await share.capture(attempt);

    expect(changes.last, isNull);
  });

  test('an end outside the app is reported while a share runs', () async {
    await captured();

    capturer.endOutside();
    await pumpEventQueue();

    expect(endedOutside, 1);
  });

  test('dispose releases a running share', () async {
    final attempt = await captured();
    await share.attach(attempt, _Destination());

    await share.dispose();

    expect(capturer.serviceRunning, isFalse);
    expect((capturer.lastCapture!.getVideoTracks().single as FakeMediaStreamTrack).stopped, isTrue);
  });
}
