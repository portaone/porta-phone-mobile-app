import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';
import 'package:webtrit_callkeep_web/webtrit_callkeep_web.dart';

void main() {
  late WebtritCallkeepWeb web;

  Future<void> call(String id) => web.reportNewIncomingCall(id, const CallkeepHandle.number('1'), null, false);

  setUp(() async {
    web = WebtritCallkeepWeb();
    await web.setUp(
      const CallkeepOptions(
        ios: CallkeepIOSOptions(
          localizedName: 'x',
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 3,
          supportedHandleTypes: {CallkeepHandleType.number},
        ),
        android: CallkeepAndroidOptions(),
      ),
    );
    await call('a');
    await call('b');
    await call('c');
  });

  test('a second group is refused while one is live', () async {
    expect(await web.setCallGroup('room', ['a', 'b']), isNull);
    expect(await web.setCallGroup('other', ['b', 'c']), CallkeepCallRequestError.maximumCallGroupsReached);
    expect(await web.setHeld('c', true), isNull, reason: 'the refused declaration changed nothing');
    expect(await web.setCallGroup('room', ['a', 'b', 'c']), isNull, reason: 'the live name restates its group');
    await web.unsetCallGroup(['a', 'b', 'c']);
    expect(await web.setCallGroup('other', ['b', 'c']), isNull, reason: 'the group is gone, so its name is free');
  });

  test('ending one member releases the partner left alone', () async {
    await web.setCallGroup('room', ['a', 'b']);
    expect(await web.endCall('a'), isNull);
    expect(await web.setHeld('b', true), isNull, reason: 'a ended; b is the only call left of the group');
  });

  test('cleaning the connections forgets the groups with them', () async {
    await web.setCallGroup('room', ['a', 'b']);
    await web.cleanConnections();
    await call('a');
    await call('b');
    expect(await web.setHeld('b', true), isNull);
  });

  test('a member of a group is not held on its own', () async {
    expect(await web.setCallGroup('room', ['a', 'b']), isNull);
    expect(await web.setHeld('a', true), CallkeepCallRequestError.callIsGrouped);
    expect(await web.setHeld('c', true), isNull);
  });

  test('restating a longer membership grows the same group', () async {
    await web.setCallGroup('room', ['a', 'b']);
    await web.setCallGroup('room', ['a', 'b', 'c']);
    expect(await web.setHeld('c', true), CallkeepCallRequestError.callIsGrouped);
  });

  test('ungrouping and a member ending free the rest', () async {
    await web.setCallGroup('room', ['a', 'b', 'c']);
    await web.unsetCallGroup(['c']);
    expect(await web.setHeld('c', true), isNull);
    expect(await web.setHeld('a', true), CallkeepCallRequestError.callIsGrouped);
    await web.reportEndCall('b', '', CallkeepEndCallReason.remoteEnded);
    // a is alone now, and a group of one is not a group.
    expect(await web.setHeld('a', true), isNull);
  });

  test('one call named as the whole membership takes the group apart for everyone', () async {
    await web.setCallGroup('room', ['a', 'b', 'c']);
    await web.setCallGroup('room', ['a']);
    expect(await web.setHeld('a', true), isNull);
    expect(await web.setHeld('b', true), isNull);
    expect(await web.setHeld('c', true), isNull);
  });

  test('there is one group at a time', () async {
    await web.setCallGroup('room', ['a', 'b']);
    await web.setCallGroup('room', ['b', 'c']);
    expect(await web.setHeld('a', true), isNull);
    expect(await web.setHeld('c', true), CallkeepCallRequestError.callIsGrouped);
  });

  test('an empty membership changes nothing', () async {
    await web.setCallGroup('room', ['a', 'b']);
    expect(await web.setCallGroup('room', []), isNull);
    expect(await web.setHeld('a', true), CallkeepCallRequestError.callIsGrouped);
  });
}
