import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep_android/src/common/callkeep.pigeon.dart';
import 'package:webtrit_callkeep_android/webtrit_callkeep_android.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

const _prefix = 'dev.flutter.pigeon.webtrit_callkeep_android';
final _codec = PHostApi.pigeonChannelCodec;
const _handle = CallkeepHandle(type: CallkeepHandleType.number, value: '555');

/// The time the server offered an incoming call crosses Pigeon as epoch milliseconds, on both
/// the main path and the push bootstrap path: the native core compares it with the end of a call
/// the app ended before presenting it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<List<Object?>> sent;

  void record(String channel) {
    messenger.setMockMessageHandler(channel, (message) async {
      sent.add(_codec.decodeMessage(message)! as List<Object?>);
      return _codec.encodeMessage([null]);
    });
  }

  setUp(() {
    WebtritCallkeepAndroid.registerWith();
    sent = [];
  });

  group('reportNewIncomingCall', () {
    setUp(() => record('$_prefix.PHostApi.reportNewIncomingCall'));

    test('sends offeredAt as epoch milliseconds after the call arguments', () async {
      final offeredAt = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

      final result = await WebtritCallkeepPlatform.instance.reportNewIncomingCall(
        'call-1',
        _handle,
        'Alice',
        true,
        offeredAt: offeredAt,
      );

      expect(result, isNull);
      final args = sent.single;
      expect(args, hasLength(5));
      expect(args[0], 'call-1');
      expect((args[1]! as PHandle).value, '555');
      expect(args[2], 'Alice');
      expect(args[3], true);
      expect(args[4], offeredAt.millisecondsSinceEpoch);
    });

    test('sends null when the offer time is not known', () async {
      await WebtritCallkeepPlatform.instance.reportNewIncomingCall('call-1', _handle, null, false);

      expect(sent.single, hasLength(5));
      expect(sent.single[4], isNull);
    });

    test('sends the same instant for a local and a UTC offer time', () async {
      final utc = DateTime.utc(2026, 10, 29, 12);

      await WebtritCallkeepPlatform.instance.reportNewIncomingCall('call-1', _handle, null, false, offeredAt: utc);
      await WebtritCallkeepPlatform.instance.reportNewIncomingCall(
        'call-2',
        _handle,
        null,
        false,
        offeredAt: utc.toLocal(),
      );

      expect(sent[0][4], sent[1][4]);
    });
  });

  group('incomingCallPushNotificationService', () {
    setUp(() => record('$_prefix.PHostBackgroundPushNotificationIsolateBootstrapApi.reportNewIncomingCall'));

    test('sends offeredAt as epoch milliseconds after the call arguments', () async {
      final offeredAt = DateTime.utc(2026, 10, 29, 12, 30, 15, 123);

      final result = await WebtritCallkeepPlatform.instance.incomingCallPushNotificationService(
        'call-1',
        _handle,
        'Alice',
        true,
        offeredAt: offeredAt,
      );

      expect(result, isNull);
      final args = sent.single;
      expect(args, hasLength(5));
      expect(args[0], 'call-1');
      expect((args[1]! as PHandle).value, '555');
      expect(args[2], 'Alice');
      expect(args[3], true);
      expect(args[4], offeredAt.millisecondsSinceEpoch);
    });

    test('sends null when the offer time is not known', () async {
      await WebtritCallkeepPlatform.instance.incomingCallPushNotificationService('call-1', _handle, null, false);

      expect(sent.single, hasLength(5));
      expect(sent.single[4], isNull);
    });

    test('maps the error the native side answers', () async {
      messenger.setMockMessageHandler(
        '$_prefix.PHostBackgroundPushNotificationIsolateBootstrapApi.reportNewIncomingCall',
        (message) async =>
            _codec.encodeMessage([PIncomingCallError(value: PIncomingCallErrorEnum.callIdAlreadyTerminated)]),
      );

      final result = await WebtritCallkeepPlatform.instance.incomingCallPushNotificationService(
        'call-1',
        _handle,
        null,
        false,
        offeredAt: DateTime.utc(2026),
      );

      expect(result, CallkeepIncomingCallError.callIdAlreadyTerminated);
    });
  });
}
