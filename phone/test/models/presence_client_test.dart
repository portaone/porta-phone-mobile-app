import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

void main() {
  group('the client a presence record names', () {
    test('is read from what the app publishes', () {
      final client = PresenceClient.parse('PortaPhone/1.18.0+0 (Galaxy S24; Android: 14)');

      expect(
        client,
        const PresenceClient(name: 'PortaPhone', version: '1.18.0+0', device: 'Galaxy S24', system: 'Android 14'),
      );
      expect(client?.label, 'PortaPhone 1.18.0+0 \u00b7 Galaxy S24 \u00b7 Android 14');
    });

    test('is read from what the web dialer publishes', () {
      final client = PresenceClient.parse('Web-dialer/0.2.13 (Chrome; macOS)');

      expect(client, const PresenceClient(name: 'Web-dialer', version: '0.2.13', device: 'Chrome', system: 'macOS'));
      expect(client?.label, 'Web-dialer 0.2.13 \u00b7 Chrome \u00b7 macOS');
    });

    test('keeps a brand name that has a space in it', () {
      expect(PresenceClient.parse('Acme Phone/2.0.0 (Pixel 9; Android: 15)')?.name, 'Acme Phone');
    });

    test('decodes a device name the app had to encode', () {
      expect(PresenceClient.parse('PortaPhone/1.0.0 (Ren%C3%A9s iPhone; iOS: 18.1)')?.device, 'Ren\u00e9s iPhone');
    });

    test('leaves out a part the client did not give', () {
      final client = PresenceClient.parse('Web-dialer/0.2.13 (Chrome)');

      expect(client?.system, isEmpty);
      expect(client?.label, 'Web-dialer 0.2.13 \u00b7 Chrome');
    });

    test('is not read out of what a third-party device calls itself', () {
      // A desk phone's device id, a bare word, nothing: none of these is the
      // shape our clients write, and guessing at them would invent a client.
      expect(PresenceClient.parse('Yealink T54W'), isNull);
      expect(PresenceClient.parse('Web'), isNull);
      expect(PresenceClient.parse('urn:uuid:00000000-0000-1000-8000-000a95a0e128'), isNull);
      expect(PresenceClient.parse(''), isNull);
      expect(PresenceClient.parse(null), isNull);
    });

    test('survives a percent sign that is not an encoding', () {
      // Any client may put anything into this field, and the card of the
      // contact must still open for everybody who looks at it.
      expect(PresenceClient.parse('Zoiper/5 (Ren%E9; Windows)')?.device, 'Ren%E9');
      expect(PresenceClient.parse('Acme/1.0 (100%FF; x)')?.device, '100%FF');
      expect(PresenceClient.parse('Acme/1.0 (50% off; x)')?.device, '50% off');
    });
  });
}
