import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_webrtc_noise_suppression/flutter_webrtc_noise_suppression.dart';

import 'package:webtrit_phone/features/call/utils/voice_noise_reduction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/voice_noise_reduction');
  late List<String> calls;
  late Object? Function(String method) answer;

  setUp(() {
    calls = [];
    answer = (_) => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      final result = answer(call.method);
      if (result is Exception) throw result;
      return result;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('a mark left by a microphone that never reported its release goes when the choice is off', () async {
    var enabled = true;
    answer = (_) => false;
    final subject = VoiceNoiseReduction(
      isEnabled: () => enabled,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    expect(subject.failed.value, isTrue);

    enabled = false;
    await subject.onAudioTrackAcquired();

    expect(subject.failed.value, isFalse);
  });

  test('a throwing attach is a failure even after an attach whose release was never reported', () async {
    final subject = VoiceNoiseReduction(
      isEnabled: () => true,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    expect(subject.failed.value, isFalse);

    answer = (_) => PlatformException(code: 'unknown_engine');
    await subject.onAudioTrackAcquired();

    expect(subject.failed.value, isTrue);
  });

  test('does not reach the platform when the user left it off', () async {
    final subject = VoiceNoiseReduction(
      isEnabled: () => false,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    await subject.onAudioTrackReleased();

    expect(calls, isEmpty);
  });

  test('attaches on acquire and detaches on release when on', () async {
    final subject = VoiceNoiseReduction(
      isEnabled: () => true,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    await subject.onAudioTrackReleased();

    expect(calls, ['attach', 'detach']);
  });

  test('detaches what it attached even if the user turned it off during the call', () async {
    var enabled = true;
    final subject = VoiceNoiseReduction(
      isEnabled: () => enabled,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    enabled = false;
    await subject.onAudioTrackReleased();

    expect(calls, ['attach', 'detach']);
  });

  test('does not detach when the platform could not attach', () async {
    answer = (_) => false;
    final subject = VoiceNoiseReduction(
      isEnabled: () => true,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await subject.onAudioTrackAcquired();
    await subject.onAudioTrackReleased();

    expect(calls, ['attach']);
  });

  test('a platform failure does not reach the call', () async {
    answer = (method) => PlatformException(code: 'boom');
    final subject = VoiceNoiseReduction(
      isEnabled: () => true,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await expectLater(subject.onAudioTrackAcquired(), completes);
    await expectLater(subject.onAudioTrackReleased(), completes);
  });

  test('a missing bridge does not reach the call', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    final subject = VoiceNoiseReduction(
      isEnabled: () => true,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    await expectLater(subject.onAudioTrackAcquired(), completes);
  });

  group('failed', () {
    VoiceNoiseReduction subject({bool enabled = true}) => VoiceNoiseReduction(
      isEnabled: () => enabled,
      bridge: const WebrtcNoiseSuppressionBridge(channel: channel),
    );

    test('stays false when the reduction starts', () async {
      final reduction = subject();

      await reduction.onAudioTrackAcquired();

      expect(reduction.failed.value, isFalse);
    });

    test('stays false when nobody asked for the reduction', () async {
      answer = (_) => false;
      final reduction = subject(enabled: false);

      await reduction.onAudioTrackAcquired();

      expect(reduction.failed.value, isFalse);
    });

    test('is true when the platform refuses', () async {
      answer = (_) => false;
      final reduction = subject();

      await reduction.onAudioTrackAcquired();

      expect(reduction.failed.value, isTrue);
    });

    test('is true when the platform throws', () async {
      answer = (_) => PlatformException(code: 'failed');
      final reduction = subject();

      await reduction.onAudioTrackAcquired();

      expect(reduction.failed.value, isTrue);
    });

    test('goes when the microphone closes, so the next call starts clean', () async {
      answer = (_) => false;
      final reduction = subject();

      await reduction.onAudioTrackAcquired();
      await reduction.onAudioTrackReleased();

      expect(reduction.failed.value, isFalse);
    });
  });
}
