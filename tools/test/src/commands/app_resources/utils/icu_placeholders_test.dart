import 'package:test/test.dart';

import 'package:webtrit_phone_tools/src/commands/app_resources/utils/utils.dart';

void main() {
  group('IcuPlaceholders.namesIn', () {
    test('reads plain arguments', () {
      expect(IcuPlaceholders.namesIn('{description} (code: {code})'), {'description', 'code'});
    });

    test('reads none from plain text', () {
      expect(IcuPlaceholders.namesIn('Could not forward'), isEmpty);
    });

    test('reads an argument used twice once', () {
      expect(IcuPlaceholders.namesIn('{name} called, call {name} back'), {'name'});
    });

    test('reads the selector of a plural and the arguments of its branches, not its branch keys', () {
      const message = '{count, plural, =0{No calls} one{{count} call from {name}} other{{count} calls}}';

      expect(IcuPlaceholders.namesIn(message), {'count', 'name'});
    });

    test('reads a select with spaces around its branches', () {
      const message = '{gender, select, male {He} female {She} other {They}} called {name}';

      expect(IcuPlaceholders.namesIn(message), {'gender', 'name'});
    });

    test('reads through a select nested in a plural', () {
      const message = '{count, plural, one{{gender, select, male{his} other{their}} call from {name}} other{calls}}';

      expect(IcuPlaceholders.namesIn(message), {'count', 'gender', 'name'});
    });

    // `use-escaping` is off in the app, so `gen-l10n` reads an apostrophe as
    // plain text: a quoted argument is still an argument.
    test('treats an apostrophe as plain text', () {
      expect(IcuPlaceholders.namesIn("Couldn't forward to {name}"), {'name'});
      expect(IcuPlaceholders.namesIn("'{name}'"), {'name'});
    });

    test('refuses an unclosed argument', () {
      expect(IcuPlaceholders.namesIn('Hello {name'), isNull);
    });

    test('refuses a stray closing brace', () {
      expect(IcuPlaceholders.namesIn('Hello }'), isNull);
    });

    test('refuses an argument that is not an identifier', () {
      expect(IcuPlaceholders.namesIn('Hello {}'), isNull);
      expect(IcuPlaceholders.namesIn('Hello {first name}'), isNull);
    });

    test('refuses an unclosed branch', () {
      expect(IcuPlaceholders.namesIn('{count, plural, one{call other{calls}}'), isNull);
    });
  });
}
