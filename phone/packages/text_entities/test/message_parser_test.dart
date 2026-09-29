import 'package:test/test.dart';
import 'package:text_entities/text_entities.dart';

/// The parse as `(type, shown text)` pairs, in entity order.
List<(TextEntityType, String)> shape(String source) =>
    parseMessage(source).entities.map((e) => (e.type, e.value)).toList();

String shown(String source) => parseMessage(source).text;

void main() {
  group('plain text', () {
    const texts = [
      'no markup here',
      '',
      'multi\nline\ntext',
      'snake_case_name and my_file.dart',
      '1+1=2 and a+b+c',
      '2 * 3 * 4 = 24',
      'files in ~/tmp and ~user',
      'a > b and b -> c',
      'a lone * star and a lone _ bar',
      'price: 5*',
      'x`y',
    ];

    for (final text in texts) {
      test('"${text.replaceAll('\n', r'\n')}" is shown as written, with no entities', () {
        final parsed = parseMessage(text);

        expect(parsed.text, text);
        expect(parsed.entities, isEmpty);
      });
    }
  });

  group('emphasis', () {
    const cases = {
      '*bold*': ('bold', TextEntityType.bold),
      '_italic_': ('italic', TextEntityType.italic),
      '~gone~': ('gone', TextEntityType.strikethrough),
      '+under+': ('under', TextEntityType.underline),
      '`code`': ('code', TextEntityType.code),
    };

    cases.forEach((source, expected) {
      final (text, type) = expected;

      test('$source is shown as "$text" with one ${type.name} entity', () {
        final parsed = parseMessage(source);

        expect(parsed.text, text);
        expect(parsed.entities, [TextEntity(type: type, start: 0, end: text.length, value: text)]);
      });
    });

    test('inside a sentence, with the offsets of the shown text', () {
      final parsed = parseMessage('this is *very* important');

      expect(parsed.text, 'this is very important');
      expect(parsed.entities.single, const TextEntity(type: TextEntityType.bold, start: 8, end: 12, value: 'very'));
    });

    test('several words', () => expect(shape('a *b c d* e'), [(TextEntityType.bold, 'b c d')]));

    test('next to punctuation', () {
      expect(shown('(*a*), "_b_"!'), '(a), "b"!');
      expect(shape('(*a*), "_b_"!'), [(TextEntityType.bold, 'a'), (TextEntityType.italic, 'b')]);
    });

    test('different markers nest', () {
      final parsed = parseMessage('*bold _both_ bold*');

      expect(parsed.text, 'bold both bold');
      expect(shape('*bold _both_ bold*'), [(TextEntityType.bold, 'bold both bold'), (TextEntityType.italic, 'both')]);
    });

    test('two spans side by side', () {
      expect(shape('*a* and _b_'), [(TextEntityType.bold, 'a'), (TextEntityType.italic, 'b')]);
    });

    test('a marker does not open before a space', () => expect(shape('* not bold*'), isEmpty));

    test('a marker does not close after a space', () => expect(shape('*not bold *'), isEmpty));

    test('a marker does not open inside a word', () => expect(shape('a*b* and x_y_'), isEmpty));

    test('a marker does not close inside a word', () => expect(shape('*a*b'), isEmpty));

    test('an unclosed marker is shown as written', () {
      expect(shown('*unclosed and _also'), '*unclosed and _also');
      expect(shape('*unclosed and _also'), isEmpty);
    });

    test('emphasis does not cross a line break', () {
      expect(shown('*first\nsecond*'), '*first\nsecond*');
      expect(shape('_a\nb_'), isEmpty);
    });

    test('the same marker does not nest in itself', () => expect(shape('*a *b* c*'), [(TextEntityType.bold, 'a *b')]));

    test('code content is shown as written, with no emphasis inside', () {
      final parsed = parseMessage('run `my_var_name *x*` now');

      expect(parsed.text, 'run my_var_name *x* now');
      expect(shape('run `my_var_name *x*` now'), [(TextEntityType.code, 'my_var_name *x*')]);
    });

    test('an empty pair of markers is shown as written', () => expect(shown('** and __'), '** and __'));
  });

  group('links are atomic', () {
    test('a link is an entity of its own', () {
      final parsed = parseMessage('see https://example.com/a_b now');

      expect(parsed.text, 'see https://example.com/a_b now');
      expect(
        parsed.entities.single,
        const TextEntity(type: TextEntityType.link, start: 4, end: 27, value: 'https://example.com/a_b'),
      );
    });

    const untouched = {
      'an underscore earlier on the line': 'rename my_file then open https://example.com/a_b',
      'an underscore on an earlier line': 'my_var\nsee https://example.com/x_y',
      'a plus earlier on the line': 'search 1+1 at https://google.com/search?q=a+b',
      'a tilde earlier on the line': 'files in ~/tmp, docs at https://example.com/~user',
      'an opener whose only closer is inside the link': 'a _b https://example.com/c_d',
      'a star inside the link': 'see https://example.com/a*b*c now',
    };

    untouched.forEach((description, text) {
      test('$description: text unchanged, link whole', () {
        final parsed = parseMessage(text);

        expect(parsed.text, text);
        expect(parsed.entities.where((e) => e.type != TextEntityType.link), isEmpty);
        expect(parsed.entities.where((e) => e.type == TextEntityType.link).single.value, firstLink(text)!.value);
      });
    });

    const wrapped = {
      '*https://example.com*': TextEntityType.bold,
      '_https://example.com_': TextEntityType.italic,
      '~https://example.com~': TextEntityType.strikethrough,
      '+https://example.com+': TextEntityType.underline,
      '`https://example.com`': TextEntityType.code,
    };

    wrapped.forEach((source, type) {
      test('$source is a link inside ${type.name}, markers removed', () {
        final parsed = parseMessage(source);

        expect(parsed.text, 'https://example.com');
        expect(shape(source), [(type, 'https://example.com'), (TextEntityType.link, 'https://example.com')]);
      });
    });

    test('emphasis around a link and more text', () {
      expect(shape('*see https://example.com/a now*'), [
        (TextEntityType.bold, 'see https://example.com/a now'),
        (TextEntityType.link, 'https://example.com/a'),
      ]);
    });

    test('an address starting with an underscore is not italic', () {
      final parsed = parseMessage('write to _service@example.com now');

      expect(parsed.text, 'write to _service@example.com now');
      expect(shape('write to _service@example.com now'), [(TextEntityType.email, '_service@example.com')]);
    });

    test('underscores around an address are italic around it', () {
      expect(shape('_john@example.com_'), [
        (TextEntityType.italic, 'john@example.com'),
        (TextEntityType.email, 'john@example.com'),
      ]);
    });

    test('asterisks around an address are bold around it', () {
      expect(shape('*john@example.com*'), [
        (TextEntityType.bold, 'john@example.com'),
        (TextEntityType.email, 'john@example.com'),
      ]);
    });

    test('an email address is atomic too', () {
      expect(shape('_mail john_doe@mail.com_'), [
        (TextEntityType.italic, 'mail john_doe@mail.com'),
        (TextEntityType.email, 'john_doe@mail.com'),
      ]);
    });

    test('offsets of a link after removed markers point at the link', () {
      final parsed = parseMessage('*a* https://example.com');
      final link = parsed.entities.firstWhere((e) => e.type == TextEntityType.link);

      expect(parsed.text.substring(link.start, link.end), 'https://example.com');
    });
  });

  group('quotes', () {
    test('a line starting with > is a quote, the prefix removed', () {
      final parsed = parseMessage('> quoted text');

      expect(parsed.text, 'quoted text');
      expect(
        parsed.entities.single,
        const TextEntity(type: TextEntityType.quote, start: 0, end: 11, value: 'quoted text'),
      );
    });

    test('the prefix works without a space too', () => expect(shape('>quoted'), [(TextEntityType.quote, 'quoted')]));

    test('only the quoted line is a quote', () {
      final parsed = parseMessage('> asked\nanswered');

      expect(parsed.text, 'asked\nanswered');
      expect(shape('> asked\nanswered'), [(TextEntityType.quote, 'asked')]);
    });

    test('consecutive quoted lines are quotes each', () {
      expect(shape('> one\n> two'), [(TextEntityType.quote, 'one'), (TextEntityType.quote, 'two')]);
    });

    test('a > inside a line is not a quote', () {
      expect(shape('go -> https://example.com'), [(TextEntityType.link, 'https://example.com')]);
      expect(shape('a > b, see https://example.com'), [(TextEntityType.link, 'https://example.com')]);
    });

    test('a lone > is text', () {
      expect(shown('>'), '>');
      expect(shape('> '), isEmpty);
    });

    test('a link inside a quote is found', () {
      expect(shape('> see https://example.com'), [
        (TextEntityType.quote, 'see https://example.com'),
        (TextEntityType.link, 'https://example.com'),
      ]);
    });

    test('emphasis inside a quote', () {
      expect(shape('> a *b*'), [(TextEntityType.quote, 'a b'), (TextEntityType.bold, 'b')]);
    });
  });

  group('the result is consistent', () {
    const samples = [
      '> *quoted* https://example.com/a_(b)\nplain _x_ john@mail.com `code`',
      'a *b _c ~d +e+ d~ c_ b* https://x.com/y?z=1',
      '*https://example.com* and _john@mail.com_',
    ];

    for (final sample in samples) {
      test('every entity value is the text it covers: "${sample.replaceAll('\n', r'\n')}"', () {
        final parsed = parseMessage(sample);

        for (final entity in parsed.entities) {
          expect(parsed.text.substring(entity.start, entity.end), entity.value);
        }
      });

      test('entities never cross: "${sample.replaceAll('\n', r'\n')}"', () {
        final entities = parseMessage(sample).entities;

        for (final a in entities) {
          for (final b in entities) {
            final disjoint = a.end <= b.start || b.end <= a.start;
            final nested = (a.start <= b.start && b.end <= a.end) || (b.start <= a.start && a.end <= b.end);
            expect(disjoint || nested, isTrue, reason: '$a crosses $b');
          }
        }
      });

      test('an enclosing entity comes before the ones it contains: "${sample.replaceAll('\n', r'\n')}"', () {
        final entities = parseMessage(sample).entities;

        for (var i = 1; i < entities.length; i++) {
          final previous = entities[i - 1];
          final current = entities[i];
          expect(
            previous.start < current.start || (previous.start == current.start && previous.end >= current.end),
            isTrue,
          );
        }
      });
    }
  });
}
