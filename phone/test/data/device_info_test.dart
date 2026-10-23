import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/data/data.dart';

/// The channel device_info_plus asks the platform on; the device name plugin
/// has nothing to say on a desktop, so what the test host is decides the
/// fallback path exercised here. On Linux device_info_plus reads
/// /etc/os-release in Dart and never asks the channel, so the tests run on
/// macOS only.
const _deviceInfoChannel = MethodChannel('dev.fluttercommunity.plus/device_info');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _deviceInfoChannel,
      null,
    );
  });

  test('displayName is null where the platform has no marketing name to give', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _deviceInfoChannel,
      (call) async => <String, Object?>{
        'computerName': 'host',
        'hostName': 'host.local',
        'arch': 'arm64',
        'model': 'Mac14,2',
        'modelName': 'MacBook Air',
        'kernelVersion': '24.0.0',
        'osRelease': '15.0',
        'majorVersion': 15,
        'minorVersion': 0,
        'patchVersion': 0,
        'activeCPUs': 8,
        'memorySize': 1,
        'cpuFrequency': 0,
        'systemGUID': null,
      },
    );

    final deviceInfo = await DeviceInfoFactory.init();

    expect(deviceInfo.model, 'Mac14,2');
    expect(deviceInfo.displayName, isNull);
  }, skip: !Platform.isMacOS);

  test('nothing is named when the platform could not be asked at all', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _deviceInfoChannel,
      (call) async => throw PlatformException(code: 'unavailable'),
    );

    final deviceInfo = await DeviceInfoFactory.init();

    expect(deviceInfo.model, 'unknown');
    expect(deviceInfo.displayName, isNull);
  }, skip: !Platform.isMacOS);
}
