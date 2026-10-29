import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

typedef _Report = (String callId, CallkeepHandle handle, String? displayName, bool hasVideo, DateTime? offeredAt);

/// Records what each incoming-call path hands the platform.
class _RecordingPlatform extends WebtritCallkeepPlatform with MockPlatformInterfaceMixin {
  final List<_Report> reported = [];
  final List<_Report> pushReported = [];
  CallkeepIncomingCallError? result;

  @override
  Future<CallkeepIncomingCallError?> reportNewIncomingCall(
    String callId,
    CallkeepHandle handle,
    String? displayName,
    bool hasVideo, {
    DateTime? offeredAt,
  }) async {
    reported.add((callId, handle, displayName, hasVideo, offeredAt));
    return result;
  }

  @override
  Future<CallkeepIncomingCallError?> incomingCallPushNotificationService(
    String callId,
    CallkeepHandle handle,
    String? displayName,
    bool hasVideo, {
    DateTime? offeredAt,
  }) async {
    pushReported.add((callId, handle, displayName, hasVideo, offeredAt));
    return result;
  }

  @override
  Future<void> tearDown() async {}
}

const _handle = CallkeepHandle.number('100');

/// The time the server offered an incoming call reaches the platform unchanged from both the
/// app's report and the push bootstrap report: the platform decides with it whether an id the
/// app ended before is a late copy or a new attempt.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingPlatform platform;

  setUp(() async {
    platform = _RecordingPlatform();
    WebtritCallkeepPlatform.instance = platform;
    // The singleton outlives tests: start each one with no reported ends.
    await Callkeep().tearDown();
  });

  group('Callkeep.reportNewIncomingCall', () {
    test('forwards offeredAt to the platform unchanged', () async {
      final offeredAt = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

      await Callkeep().reportNewIncomingCall('c1', _handle, displayName: 'Alice', hasVideo: true, offeredAt: offeredAt);

      expect(platform.reported, [('c1', _handle, 'Alice', true, offeredAt)]);
      expect(platform.reported.single.$5, same(offeredAt));
    });

    test('forwards null when the offer time is not known', () async {
      await Callkeep().reportNewIncomingCall('c1', _handle);

      expect(platform.reported, [('c1', _handle, null, false, null)]);
    });

    test('returns what the platform answers for a timed report', () async {
      platform.result = CallkeepIncomingCallError.callIdAlreadyTerminated;

      final result = await Callkeep().reportNewIncomingCall('c1', _handle, offeredAt: DateTime.utc(2026));

      expect(result, CallkeepIncomingCallError.callIdAlreadyTerminated);
    });
  });

  group('BackgroundPushNotificationBootstrapService.reportNewIncomingCall', () {
    test('forwards offeredAt to incomingCallPushNotificationService unchanged', () async {
      final offeredAt = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

      await BackgroundPushNotificationBootstrapService().reportNewIncomingCall(
        'c1',
        _handle,
        displayName: 'Alice',
        hasVideo: true,
        offeredAt: offeredAt,
      );

      expect(platform.pushReported, [('c1', _handle, 'Alice', true, offeredAt)]);
      expect(platform.pushReported.single.$5, same(offeredAt));
      expect(platform.reported, isEmpty);
    });

    test('forwards null when the offer time is not known', () async {
      await BackgroundPushNotificationBootstrapService().reportNewIncomingCall('c1', _handle);

      expect(platform.pushReported, [('c1', _handle, null, false, null)]);
    });

    test('returns what the platform answers', () async {
      platform.result = CallkeepIncomingCallError.callIdAlreadyTerminated;

      final result = await BackgroundPushNotificationBootstrapService().reportNewIncomingCall(
        'c1',
        _handle,
        offeredAt: DateTime.utc(2026),
      );

      expect(result, CallkeepIncomingCallError.callIdAlreadyTerminated);
    });
  });
}
