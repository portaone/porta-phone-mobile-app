import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/features/call/utils/utils.dart';

import '../bloc/call_bloc_harness.dart';

class _FakeService extends Fake implements CallkeepScreenShare {
  final List<String> calls = [];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  void setDelegate(CallkeepScreenShareDelegate? delegate) => calls.add(delegate == null ? 'clear' : 'delegate');
}

class _FakeBroadcast implements ScreenBroadcast {
  final controller = StreamController<ScreenBroadcastEvent>.broadcast(sync: true);

  @override
  Stream<ScreenBroadcastEvent> get events => controller.stream;
}

void main() {
  late _FakeService service;
  late _FakeBroadcast broadcast;
  late List<Map<String, dynamic>> opened;
  late FakeMediaStreamTrack track;
  late Completer<MediaStream>? openGate;

  setUp(() {
    service = _FakeService();
    broadcast = _FakeBroadcast();
    opened = [];
    track = FakeMediaStreamTrack(kind: 'video', id: 'screen');
    openGate = null;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<MediaStream> open(Map<String, dynamic> constraints) async {
    opened.add(constraints);
    return openGate?.future ?? FakeMediaStream('screen', tracks: [track]);
  }

  DefaultScreenCapturer capturer({ScreenBroadcast? withBroadcast, Duration timeout = const Duration(seconds: 5)}) =>
      DefaultScreenCapturer(
        service: service,
        broadcast: withBroadcast,
        displayMedia: open,
        broadcastStartTimeout: timeout,
      );

  group('iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('a build without the screen share extension cannot share', () async {
      final subject = capturer();

      expect(subject.isSupported, isFalse);
      await subject.dispose();
    });

    test('the system picker is the consent and there is no service', () async {
      final subject = capturer(withBroadcast: broadcast);

      expect(subject.isSupported, isTrue);
      expect(await subject.requestConsent(), isTrue);
      await subject.startService();
      await subject.stopService();
      expect(service.calls, isEmpty);
      await subject.dispose();
    });

    test('the capture opens the broadcast and counts once the extension started', () async {
      final subject = capturer(withBroadcast: broadcast);

      var done = false;
      final capture = subject.capture().whenComplete(() => done = true);
      await pumpEventQueue();
      expect(opened.single, {
        'audio': false,
        'video': {'deviceId': 'broadcast'},
      });
      expect(done, isFalse);

      broadcast.controller.add(ScreenBroadcastEvent.started);
      expect((await capture).getVideoTracks().single.id, 'screen');
      expect(track.stopped, isFalse);
      await subject.dispose();
    });

    test('a picker the person dismissed gives up after the timeout and closes the capture', () async {
      final subject = capturer(withBroadcast: broadcast, timeout: const Duration(milliseconds: 10));

      await expectLater(subject.capture(), throwsA(isA<TimeoutException>()));
      expect(track.stopped, isTrue);
      await subject.dispose();
    });

    test('a broadcast that stops before it started fails the capture', () async {
      final subject = capturer(withBroadcast: broadcast);

      final capture = subject.capture();
      await pumpEventQueue();
      broadcast.controller.add(ScreenBroadcastEvent.stopped);

      await expectLater(capture, throwsStateError);
      expect(track.stopped, isTrue);
      await subject.dispose();
    });

    test('a stop while the picker is open ends the capture', () async {
      final subject = capturer(withBroadcast: broadcast);

      final capture = subject.capture();
      await pumpEventQueue();
      await subject.stopService();

      await expectLater(capture, throwsStateError);
      expect(track.stopped, isTrue);
      await subject.dispose();
    });

    test('a stop before the broadcast was even opened is no unhandled error', () async {
      final subject = capturer(withBroadcast: broadcast);
      openGate = Completer<MediaStream>();

      final capture = subject.capture();
      await pumpEventQueue();
      await subject.stopService();
      openGate!.complete(FakeMediaStream('screen', tracks: [track]));

      await expectLater(capture, throwsStateError);
      expect(track.stopped, isTrue);
      await subject.dispose();
    });

    test('the broadcast stopped outside the app is an end outside the app', () async {
      final subject = capturer(withBroadcast: broadcast);
      var ended = 0;
      subject.endedOutside.listen((_) => ended++);

      final capture = subject.capture();
      await pumpEventQueue();
      broadcast.controller.add(ScreenBroadcastEvent.started);
      await capture;
      broadcast.controller.add(ScreenBroadcastEvent.stopped);
      await pumpEventQueue();

      expect(ended, 1);
      await subject.dispose();
    });

    test('the broadcast stopping after the app stopped the share is the app\'s own stop', () async {
      final subject = capturer(withBroadcast: broadcast);
      var ended = 0;
      subject.endedOutside.listen((_) => ended++);

      final capture = subject.capture();
      await pumpEventQueue();
      broadcast.controller.add(ScreenBroadcastEvent.started);
      await capture;
      await subject.stopService();
      broadcast.controller.add(ScreenBroadcastEvent.stopped);
      await pumpEventQueue();

      expect(ended, 0);
      await subject.dispose();
    });

    test('a dismissed picker leaves no share behind', () async {
      final subject = capturer(withBroadcast: broadcast, timeout: const Duration(milliseconds: 10));
      final share = ScreenShare(capturer: subject, onEndedOutside: () {}, onChanged: () {});

      final attempt = share.begin(const CallScreenShareTarget('a'))!;
      expect(await share.capture(attempt), ScreenShareCaptureResult.failed);
      expect(share.state, isNull);
      expect(track.stopped, isTrue);

      await share.dispose();
      await subject.dispose();
    });

    test('a share stopped while the picker is open is cancelled', () async {
      final subject = capturer(withBroadcast: broadcast);
      final share = ScreenShare(capturer: subject, onEndedOutside: () {}, onChanged: () {});

      final attempt = share.begin(const CallScreenShareTarget('a'))!;
      final capture = share.capture(attempt);
      await pumpEventQueue();
      await share.stop();

      expect(await capture, ScreenShareCaptureResult.cancelled);
      expect(track.stopped, isTrue);

      await share.dispose();
      await subject.dispose();
    });
  });

  group('Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('shares through the service and a plain display capture', () async {
      final subject = capturer();

      expect(subject.isSupported, isTrue);
      await subject.startService();
      await subject.capture();
      await subject.stopService();
      await subject.dispose();

      expect(service.calls, ['delegate', 'start', 'stop', 'clear']);
      expect(opened.single, {'audio': false, 'video': true});
    });
  });
}
