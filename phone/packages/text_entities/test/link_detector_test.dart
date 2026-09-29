import 'package:test/test.dart';
import 'package:text_entities/text_entities.dart';

/// The first link in [text], as written.
String? linkIn(String text) => firstLink(text)?.value;

/// The first email address in [text], as written.
String? emailIn(String text) {
  for (final entity in detectLinks(text)) {
    if (entity.type == TextEntityType.email) return entity.value;
  }
  return null;
}

void main() {
  group('ordinary text is not a link', () {
    const notLinks = {
      'python attribute access': 'string.ascii_letters + string.digits',
      'method call': 'random.choice',
      'dotted module path': 'use os.path.join here',
      'nonsense pair': 'asd.zxc',
      'document file name': 'report.pdf attached',
      'source file name': 'main.dart',
      'config file name': 'config.yaml',
      'markup file name': 'index.html',
      'missing space after a full stop': 'the sentence ends here.Then the next one starts',
      'abbreviated name': 'Mr.Smith',
      'semantic version': 'version 1.2.3',
      'decimal number': 'that costs 3.14 dollars',
      'plain prose': 'no link here at all',
      'empty text': '',
      'a lone scheme': 'type https:// and then the host',
    };

    notLinks.forEach((description, text) {
      test(description, () => expect(detectLinks(text), isEmpty, reason: '"$text" must not be linkified'));
    });
  });

  group('real links are recognised', () {
    const links = {
      'bare host': ('portaone.com', 'portaone.com'),
      'host with path': ('webtrit.com/pricing', 'webtrit.com/pricing'),
      'www prefix': ('www.example.com', 'www.example.com'),
      'https with path, query and fragment': (
        'https://sub.domain.co.uk/path?a=b#frag here',
        'https://sub.domain.co.uk/path?a=b#frag',
      ),
      'http scheme': ('http://example.com/x', 'http://example.com/x'),
      'long tld': ('shop.example.online', 'shop.example.online'),
      'country code tld': ('my.site.io', 'my.site.io'),
      'ip address behind a scheme': ('http://192.168.1.1:8080/admin', 'http://192.168.1.1:8080/admin'),
      'port on a bare host': ('example.com:8080/x', 'example.com:8080/x'),
      'single-label host behind a scheme': ('http://localhost:3000/x', 'http://localhost:3000/x'),
      'credentials before the host': ('https://user:pass@example.com/x', 'https://user:pass@example.com/x'),
      'fragment route': ('https://x.com/#/route', 'https://x.com/#/route'),
      'uppercase': ('HTTPS://WEBTRIT.COM', 'HTTPS://WEBTRIT.COM'),
      'mixed case bare host': ('Example.Com', 'Example.Com'),
    };

    links.forEach((description, sample) {
      final (text, expected) = sample;
      test(description, () => expect(linkIn(text), expected));
    });

    test('finds every link in a message, in order', () {
      final links = detectLinks('see example.com and www.other.org today');

      expect(links.map((e) => e.value), ['example.com', 'www.other.org']);
      expect(links.map((e) => (e.start, e.end)), [(4, 15), (20, 33)]);
    });

    test('reports offsets that cut the link out of the text', () {
      const text = 'open https://example.com/a now';
      final link = firstLink(text)!;

      expect(text.substring(link.start, link.end), link.value);
    });

    test('a link at the very start and the very end', () {
      expect(detectLinks('example.com').single.value, 'example.com');
      expect(linkIn('go to https://example.com/x'), 'https://example.com/x');
    });
  });

  group('parentheses that belong to the URL stay in it', () {
    // Browsers copy Wikipedia titles with literal parentheses and the rest percent-encoded, so this
    // is the shape users actually paste.
    const wikipediaTitle = 'https://uk.wikipedia.org/wiki/%D0%9F%D1%82%D0%B0%D1%85_(%D0%B1%D0%BE%D0%B3)';

    const links = {
      'percent-encoded title in parentheses': (wikipediaTitle, wikipediaTitle),
      'ascii title in parentheses': (
        'https://en.wikipedia.org/wiki/Bird_(god)',
        'https://en.wikipedia.org/wiki/Bird_(god)',
      ),
      'parentheses in the middle of the path': ('https://example.com/a_(b)_c/d', 'https://example.com/a_(b)_c/d'),
      'nested parentheses': ('https://example.com/a_(b_(c))', 'https://example.com/a_(b_(c))'),
      'link followed by prose': ('read $wikipediaTitle first', wikipediaTitle),
      'link with parentheses wrapped in parentheses': ('(see $wikipediaTitle)', wikipediaTitle),
      'percent-encoded parentheses': (
        'https://uk.wikipedia.org/wiki/%D0%9F%D1%82%D0%B0%D1%85_%28%D0%B1%D0%BE%D0%B3%29',
        'https://uk.wikipedia.org/wiki/%D0%9F%D1%82%D0%B0%D1%85_%28%D0%B1%D0%BE%D0%B3%29',
      ),
      'balanced square brackets': ('https://example.com/?q[]=1&q[]=2', 'https://example.com/?q[]=1&q[]=2'),
      'balanced braces': ('https://example.com/{id}/x', 'https://example.com/{id}/x'),
    };

    links.forEach((description, sample) {
      final (text, expected) = sample;
      test(description, () => expect(linkIn(text), expected));
    });

    test('leaves out the closing parenthesis of the surrounding prose', () {
      expect(linkIn('see the docs (https://example.com/a) first'), 'https://example.com/a');
    });

    test('leaves out a closing parenthesis and the full stop after it', () {
      expect(linkIn('(see https://example.com/a.)'), 'https://example.com/a');
    });

    test('leaves out an unbalanced opening parenthesis', () {
      expect(linkIn('https://example.com/a(b'), 'https://example.com/a');
    });

    test('leaves out a bracket that closes a different kind', () {
      expect(linkIn('[see https://example.com/a(b]'), 'https://example.com/a');
    });

    test('a bare host in parentheses', () {
      expect(linkIn('the site (example.com) is down'), 'example.com');
    });
  });

  group('characters a URL may carry stay in it', () {
    // RFC 3986 sub-delims and the brackets of a query array. Each one used to end the link, so the
    // tap target and the preview both got a shorter, different address.
    const links = {
      'semicolon': 'https://example.com/a;b',
      'apostrophe': "https://en.wikipedia.org/wiki/Don't_Stop_Me_Now",
      'exclamation mark': 'https://example.com/a!b',
      'asterisk': 'https://example.com/a*b',
      'dollar sign': r'https://example.com/a$b',
      'square brackets of a query array': 'https://example.com/?q[]=1&q[]=2',
      'pipe in a query': 'https://example.com/?b=c|d',
      'plus in a query': 'https://google.com/search?q=a+b',
      'tilde in a path': 'https://example.com/~user',
      'underscores in a path': 'https://example.com/a_b_c',
      'at sign in a query': 'https://example.com/unsubscribe?email=john@mail.com',
      'comma in a path': 'https://example.com/a,b/c',
      'colon in a path': 'https://example.com/a:b/c',
    };

    links.forEach((description, url) {
      test(description, () => expect(linkIn('open $url now'), url));
    });
  });

  group('sentence punctuation after a link is left out', () {
    const trailing = {
      'full stop': 'go to https://example.com/a.',
      'comma': 'see https://example.com/a, then call',
      'colon': 'at https://example.com/a: the list',
      'question mark': 'did you see https://example.com/a?',
      'exclamation mark': 'look: https://example.com/a!',
      'semicolon': 'see https://example.com/a; then call',
      'apostrophe closing a quotation': "it is 'https://example.com/a' now",
      'double quote closing a quotation': 'see "https://example.com/a".',
      'asterisk closing emphasis': 'see https://example.com/a* for details',
      'underscore closing emphasis': 'see _https://example.com/a_ now',
      'tilde closing emphasis': 'see ~https://example.com/a~ now',
      'several marks at once': 'really? https://example.com/a?!.',
      'angle brackets around it': 'see <https://example.com/a> now',
      'a backtick after it': 'run `https://example.com/a` now',
    };

    trailing.forEach((description, text) {
      test(description, () => expect(linkIn(text), 'https://example.com/a'));
    });

    test('a question mark ending the sentence after a bare host', () {
      expect(linkIn('Visit example.com?'), 'example.com');
    });

    test('a question mark after a bare path', () => expect(linkIn('is it at example.com/faq?'), 'example.com/faq'));

    test('keeps a question mark that opens a query', () {
      expect(linkIn('https://example.com/search?q=a'), 'https://example.com/search?q=a');
    });

    test('keeps a trailing slash', () => expect(linkIn('see https://example.com/a/.'), 'https://example.com/a/'));
  });

  group('non-ASCII addresses', () {
    // Escaped because source files stay ASCII. These are the decoded forms a user gets by typing an
    // address, or by copying it from an app that shows it decoded.
    const cyrillicPath = 'https://uk.wikipedia.org/wiki/Птах_(бог)';
    const cyrillicHost = 'сайт.укр';
    const cyrillicRfHost = 'пример.рф/путь';
    const chineseHost = 'https://例子.测试';

    test('a Cyrillic path', () => expect(linkIn('see $cyrillicPath now'), cyrillicPath));

    test('a Cyrillic host with a Cyrillic TLD', () => expect(linkIn('see $cyrillicHost now'), cyrillicHost));

    test('a Cyrillic host and path', () => expect(linkIn('see $cyrillicRfHost now'), cyrillicRfHost));

    test('an internationalised host behind a scheme', () => expect(linkIn('see $chineseHost now'), chineseHost));

    test('a punycode TLD', () => expect(linkIn('see example.xn--p1ai now'), 'example.xn--p1ai'));

    test('a Cyrillic word with a full stop is still not a link', () {
      expect(detectLinks('привіт.як справи'), isEmpty);
    });
  });

  group('bare hosts on newer TLDs', () {
    const hosts = ['example.academy', 'example.ninja/x', 'example.agency', 'example.kyiv'];

    for (final host in hosts) {
      test(host, () => expect(linkIn('see $host now'), host));
    }
  });

  group('one address never turns into another', () {
    // Anything matched is opened as https when it carries no scheme of its own, so a match that
    // drops an unsupported scheme sends the user somewhere else.
    const unsupported = [
      'ws://example.com/socket',
      'wss://sub.example.com/socket',
      'ftp://files.example.net/x.txt',
      'file:///etc/hosts',
    ];

    for (final text in unsupported) {
      test(
        '$text is not linkified',
        () => expect(detectLinks(text).where((e) => e.type == TextEntityType.link), isEmpty),
      );
    }

    test('an IPv6 literal behind a scheme', () {
      expect(linkIn('admin at http://[::1]:8080/ now'), 'http://[::1]:8080/');
    });

    test('a path segment that looks like a host is not a link of its own', () {
      expect(detectLinks('see some/path/example.com here'), isEmpty);
    });
  });

  group('email addresses', () {
    const addresses = {
      'plain': 'john@mail.com',
      'dotted local part': 'a.b@example.org',
      'plus tag in the local part': 'a+tag@gmail.com',
      'apostrophe in the local part': "o'brien@example.ie",
      'TLD longer than four letters': 'john@company.email',
      'museum TLD': 'john@example.museum',
      'subdomains': 'john@mail.co.uk',
      'digits': 'user42@example42.com',
    };

    addresses.forEach((description, address) {
      test(description, () => expect(emailIn('write to $address today'), address));
    });

    test('leaves out a full stop ending the sentence', () {
      expect(emailIn('write to john@mail.co.uk.'), 'john@mail.co.uk');
    });

    test('leaves out a quote around it', () => expect(emailIn("write to 'john@mail.com' now"), 'john@mail.com'));

    test('is not also read as a link to its domain', () {
      expect(detectLinks('write to john@mail.com').map((e) => e.type), [TextEntityType.email]);
    });

    test('a host before the at sign is not a link either', () {
      expect(detectLinks('write to a.io@example.com').map((e) => e.type), [TextEntityType.email]);
    });

    test('an address and a link side by side', () {
      final entities = detectLinks('write john@mail.com or visit example.com');

      expect(entities.map((e) => (e.type, e.value)), [
        (TextEntityType.email, 'john@mail.com'),
        (TextEntityType.link, 'example.com'),
      ]);
    });

    test('text with an at sign and no domain is not an address', () => expect(detectLinks('meet @ noon'), isEmpty));
  });

  group('a link wins over an address inside it', () {
    const urls = [
      'https://example.com/unsubscribe?email=john@mail.com',
      'https://example.com/?to=a.b@c.org&x=1',
      'https://user:pass@example.com/x',
    ];

    for (final url in urls) {
      test(url, () {
        final entities = detectLinks('open $url now');

        expect(entities.map((e) => (e.type, e.value)), [(TextEntityType.link, url)]);
      });
    }
  });
}
