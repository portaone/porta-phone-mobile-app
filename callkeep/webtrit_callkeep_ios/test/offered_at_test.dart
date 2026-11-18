import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/callkeep.pigeon.dart';
import 'package:webtrit_callkeep_ios/webtrit_callkeep_ios.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

const _prefix = 'dev.flutter.pigeon.webtrit_callkeep_ios';
const _handle = CallkeepHandle.number('555');

WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

/// The iOS implementation passes the native side Core's offered_at only: with it the plugin tells
/// a new attempt of a call id that ended from a late copy of it. A time of this phone or of FCM is
/// left out (TEMPORARY(old Core without offered_at)).
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

  test('a report with a time not from Core sends no offer time', () async {
    expect(await platform.reportNewIncomingCall('call-1', _handle, 'Alice', true), isNull);
    expect(
      await platform.reportNewIncomingCall(
        'call-1',
        _handle,
        'Alice',
        true,
        offeredAt: DateTime.utc(2026, 10, 29),
        offeredAtSource: CallkeepOfferTimeSource.device,
      ),
      isNull,
    );

    expect(sent, hasLength(2));
    expect(sent[0], hasLength(5));
    expect(sent[0][4], isNull);
    expect(sent[1][4], isNull);
    expect(comparable(sent[1]), comparable(sent[0]));
  });

  test('a report with Core\'s offered_at sends it as epoch milliseconds', () async {
    final offeredAt = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

    await platform.reportNewIncomingCall(
      'call-1',
      _handle,
      null,
      false,
      offeredAt: offeredAt,
      offeredAtSource: CallkeepOfferTimeSource.core,
    );

    expect(sent.single[4], offeredAt.millisecondsSinceEpoch);
  });

  test('a late copy the native side refuses is reported as terminated', () async {
    reply = PIncomingCallError(value: PIncomingCallErrorEnum.callIdAlreadyTerminated);

    final result = await platform.reportNewIncomingCall('call-3', _handle, null, false);

    expect(result, CallkeepIncomingCallError.callIdAlreadyTerminated);
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
