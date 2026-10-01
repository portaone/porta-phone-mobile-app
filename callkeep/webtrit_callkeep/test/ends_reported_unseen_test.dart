import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

/// The app reports the end of a call it never held, learnt from signaling; the platform can
/// still present that call afterwards (an Android replay on attach, an iOS push registration
/// confirmed late). The fact that the call is over lives in [Callkeep], in the isolate that
/// reported it: the delegate is not handed the call, and the app can ask before applying a
/// presentation it received earlier.
class _FakePlatform extends WebtritCallkeepPlatform with MockPlatformInterfaceMixin {
  CallkeepDelegate? delegate;
  final List<(String, CallkeepEndCallReason)> ended = [];
  CallkeepIncomingCallError? registrationResult;
  Object? registrationError;
  Completer<void>? registrationGate;
  var tearDownCount = 0;

  @override
  void setDelegate(CallkeepDelegate? delegate) => this.delegate = delegate;

  @override
  Future<void> reportEndCall(String callId, String displayName, CallkeepEndCallReason reason) async {
    ended.add((callId, reason));
  }

  @override
  Future<CallkeepIncomingCallError?> reportNewIncomingCall(
    String callId,
    CallkeepHandle handle,
    String? displayName,
    bool hasVideo,
  ) async {
    await registrationGate?.future;
    if (registrationError != null) throw registrationError!;
    return registrationResult;
  }

  @override
  Future<void> tearDown() async => tearDownCount++;

  void present(String callId) =>
      delegate!.didPresentIncomingCall(const CallkeepHandle.number('100'), null, false, callId, null);
}

class _RecordingDelegate implements CallkeepDelegate {
  final List<String> presented = [];
  final List<String> answered = [];

  @override
  void didPresentIncomingCall(
    CallkeepHandle handle,
    String? displayName,
    bool video,
    String callId,
    CallkeepIncomingCallError? error,
  ) => presented.add(callId);

  @override
  Future<bool> performAnswerCall(String callId) async {
    answered.add(callId);
    return true;
  }

  @override
  void continueStartCallIntent(CallkeepHandle handle, String? displayName, bool video) {}
  @override
  Future<bool> performStartCall(String callId, CallkeepHandle handle, String? name, bool video) async => false;
  @override
  Future<bool> performEndCall(String callId) async => false;
  @override
  Future<bool> performSetHeld(String callId, bool onHold) async => false;
  @override
  Future<bool> performSetMuted(String callId, bool muted) async => false;
  @override
  Future<bool> performSendDTMF(String callId, String key) async => false;
  @override
  Future<bool> performAudioDeviceSet(String callId, CallkeepAudioDevice device) async => false;
  @override
  Future<bool> performAudioDevicesUpdate(String callId, List<CallkeepAudioDevice> devices) async => false;
  @override
  Future<bool> performSetCallGroup(String callId, String? groupWithCallId) async => false;
  @override
  void didActivateAudioSession() {}
  @override
  void didDeactivateAudioSession() {}
  @override
  void didReset() {}
}

