import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/data/data.dart';

class _MockPackageInfo extends Mock implements PackageInfo {}

class _MockDeviceInfo extends Mock implements DeviceInfo {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late _MockPackageInfo packageInfo;
  late _MockDeviceInfo deviceInfo;
  late _MockAppInfo appInfo;

  setUp(() {
    packageInfo = _MockPackageInfo();
    deviceInfo = _MockDeviceInfo();
    appInfo = _MockAppInfo();

    when(() => packageInfo.appName).thenReturn('PortaPhone');
    when(() => appInfo.version).thenReturn(Version(1, 8, 2));
    when(() => deviceInfo.model).thenReturn('iPhone');
    when(() => deviceInfo.displayName).thenReturn('iPhone 13 mini');
    when(() => deviceInfo.systemName).thenReturn('iOS');
    when(() => deviceInfo.systemVersion).thenReturn('17.4');
  });

  test('buildUserAgent names the app build and the device by its marketing name', () {
    expect(
      DefaultAppMetadataProvider.buildUserAgent(packageInfo, appInfo, deviceInfo),
      equals('PortaPhone/1.8.2 (iPhone 13 mini; iOS: 17.4)'),
    );
  });

  test('buildUserAgent names the device by its model where no marketing name is known', () {
    when(() => deviceInfo.displayName).thenReturn(null);

    expect(
      DefaultAppMetadataProvider.buildUserAgent(packageInfo, appInfo, deviceInfo),
      equals('PortaPhone/1.8.2 (iPhone; iOS: 17.4)'),
    );
  });

  test('buildUserAgent escapes a device name the User-Agent comment could not carry', () {
    when(() => deviceInfo.displayName).thenReturn('Lenovo Tab M8 (4th Gen); Wi-Fi');

    expect(
      DefaultAppMetadataProvider.buildUserAgent(packageInfo, appInfo, deviceInfo),
      equals('PortaPhone/1.8.2 (Lenovo Tab M8 [4th Gen], Wi-Fi; iOS: 17.4)'),
    );
  });

  test('the User-Agent sent to the backend is the string presence uses as the device name', () async {
    final provider = await DefaultAppMetadataProvider.init(packageInfo, deviceInfo, appInfo, _MockSecureStorage());

    expect(provider.userAgent, equals(DefaultAppMetadataProvider.buildUserAgent(packageInfo, appInfo, deviceInfo)));
  });
}
