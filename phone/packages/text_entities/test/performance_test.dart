import 'package:test/test.dart';
import 'package:text_entities/text_entities.dart';

/// Detection and parsing run on the UI thread, on every rebuild of a message. A regex that
/// re-scanned from every offset once cost ~7 s on one 19k-character token - an ANR on Android and a
/// watchdog kill on iOS - so every input shape that could make either step quadratic is timed here.
///
/// The budget is generous enough to absorb a slow CI machine while still failing a quadratic
/// regression, which costs seconds rather than milliseconds.
void main() {
  const budget = Duration(seconds: 1);

  final inputs = {
    'an unbroken token': 'ConversationsScreenPageRoute' * 700,
    'a dot-heavy token': 'ab.' * 6000,
    'an unbroken Cyrillic token': '\u0430' * 19000,
    'unbalanced parentheses in a path': 'https://example.com/${'(a' * 9000}',
    'nested openings in a path': 'https://example.com/${'((' * 9000}',
    'balanced groups ending unbalanced': 'https://example.com/${'(a)' * 6000}(',
    'a colon-heavy token after a scheme': 'https://${':' * 19000}',
    'many links': 'example.com ' * 1600,
    'an at-sign-heavy token': 'a@' * 9500,
    'a plus-joined local part': '${'a+' * 9500}@',
    'unclosed star openers': '*a ' * 6000,
    'unclosed underscore openers': ' _a' * 6000,
    'closers without openers': 'a* ' * 6000,
    'alternating markers': '*_~+' * 4750,
    'deeply alternating pairs': '${'*_' * 4000}x${'_*' * 4000}',
    'backticks': '`a' * 9500,
    'many quote lines': '> a https://x.com\n' * 1000,
  };

  inputs.forEach((description, input) {
    test('detection over $description (${input.length} chars)', () {
      final stopwatch = Stopwatch()..start();
      detectLinks(input);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(budget));
    });

    test('parsing $description (${input.length} chars)', () {
      final stopwatch = Stopwatch()..start();
      parseMessage(input);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(budget));
    });
  });
}
