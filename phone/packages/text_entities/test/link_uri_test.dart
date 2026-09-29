import 'package:test/test.dart';
import 'package:text_entities/text_entities.dart';

void main() {
  group('punycodeEncode', () {
    // Vectors from RFC 3492 and from live IDN registrations.
    const vectors = {
      'bücher': 'bcher-kva',
      'пример': 'e1afmkfd',
      'сайт': '80aswg',
      'укр': 'j1amh',
      'рф': 'p1ai',
      '例子': 'fsqu00a',
      '测试': '0zwm56d',
      'münchen': 'mnchen-3ya',
    };

    vectors.forEach((input, expected) {
      test(expected, () => expect(punycodeEncode(input), expected));
    });

    test('leaves pure ASCII with a trailing delimiter', () => expect(punycodeEncode('abc'), 'abc-'));
  });

  group('hostToAscii', () {
    test('converts only the non-ASCII labels', () {
      expect(hostToAscii('сайт.укр'), 'xn--80aswg.xn--j1amh');
      expect(hostToAscii('www.сайт.com'), 'www.xn--80aswg.com');
    });

    test('lowercases before encoding', () {
      expect(hostToAscii('САЙТ.рф'), 'xn--80aswg.xn--p1ai');
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
      'IDN host to punycode': ('сайт.укр', 'https://xn--80aswg.xn--j1amh'),
      'IDN host behind a scheme, with port and credentials': (
        'https://u:p@сайт.рф:8443/a',
        'https://u:p@xn--80aswg.xn--p1ai:8443/a',
      ),
      'non-ASCII path percent-encoded': (
        'https://uk.wikipedia.org/wiki/Птах',
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
