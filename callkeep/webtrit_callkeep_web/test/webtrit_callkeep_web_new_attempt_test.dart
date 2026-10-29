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
}
