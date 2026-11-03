import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_shape/screen_shape.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('screen_shape');
  late int calls;

  void answer(Object? Function() reply) {
    calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      expect(call.method, 'isRound');
      return reply();
    });
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('Android answers what the configuration says', () async {
    answer(() => true);
    expect(await DisplayShape.isRound(), isTrue);
    answer(() => false);
    expect(await DisplayShape.isRound(), isFalse);
  });

  test('a failure, or no plugin, is null, never a throw', () async {
    answer(() => throw PlatformException(code: 'boom'));
    expect(await DisplayShape.isRound(), isNull);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    expect(await DisplayShape.isRound(), isNull);
  });

  test('every other platform is null without asking', () async {
    answer(() => true);
    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(await DisplayShape.isRound(), isNull, reason: '$platform');
    }
    expect(calls, 0);
  });
}
