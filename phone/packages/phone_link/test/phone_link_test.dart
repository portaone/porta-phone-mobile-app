import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phone_link/phone_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  void answer(Object? Function(MethodCall call) reply) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(PhoneLink.channel, (
      call,
    ) async {
      calls.add(call);
      return reply(call);
    });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(PhoneLink.channel, null);
  });

  test('the link goes to the phone as its text; the phone taking it is true', () async {
    answer((_) => true);

    expect(await PhoneLink.open(Uri.parse('https://example.test/terms')), isTrue);
    expect(calls.single.method, 'open');
    expect(calls.single.arguments, 'https://example.test/terms');
  });

  test('no phone to take it, or the channel failing, is false', () async {
    answer((_) => false);
    expect(await PhoneLink.open(Uri.parse('https://example.test')), isFalse);

    answer((_) => throw PlatformException(code: 'no_node'));
    expect(await PhoneLink.open(Uri.parse('https://example.test')), isFalse);
  });

  test('off Android nothing is asked', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    answer((_) => true);

    expect(await PhoneLink.open(Uri.parse('https://example.test')), isFalse);
    expect(calls, isEmpty);
  });
}
