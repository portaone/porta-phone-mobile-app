import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

void main() {
  test('reads the app, the device and the system out of the User-Agent the app writes', () {
    final device = SessionDevice.parse('PortaPhone/1.18.0+0 (Samsung Galaxy XCover 5; Android: 14)');

    expect(
      device,
      const SessionDevice(
        appName: 'PortaPhone',
        appVersion: '1.18.0+0',
        deviceName: 'Samsung Galaxy XCover 5',
        osName: 'Android',
        osVersion: '14',
      ),
    );
    expect(device!.osLabel, 'Android 14');
  });

  test('an app name with a space in it, as a brand may launch the app, still parses', () {
    final device = SessionDevice.parse('Acme Phone/1.18.0+0 (Pixel 9; Android: 15)');

    expect(device?.appName, 'Acme Phone');
    expect(device?.deviceName, 'Pixel 9');
  });

  test('keeps a hardware code an older build sent as the name', () {
    expect(SessionDevice.parse('Portaphone2/1.18.0+4 (CPH2089; Android: 12)')?.deviceName, 'CPH2089');
    expect(SessionDevice.parse('Portaphone2/1.18.0+3 (iPhone; iOS: 16.7.16)')?.deviceName, 'iPhone');
  });

  test('decodes a name the app percent-encoded for the header', () {
    expect(
      SessionDevice.parse("PortaPhone/1.18.0+0 (%D0%93%D0%B0%D0%BD%D0%BD%D0%B0's M32; Android: 13)")?.deviceName,
      "\u0413\u0430\u043d\u043d\u0430's M32",
    );
  });

  test('leaves a percent that is not an encoding, or not UTF-8, alone', () {
    expect(SessionDevice.parse('PortaPhone/1.18.0+0 (100% phone; Android: 13)')?.deviceName, '100% phone');
    expect(SessionDevice.parse('PortaPhone/1.18.0+0 (Phone%ff; Android: 14)')?.deviceName, 'Phone%ff');
  });

  test('a User-Agent of another shape is not a device', () {
    expect(SessionDevice.parse(null), isNull);
    expect(SessionDevice.parse(''), isNull);
    expect(SessionDevice.parse('Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/130.0'), isNull);
    expect(SessionDevice.parse('Dart/3.9 (dart:io)'), isNull);
    expect(SessionDevice.parse('portaone-qa/1'), isNull);
  });
}
