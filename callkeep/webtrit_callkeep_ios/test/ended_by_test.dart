import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/callkeep.pigeon.dart';
import 'package:webtrit_callkeep_ios/src/common/converters.dart';
import 'package:webtrit_callkeep_ios/webtrit_callkeep_ios.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

const _prefix = 'dev.flutter.pigeon.webtrit_callkeep_ios';

WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

class _EndRecordingDelegate implements CallkeepDelegate {
  final List<(String, CallkeepEndedBy)> ended = [];

  @override
  Future<bool> performEndCall(String callId, CallkeepEndedBy endedBy) async {
    ended.add((callId, endedBy));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Who ended a call crosses Pigeon in both directions: the app's endCall tells CallKit's side
/// who asks, and the performEndCall CallKit sends back names the initiator to the delegate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<List<Object?>> endCalls;

  setUp(() {
    WebtritCallkeep.registerWith();
    endCalls = [];
    messenger.setMockMessageHandler('$_prefix.PHostApi.endCall', (message) async {
      endCalls.add(PHostApi.pigeonChannelCodec.decodeMessage(message)! as List<Object?>);
      return PHostApi.pigeonChannelCodec.encodeMessage([null]);
    });
  });

  tearDown(() => platform.setDelegate(null));

  test('endCall without an initiator asks as the app', () async {
    await platform.endCall('call-1');
    expect(endCalls.single[1], PEndedByEnum.app);
  });

  test('endCall on the user behalf carries the user', () async {
    await platform.endCall('call-1', endedBy: CallkeepEndedBy.user);
    expect(endCalls.single[1], PEndedByEnum.user);
  });

  for (final endedBy in PEndedByEnum.values) {
    test('performEndCall from CallKit reaches the delegate with ${endedBy.name}', () async {
      final delegate = _EndRecordingDelegate();
      platform.setDelegate(delegate);
      // endCall registers the callId's CallKit UUID, which performEndCall is keyed by.
      await platform.endCall('call-1');
      final uuid = endCalls.single[0]! as String;

      final reply = await messenger.handlePlatformMessage(
        '$_prefix.PDelegateFlutterApi.performEndCall',
        PDelegateFlutterApi.pigeonChannelCodec.encodeMessage([uuid, endedBy]),
        (_) {},
      );

      expect(delegate.ended, [('call-1', endedBy.toCallkeep())]);
      expect(PDelegateFlutterApi.pigeonChannelCodec.decodeMessage(reply), [true]);
    });
  }

  test('the converters map every initiator both ways', () {
    for (final endedBy in CallkeepEndedBy.values) {
      expect(endedBy.toPigeon().toCallkeep(), endedBy);
      expect(endedBy.toPigeon().name, endedBy.name);
    }
  });
}
