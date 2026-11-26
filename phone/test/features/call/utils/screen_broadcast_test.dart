import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/call/utils/screen_broadcast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.webtrit.phone/screen_broadcast');
  late List<String> asked;
  late bool? nativeAnswer;

  setUp(() {
    asked = [];
    nativeAnswer = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      asked.add(call.method);
      return nativeAnswer;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    EnvironmentConfig.clearOverrides();
  });

  void nameGroup(String group) =>
      EnvironmentConfig.applyOverrides({EnvironmentConfig.IOS_SCREEN_SHARE_APP_GROUP__NAME: group});

  test('no app group: no extension, and the native side is not asked', () async {
    expect(await ScreenBroadcast.ofThisBuild(), isNull);
    expect(asked, isEmpty);
  });

  test('an app group and the extension in the bundle: the extension', () async {
    nameGroup('group.com.example.app');

    expect(await ScreenBroadcast.ofThisBuild(), isNotNull);
    expect(asked, ['isAvailable']);
  });

  test('an app group but no extension in the bundle: no extension', () async {
    nameGroup('group.com.example.app');
    nativeAnswer = false;

    expect(await ScreenBroadcast.ofThisBuild(), isNull);
  });

  test('off iOS: no extension, whatever the group', () async {
    nameGroup('group.com.example.app');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(await ScreenBroadcast.ofThisBuild(), isNull);
    expect(asked, isEmpty);
  });
}
