import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/callkeep.pigeon.dart';
import 'package:webtrit_callkeep_ios/webtrit_callkeep_ios.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

const _prefix = 'dev.flutter.pigeon.webtrit_callkeep_ios';
const _handle = CallkeepHandle.number('555');

WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

/// CallKit keeps no end of a call the app never presented, so the iOS implementation takes the
/// time the server offered a call and leaves it out: a timed report reaches the native side
/// exactly as an untimed one did.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<List<Object?>> sent;
  PIncomingCallError? reply;

  setUp(() {
    WebtritCallkeep.registerWith();
    sent = [];
    reply = null;
    messenger.setMockMessageHandler('$_prefix.PHostApi.reportNewIncomingCall', (message) async {
      sent.add(PHostApi.pigeonChannelCodec.decodeMessage(message)! as List<Object?>);
      return PHostApi.pigeonChannelCodec.encodeMessage([reply]);
    });
  });

  List<Object?> comparable(List<Object?> args) {
    final handle = args[1]! as PHandle;
    return [args[0], handle.type, handle.value, args[2], args[3]];
  }

  test('a report with offeredAt sends the same four arguments as one without', () async {
    expect(await platform.reportNewIncomingCall('call-1', _handle, 'Alice', true), isNull);
    expect(
      await platform.reportNewIncomingCall('call-1', _handle, 'Alice', true, offeredAt: DateTime.utc(2026, 10, 29)),
      isNull,
    );

    expect(sent, hasLength(2));
    expect(sent[0], hasLength(4));
    expect(sent[1], hasLength(4));
    expect(comparable(sent[1]), comparable(sent[0]));
  });

  test('a report with offeredAt returns the error the native side answers', () async {
    reply = PIncomingCallError(value: PIncomingCallErrorEnum.filteredByDoNotDisturb);

    final result = await platform.reportNewIncomingCall(
      'call-2',
      _handle,
      null,
      false,
      offeredAt: DateTime.utc(2026, 10, 29),
    );

    expect(result, CallkeepIncomingCallError.filteredByDoNotDisturb);
  });
}