const _handle = CallkeepHandle.number('100');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlatform platform;
  late _RecordingDelegate delegate;
  late Callkeep callkeep;

  setUp(() async {
    platform = _FakePlatform();
    WebtritCallkeepPlatform.instance = platform;
    callkeep = Callkeep();
    // The singleton outlives tests: start each one with no reported ends.
    await callkeep.tearDown();
    delegate = _RecordingDelegate();
    callkeep.setDelegate(delegate);
  });

  Future<void> reportUnseenEnd(String callId) =>
      callkeep.reportEndCall(callId, '', CallkeepEndCallReason.missedWhileConnecting);

  group('an end reported before the call was held', () {
    test('keeps the delegate from being handed that call, and only that call', () async {
      await reportUnseenEnd('x');

      platform.present('x');
      platform.present('y');

      expect(delegate.presented, ['y']);
      expect(callkeep.wasEndedBeforePresented('x'), isTrue);
      expect(platform.ended, [
        ('x', CallkeepEndCallReason.missedWhileConnecting),
      ], reason: 'the platform still hears the end');
    });

    test('is known before the platform hears of it', () {
      // The record is made synchronously, in the same turn as the call: a presentation the
      // platform has in flight cannot slip between the report and the knowledge.
      unawaited(callkeep.reportEndCall('x', '', CallkeepEndCallReason.missedWhileConnecting));

      expect(callkeep.wasEndedBeforePresented('x'), isTrue);
    });

    test('the end of a call the app held is not recorded: its id stays free for a transfer back', () async {
      await callkeep.reportEndCall('x', 'Alice', CallkeepEndCallReason.remoteEnded);
      await callkeep.reportEndCall('y', 'Bob', CallkeepEndCallReason.unanswered);

      platform.present('x');
      platform.present('y');

      expect(delegate.presented, ['x', 'y']);
      expect(callkeep.wasEndedBeforePresented('x'), isFalse);
    });

    test('every other delegate call is forwarded untouched', () async {
      await reportUnseenEnd('x');

      expect(await platform.delegate!.performAnswerCall('x'), isTrue);
      expect(delegate.answered, ['x']);
    });
  });

  group('reopening the id', () {
    test('a registration the platform accepts as new reopens it', () async {
      await reportUnseenEnd('x');
      platform.registrationResult = null;

      expect(await callkeep.reportNewIncomingCall('x', _handle), isNull);

      expect(callkeep.wasEndedBeforePresented('x'), isFalse);
      platform.present('x');
      expect(delegate.presented, ['x']);
    });

    for (final outcome in [
      CallkeepIncomingCallError.callIdAlreadyExists,
      CallkeepIncomingCallError.callIdAlreadyExistsAndAnswered,
      CallkeepIncomingCallError.callIdAlreadyTerminated,
      CallkeepIncomingCallError.callRejectedBySystem,
    ]) {
      test('a registration answered $outcome leaves the fact as it is', () async {
        await reportUnseenEnd('x');
        platform.registrationResult = outcome;

        expect(await callkeep.reportNewIncomingCall('x', _handle), outcome);

        expect(
          callkeep.wasEndedBeforePresented('x'),
          isTrue,
          reason: 'an adoption may be the old call the platform still holds',
        );
      });
    }

    test('a registration that throws leaves the fact as it is', () async {
      await reportUnseenEnd('x');
      platform.registrationError = StateError('channel gone');

      await expectLater(callkeep.reportNewIncomingCall('x', _handle), throwsStateError);

      expect(callkeep.wasEndedBeforePresented('x'), isTrue);
    });

    test('an end reported while the registration is in flight survives its late success', () async {
      await reportUnseenEnd('x');
      platform.registrationGate = Completer();
      platform.registrationResult = null;
      final registration = callkeep.reportNewIncomingCall('x', _handle);

      await reportUnseenEnd('x');
      platform.registrationGate!.complete();
      expect(await registration, isNull);

      expect(
        callkeep.wasEndedBeforePresented('x'),
        isTrue,
        reason: 'the newer report is not erased by the older registration',
      );
    });

    test('a presentation while the registration is in flight is still dropped', () async {
      await reportUnseenEnd('x');
      platform.registrationGate = Completer();
      final registration = callkeep.reportNewIncomingCall('x', _handle);

      platform.present('x');

      expect(delegate.presented, isEmpty);
      platform.registrationGate!.complete();
      await registration;
    });

    test('a registration of an id never reported ends records nothing', () async {
      platform.registrationResult = null;

      await callkeep.reportNewIncomingCall('x', _handle);

      expect(callkeep.wasEndedBeforePresented('x'), isFalse);
    });

    test('tearDown forgets every reported end', () async {
      await reportUnseenEnd('x');

      await callkeep.tearDown();

      expect(callkeep.wasEndedBeforePresented('x'), isFalse);
      expect(platform.tearDownCount, greaterThanOrEqualTo(1));
    });
  });

  group('the bound', () {
    test('the oldest report is forgotten first', () async {
      for (var i = 0; i < 33; i++) {
        await reportUnseenEnd('c$i');
      }

      expect(callkeep.wasEndedBeforePresented('c0'), isFalse);
      expect(callkeep.wasEndedBeforePresented('c1'), isTrue);
      expect(callkeep.wasEndedBeforePresented('c32'), isTrue);
    });

    test('a repeated report counts as the newest, not the oldest', () async {
      await reportUnseenEnd('a');
      for (var i = 0; i < 31; i++) {
        await reportUnseenEnd('b$i');
      }
      await reportUnseenEnd('a');
      await reportUnseenEnd('c');

      expect(callkeep.wasEndedBeforePresented('a'), isTrue, reason: 'the report of a was renewed before c arrived');
      expect(callkeep.wasEndedBeforePresented('b0'), isFalse, reason: 'b0 is now the oldest');
    });
  });
}
