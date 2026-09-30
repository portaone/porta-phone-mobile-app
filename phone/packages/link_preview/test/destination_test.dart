import 'package:link_preview/link_preview.dart';
import 'package:test/test.dart';

void main() {
  bool previewable(String url) => isPreviewable(Uri.parse(url));

  group('isPreviewable', () {
    test('https to a public name', () => expect(previewable('https://example.com/a'), isTrue));

    test('an uppercase host is still checked', () => expect(previewable('https://LOCALHOST/'), isFalse));

    test('a private range boundary is exact', () {
      expect(previewable('https://172.15.255.255/'), isTrue);
      expect(previewable('https://172.16.0.0/'), isFalse);
      expect(previewable('https://172.31.255.255/'), isFalse);
      expect(previewable('https://172.32.0.0/'), isTrue);
    });

    test('multicast and reserved IPv4', () {
      expect(previewable('https://224.0.0.1/'), isFalse);
      expect(previewable('https://255.255.255.255/'), isFalse);
    });

    test('IPv6 multicast', () => expect(previewable('https://[ff02::1]/'), isFalse));

    test('an IPv4-mapped public address', () => expect(previewable('https://[::ffff:8.8.8.8]/'), isTrue));

    test('reserved top-level names', () {
      for (final host in ['a.test', 'a.invalid', 'x.onion', 'router.home.arpa']) {
        expect(previewable('https://$host/'), isFalse, reason: host);
      }
    });

    test('no host', () => expect(previewable('https:///path'), isFalse));

    test('a trailing dot does not get a name or an address past the checks', () {
      for (final host in [
        'localhost.',
        'LOCALHOST.',
        'printer.local.',
        'router.home.arpa.',
        '127.0.0.1.',
        '10.0.0.1.',
        'a.test.',
      ]) {
        expect(previewable('https://$host/'), isFalse, reason: host);
      }
    });

    test('an IPv4 address written in any but the canonical form is refused', () {
      // A browser and the system resolver read all of these as an address, most of them as 127.0.0.1.
      const forms = [
        '127.1',
        '2130706433',
        '0x7f000001',
        '0x7F000001',
        '0177.0.0.1',
        '0x7f.0.0.1',
        '127.0.0.01',
        '8.8.8.08',
        '1.2.3.4.5',
        '256.1.1.1',
        '0x',
      ];
      for (final host in forms) {
        expect(previewable('https://$host/'), isFalse, reason: host);
      }
    });

    test('a public IPv4 address in the canonical form passes', () {
      expect(previewable('https://93.184.216.34/'), isTrue);
      expect(previewable('https://8.8.8.8/'), isTrue);
    });

    test('names with digits are names', () {
      for (final host in ['a1.example.com', '123abc.com', 'example.com1', 'x0.example.org']) {
        expect(previewable('https://$host/'), isTrue, reason: host);
      }
    });

    test('a public name with a trailing dot is still previewable', () {
      expect(previewable('https://example.com./a'), isTrue);
    });
  });
}
