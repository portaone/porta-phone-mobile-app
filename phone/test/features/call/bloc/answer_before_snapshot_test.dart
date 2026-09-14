import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// A call answered from the native notification before the session snapshot
/// arrives waits for its offer; the offer wakes it, and it opens the camera
/// according to the flags it finds. So the caller's last camera state has to
/// arrive with the offer, not after it.
///
/// The probes were written by the follow-up review of the hub snapshot change
/// and are adopted as its coverage.
class _RecordingMediaBuilder extends Fake implements UserMediaBuilder {
  final requestedVideo = <bool>[];
  final reached = Completer<void>();

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    requestedVideo.add(video);
    if (!reached.isCompleted) reached.complete();
    // The media request is the boundary under test; nothing native runs here.
    throw const WebtritSignalingTransactionTerminateByDisconnectException(1, 'test', null, 'media boundary');
  }
}

/// The session as the hub would render it: a video offer for the push call,
/// then the caller's latest camera state.
StateHandshake _cameraSnapshot({required bool cameraEnabled}) {
  final buffer = SignalingEventBuffer();
  buffer.onEvent(
    SignalingHandshakeReceived(
      handshake: const StateHandshake(
        keepaliveInterval: Duration(seconds: 30),
        timestamp: 1,
        registration: Registration(status: RegistrationStatus.registered),
        lines: [null],
        presenceInfos: [],
        dialogInfos: [],
        guestLine: null,
      ),
    ),
  );
  buffer.onEvent(
    SignalingProtocolEvent(
      event: const IncomingCallEvent(
        line: 0,
        callId: 'push-call',
        caller: '100',
        callee: '200',
        jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 RTP/AVP 0\r\nm=video 9 RTP/AVP 96\r\n'},
      ),
    ),
  );
  buffer.onEvent(
    SignalingProtocolEvent(
      event: MediaStatePeerMessageEvent(line: 0, callId: 'push-call', video: cameraEnabled),
    ),
  );
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

StateHandshake _cameraOffSnapshot() => _cameraSnapshot(cameraEnabled: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an answer after the snapshot opens audio only', () async {
    final media = _RecordingMediaBuilder();
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);

    h.signaling.emitHandshake(_cameraOffSnapshot());
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.remoteCameraEnabled, isFalse);

    await h.bloc.performAnswerCall('push-call');
    await media.reached.future.timeout(const Duration(seconds: 2));
    await pumpEventQueue();

    expect(media.requestedVideo, [false]);
  });

  test('an answer waiting for the snapshot opens audio only once the offer arrives', () async {
    final media = _RecordingMediaBuilder();
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);
    // The state a video push leaves before the signaling offer: video on, no
    // word from the caller's camera yet.
    final call = ActiveCall(
      callId: 'push-call',
      line: -1,
      direction: CallDirection.incoming,
      handle: const CallkeepHandle.number('100'),
      createdTime: DateTime(2026),
      video: true,
      processingStatus: CallProcessingStatus.incomingFromPush,
    );
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(h.bloc.state.copyWithPushActiveCall(call));

    await h.bloc.performAnswerCall('push-call');
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.processingStatus, CallProcessingStatus.incomingPerformingStarted);
    expect(media.requestedVideo, isEmpty, reason: 'the answer waits for the offer');

    h.signaling.emitHandshake(_cameraOffSnapshot());
    await media.reached.future.timeout(const Duration(seconds: 2));
    await pumpEventQueue();

    expect(media.requestedVideo, [false], reason: 'the camera state came with the offer that woke the answer');
  });

  // The push says what the native side was told, the snapshot what the caller
  // offered and last reported. The answer follows the offer and the camera
  // state, whichever order the answer and the snapshot came in - the push
  // flag is a placeholder, not a veto.
  for (final pushVideo in [false, true]) {
    for (final cameraEnabled in [false, true]) {
      for (final answerFirst in [false, true]) {
        test(
          'push video=$pushVideo, camera=$cameraEnabled, answer first=$answerFirst opens the camera=$cameraEnabled',
          () async {
            final media = _RecordingMediaBuilder();
            final h = CallBlocHarness(userMediaBuilder: media);
            addTearDown(h.close);
            h.bloc.didPushIncomingCall(const CallkeepHandle.number('100'), null, pushVideo, 'push-call', null);
            await pumpEventQueue();
            expect(h.bloc.state.activeCalls.single.video, pushVideo);
            expect(h.bloc.state.activeCalls.single.incomingOffer, isNull);
            if (answerFirst) {
              await h.bloc.performAnswerCall('push-call');
              await pumpEventQueue();
              expect(media.requestedVideo, isEmpty, reason: 'the answer waits for the offer');
            }

            h.signaling.emitHandshake(_cameraSnapshot(cameraEnabled: cameraEnabled));
            await pumpEventQueue();
            if (!answerFirst) await h.bloc.performAnswerCall('push-call');
            await media.reached.future.timeout(const Duration(seconds: 2));
            await pumpEventQueue();

            expect(media.requestedVideo, [cameraEnabled]);
          },
        );
      }
    }
  }
}
