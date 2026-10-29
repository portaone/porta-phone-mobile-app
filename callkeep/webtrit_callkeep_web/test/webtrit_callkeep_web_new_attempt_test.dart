import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';
import 'package:webtrit_callkeep_web/webtrit_callkeep_web.dart';

/// A blind transfer repeated after the target declined offers the same call id again: the web
/// implementation refuses a re-report of an ended id unless it was offered after that end.
void main() {
  late WebtritCallkeepWeb web;

  Future<CallkeepIncomingCallError?> call(String id, {DateTime? offeredAt}) =>
      web.reportNewIncomingCall(id, const CallkeepHandle.number('1'), null, false, offeredAt: offeredAt);

  setUp(() async {
    web = WebtritCallkeepWeb();
    await web.setUp(
      const CallkeepOptions(
        ios: CallkeepIOSOptions(
          localizedName: 'test',
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          supportedHandleTypes: {CallkeepHandleType.number},
        ),
        android: CallkeepAndroidOptions(),
      ),
    );
    await call('c1');
    await web.reportEndCall('c1', '', CallkeepEndCallReason.declinedByUser);
  });

  test('a re-report with no offer time is refused as terminated', () async {
    expect(await call('c1'), CallkeepIncomingCallError.callIdAlreadyTerminated);
  });

  test('a re-report offered before the end is refused as terminated', () async {
    final before = DateTime.now().subtract(const Duration(minutes: 1));

    expect(await call('c1', offeredAt: before), CallkeepIncomingCallError.callIdAlreadyTerminated);
  });

  test('a re-report offered after the end is a new attempt and registers', () async {
    final after = DateTime.now().add(const Duration(minutes: 1));

    expect(await call('c1', offeredAt: after), isNull);
  });

  test('a re-report of the new attempt while it is held is refused as existing', () async {
    final after = DateTime.now().add(const Duration(minutes: 1));
    await call('c1', offeredAt: after);

    expect(await call('c1', offeredAt: after), CallkeepIncomingCallError.callIdAlreadyExists);
  });

  test('a call the app ended itself is refused unless offered after that end', () async {
    await call('c2');
    expect(await web.endCall('c2'), isNull);

    final before = DateTime.now().subtract(const Duration(minutes: 1));
    expect(await call('c2'), CallkeepIncomingCallError.callIdAlreadyTerminated);
    expect(await call('c2', offeredAt: before), CallkeepIncomingCallError.callIdAlreadyTerminated);

    final after = DateTime.now().add(const Duration(minutes: 1));
    expect(await call('c2', offeredAt: after), isNull);
  });

  test('the end of the new attempt is what a later copy is compared with', () async {
    // Offered after the first end, so it registers; then ended again a little later.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final offeredAt = DateTime.now();
    expect(await call('c1', offeredAt: offeredAt), isNull);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await web.reportEndCall('c1', '', CallkeepEndCallReason.remoteEnded);

    // The same attempt again: after the first end, but not after the second.
    expect(await call('c1', offeredAt: offeredAt), CallkeepIncomingCallError.callIdAlreadyTerminated);
  });

  test('the push bootstrap path accepts an offer time and does nothing on the web', () async {
    final result = await web.incomingCallPushNotificationService(
      'c1',
      const CallkeepHandle.number('1'),
      null,
      false,
      offeredAt: DateTime.now().add(const Duration(minutes: 1)),
    );

    expect(result, isNull);
    expect(await call('c1'), CallkeepIncomingCallError.callIdAlreadyTerminated);
  });
}
