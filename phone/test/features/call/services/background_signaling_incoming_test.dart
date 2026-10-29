import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/services/background_isolate_callbacks.dart';

/// What the background handler reported to the platform.
class _ReportingPlatform extends WebtritCallkeepPlatform {
  final reports = <(String, DateTime?)>[];

  @override
  Future<CallkeepIncomingCallError?> incomingCallPushNotificationService(
    String callId,
    CallkeepHandle handle,
    String? displayName,
    bool hasVideo, {
    DateTime? offeredAt,
  }) async {
    reports.add((callId, offeredAt));
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The persistent signaling socket delivers a call as the server offers it: a blind transfer
  // repeated after a decline offers the same id again, later than the end of the declined attempt.
  test('an incoming call from the background socket is reported as offered when it arrived', () async {
    final previous = WebtritCallkeepPlatform.instance;
    final platform = _ReportingPlatform();
    WebtritCallkeepPlatform.instance = platform;
    addTearDown(() => WebtritCallkeepPlatform.instance = previous);
    final before = DateTime.now();

    await onSignalingBackgroundCallEvent(
      const IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200'),
    );

    final (callId, offeredAt) = platform.reports.single;
    expect(callId, 'call');
    expect(offeredAt, isNotNull);
    expect(offeredAt!.isBefore(before), isFalse);
  });

  test('an incoming call from the background socket is offered at the clock of its arrival', () async {
    final previous = WebtritCallkeepPlatform.instance;
    final platform = _ReportingPlatform();
    WebtritCallkeepPlatform.instance = platform;
    addTearDown(() => WebtritCallkeepPlatform.instance = previous);
    final arrival = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

    await withClock(
      Clock.fixed(arrival),
      () => onSignalingBackgroundCallEvent(
        const IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200'),
      ),
    );

    expect(platform.reports, [('call', arrival)]);
  });
}
