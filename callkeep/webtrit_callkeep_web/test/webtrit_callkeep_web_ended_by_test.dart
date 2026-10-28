import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';
import 'package:webtrit_callkeep_web/webtrit_callkeep_web.dart';

/// Records the ends the web implementation hands the delegate; nothing else is used here.
class _EndRecorder implements CallkeepDelegate {
  final List<(String, CallkeepEndedBy)> ended = [];

  @override
  Future<bool> performEndCall(String callId, CallkeepEndedBy endedBy) async {
    ended.add((callId, endedBy));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late WebtritCallkeepWeb web;
  late _EndRecorder delegate;

  Future<void> call(String id) => web.reportNewIncomingCall(id, const CallkeepHandle.number('1'), null, false);

  setUp(() async {
    web = WebtritCallkeepWeb();
    delegate = _EndRecorder();
    web.setDelegate(delegate);
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

  test('endCall hands the delegate who asked for the end, the app by default', () async {
    await web.endCall('a');
    await web.endCall('b', endedBy: CallkeepEndedBy.user);

    expect(delegate.ended, [('a', CallkeepEndedBy.app), ('b', CallkeepEndedBy.user)]);
  });

  test('a teardown ends the calls left as the app', () async {
    await web.tearDown();

    expect(delegate.ended, [('a', CallkeepEndedBy.app), ('b', CallkeepEndedBy.app), ('c', CallkeepEndedBy.app)]);
  });
}
