import 'package:test/test.dart';
import 'package:text_entities/text_entities.dart';

void main() {
  group('punycodeEncode', () {
    // Vectors from RFC 3492 and from live IDN registrations.
    const vectors = {
      'b\u00fccher': 'bcher-kva',
      '\u0441\u0430\u0439\u0442': '80aswg',
      '\u0443\u043a\u0440': 'j1amh',
      '\u4f8b\u5b50': 'fsqu00a',
      '\u6d4b\u8bd5': '0zwm56d',
      'm\u00fcnchen': 'mnchen-3ya',
    };

    vectors.forEach((input, expected) {
      test(expected, () => expect(punycodeEncode(input), expected));
    });

    test('leaves pure ASCII with a trailing delimiter', () => expect(punycodeEncode('abc'), 'abc-'));
  });

  group('hostToAscii', () {
    test('converts only the non-ASCII labels', () {
      expect(hostToAscii('\u0441\u0430\u0439\u0442.\u0443\u043a\u0440'), 'xn--80aswg.xn--j1amh');
      expect(hostToAscii('www.\u0441\u0430\u0439\u0442.com'), 'www.xn--80aswg.com');
    });

    test('lowercases before encoding', () {
      expect(hostToAscii('\u0421\u0410\u0419\u0422.\u0443\u043a\u0440'), 'xn--80aswg.xn--j1amh');
    });

    test('leaves an ASCII host alone', () => expect(hostToAscii('example.com'), 'example.com'));
  });

  group('linkUri', () {
    const cases = {
      'bare host gets https': ('example.com/a', 'https://example.com/a'),
      'www host gets https': ('www.example.com', 'https://www.example.com'),
      'a bare host that starts with "http"': ('httpbin.org/get', 'https://httpbin.org/get'),
      'https kept': ('https://example.com/a', 'https://example.com/a'),
      'http kept': ('http://example.com/a', 'http://example.com/a'),
      'port kept': ('example.com:8080/x', 'https://example.com:8080/x'),
      'credentials kept': ('https://user:pass@example.com/x', 'https://user:pass@example.com/x'),
      'parentheses kept': ('https://en.wikipedia.org/wiki/Bird_(god)', 'https://en.wikipedia.org/wiki/Bird_(god)'),
      'query and fragment kept': ('https://example.com/a?b=c#d', 'https://example.com/a?b=c#d'),
      'IDN host to punycode': ('\u0441\u0430\u0439\u0442.\u0443\u043a\u0440', 'https://xn--80aswg.xn--j1amh'),
      'IDN host behind a scheme, with port and credentials': (
        'https://u:p@\u0441\u0430\u0439\u0442.\u0443\u043a\u0440:8443/a',
        'https://u:p@xn--80aswg.xn--j1amh:8443/a',
      ),
      'non-ASCII path percent-encoded': (
        'https://uk.wikipedia.org/wiki/\u041f\u0442\u0430\u0445',
        'https://uk.wikipedia.org/wiki/%D0%9F%D1%82%D0%B0%D1%85',
      ),
      'IPv6 literal kept': ('http://[::1]:8080/', 'http://[::1]:8080/'),
    };

    cases.forEach((description, sample) {
      final (link, expected) = sample;
      test(description, () => expect(linkUri(link).toString(), expected));
    });

    test('an uppercase scheme is recognised as a scheme', () {
      expect(linkUri('HTTPS://EXAMPLE.COM/A').toString(), 'https://example.com/A');
    });
  });

  group('TextEntity.uri', () {
    test('a link opens its address', () {
      expect(firstLink('see example.com/a now')!.uri, Uri.parse('https://example.com/a'));
    });

    test('an email address opens a mail to it', () {
      final email = detectLinks('write a+tag@gmail.com').single;

      expect(email.uri.toString(), 'mailto:a+tag@gmail.com');
    });

    test('formatting has no address', () {
      final bold = parseMessage('*bold*').entities.single;

      expect(bold.uri, isNull);
    });
  });
}
