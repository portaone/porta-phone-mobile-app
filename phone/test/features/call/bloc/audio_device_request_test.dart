import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Which audio device the call screen shows after the person asked for one.
/// Moving the audio takes the system about 0.4 s on an iPhone, and a button
/// that waits for the route to be reported looks dead for that long. Where the
/// route is reported after every request, the device asked for is shown at
/// once - apart from the route in use, so a route read while the audio is still
/// moving does not put the old device back - and the first report after the
/// request is over has the last word. Where a refused request leaves no report,
/// the button keeps following the platform.
void main() {
  late CallBlocHarness h;
  late _MediaManager media;

  const speaker = CallAudioDevice(type: CallAudioDeviceType.speaker, name: 'Speaker');
  const earpiece = CallAudioDevice(type: CallAudioDeviceType.earpiece, name: 'Receiver');
  const headset = CallAudioDevice(type: CallAudioDeviceType.bluetooth, name: 'Headset');

  /// Longer than the debounce the route reports go through.
  Future<void> reportIsRead() => Future<void>.delayed(const Duration(milliseconds: 400));

  tearDown(() async {
    // A request a test left running would keep the bloc from closing.
    media.release();
    await h.close();
  });

  group('a platform that reports the route after every request', () {
    setUp(() async {
      h = CallBlocHarness(mediaManager: (callkeep) => media = _MediaManager(callkeep, reportsRoute: true));
      h.seedEstablishedCall('a');
      media.route = earpiece;
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', earpiece));
      await reportIsRead();
      expect(h.bloc.state.audioDevice, earpiece, reason: 'the call starts on the earpiece');
      expect(h.bloc.state.audioDeviceRequest, isNull);
    });

    test('shows the device asked for while the route in use is still the old one', () async {
      media.hold();
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      await pumpEventQueue();

      expect(h.bloc.state.shownAudioDevice, speaker);
      expect(h.bloc.state.audioDevice, earpiece);
    });

    test('keeps showing it through a route read while the request is still running', () async {
      media.hold();
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      await pumpEventQueue();

      // The plugin reports a route on the way: the old device is still in use.
      navigator.mediaDevices.ondevicechange?.call(null);
      await reportIsRead();

      expect(h.bloc.state.shownAudioDevice, speaker);
      expect(h.bloc.state.audioDevice, earpiece);
    });

    test('gives way to the route reported after the request is over', () async {
      media.hold();
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      await pumpEventQueue();

      media.route = speaker;
      media.release();
      await reportIsRead();

      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.audioDevice, speaker);
      expect(h.bloc.state.shownAudioDevice, speaker);
    });

    test('shows the route in use when the platform took the audio elsewhere', () async {
      media.hold();
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      await pumpEventQueue();

      media.route = headset;
      media.release();
      await reportIsRead();

      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.shownAudioDevice, headset);
    });

    test('reads the route back after a request that failed', () async {
      // The failure is the handler's to report; here it is only kept from failing the test.
      await h.close();
      final failures = <Object>[];
      await runZonedGuarded(() async {
        h = CallBlocHarness(mediaManager: (callkeep) => media = _MediaManager(callkeep, reportsRoute: true));
        h.seedEstablishedCall('a');
        media.route = earpiece;
        media.hold();
        h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
        await pumpEventQueue();
        expect(h.bloc.state.shownAudioDevice, speaker);

        media.release(error: StateError('the session refused'));
        await reportIsRead();
      }, (error, _) => failures.add(error));

      expect(failures, [isA<StateError>()]);
      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.shownAudioDevice, earpiece);
    });

    test('the second of two quick requests is the one shown until its own report', () async {
      media.hold();
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', earpiece));
      await pumpEventQueue();

      // The first request ends on the speaker; the second starts at once and is held.
      media.route = speaker;
      media.release();
      media.hold();
      await reportIsRead();

      expect(h.bloc.state.audioDevice, speaker, reason: 'the report of the first request was read');
      expect(h.bloc.state.shownAudioDevice, earpiece, reason: 'but the second request is still running');

      media.route = earpiece;
      media.release();
      await reportIsRead();

      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.shownAudioDevice, earpiece);
    });

    test('shows nothing for a call that is not there', () async {
      h.bloc.add(const CallControlEvent.audioDeviceSet('gone', speaker));
      await pumpEventQueue();

      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.shownAudioDevice, earpiece);
    });
  });

  group('a platform that reports only a route it moved to', () {
    final earpieceOfPlatform = CallkeepAudioDevice(type: CallkeepAudioDeviceType.earpiece, name: 'Earpiece');
    final speakerOfPlatform = CallkeepAudioDevice(type: CallkeepAudioDeviceType.speaker, name: 'Speaker');

    setUp(() async {
      h = CallBlocHarness(mediaManager: (callkeep) => media = _MediaManager(callkeep, reportsRoute: false));
      h.seedEstablishedCall('a');
      await h.bloc.performAudioDevicesUpdate('a', [earpieceOfPlatform, speakerOfPlatform]);
      await h.bloc.performAudioDeviceSet('a', earpieceOfPlatform);
      await pumpEventQueue();
    });

    test('keeps the device in use until the platform reports another', () async {
      h.bloc.add(const CallControlEvent.audioDeviceSet('a', speaker));
      await pumpEventQueue();

      expect(h.bloc.state.audioDeviceRequest, isNull);
      expect(h.bloc.state.shownAudioDevice?.type, CallAudioDeviceType.earpiece);

      await h.bloc.performAudioDeviceSet('a', speakerOfPlatform);
      await pumpEventQueue();
      expect(h.bloc.state.shownAudioDevice?.type, CallAudioDeviceType.speaker);
    });
  });
}

/// The app's media manager with the platform's part played by the test: which kind of platform it
/// is, how long a request takes and what the audio session reports as the route in use.
class _MediaManager extends CallMediaManager {
  _MediaManager(Callkeep callkeep, {required this.reportsRoute}) : super(callkeep: callkeep);

  final bool reportsRoute;

  CallAudioDevice route = const CallAudioDevice(type: CallAudioDeviceType.earpiece, name: 'Receiver');

  Completer<void>? _held;

  /// The next request does not finish until [release].
  void hold() => _held = Completer<void>();

  void release({Object? error}) {
    final held = _held;
    _held = null;
    error == null ? held?.complete() : held?.completeError(error);
  }

  @override
  bool get reportsRouteAfterEveryRequest => reportsRoute;

  @override
  Future<void> setDevice(String callId, CallAudioDevice device, {required bool hasVideo}) async => _held?.future;

  @override
  Future<({List<CallAudioDevice> available, CallAudioDevice current})> readRoute() async {
    return (
      available: [
        const CallAudioDevice(type: CallAudioDeviceType.speaker),
        route,
      ],
      current: route,
    );
  }
}
