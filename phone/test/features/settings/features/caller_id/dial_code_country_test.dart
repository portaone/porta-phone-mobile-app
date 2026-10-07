import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:country_code_picker/country_code_picker.dart';

import 'package:webtrit_phone/features/settings/features/caller_id/widgets/dial_code_country.dart';
import 'package:webtrit_phone/features/settings/features/caller_id/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/caller_id_settings.dart';

void main() {
  /// The picker's own list, by dial code: the countries it would have to
  /// choose between when handed that code alone.
  Map<String, List<String>> countriesByDialCode() {
    final byDialCode = <String, List<String>>{};
    for (final country in codes) {
      byDialCode.putIfAbsent(country['dial_code']!, () => []).add(country['code']!);
    }
    return byDialCode;
  }

  group('the table of shared dial codes', () {
    test('has a row for every code the picker lists more than once, bar +7', () {
      final shared = {
        for (final MapEntry(key: dialCode, value: countries) in countriesByDialCode().entries)
          if (countries.length > 1) dialCode,
      };

      // +7 is shared too and is left out deliberately.
      expect(mainCountryOfSharedDialCode.keys.toSet(), shared.difference({'+7'}));
    });

    test('names a country that really has the code', () {
      final byDialCode = countriesByDialCode();

      for (final MapEntry(key: dialCode, value: country) in mainCountryOfSharedDialCode.entries) {
        expect(byDialCode[dialCode], contains(country), reason: '$country is not behind $dialCode');
      }
    });

    test('shows the country the web dialer shows where the list order did not', () {
      expect(countrySelectionForDialCode('+1'), 'US');
      expect(countrySelectionForDialCode('+44'), 'GB');
      expect(countrySelectionForDialCode('+47'), 'NO');
      expect(countrySelectionForDialCode('+358'), 'FI');
    });

    test('leaves +7 to the picker', () {
      expect(countrySelectionForDialCode('+7'), '+7');
    });

    test('leaves a code one country owns as it is', () {
      expect(countrySelectionForDialCode('+54'), '+54');
      // Inside the +1 plan, with a dial code of its own.
      expect(countrySelectionForDialCode('+1268'), '+1268');
    });
  });

  group('a saved rule', () {
    Future<void> pumpRule(WidgetTester tester, String prefix) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Keyed by the code, so each rule is a row of its own, the way the
        // screen builds them, rather than one row told to change.
        home: Scaffold(
          body: MatcherTile(key: ValueKey(prefix), matcher: PrefixMatcher(prefix, '555306'), index: 0),
        ),
      ),
    );

    String shownFlag(WidgetTester tester) {
      final flag = tester.widget<Image>(
        find.descendant(of: find.byType(CountryCodePicker), matching: find.byType(Image)),
      );
      return (flag.image as AssetImage).assetName;
    }

    testWidgets('for +1 carries the flag of the United States, not of Canada', (tester) async {
      // The report: +1 picked with the American flag, saved, shown as Canada.
      await pumpRule(tester, '+1');

      expect(shownFlag(tester), 'flags/us.png');
    });

    testWidgets('for the other shared codes carries the flag the dialer shows', (tester) async {
      for (final (prefix, flag) in [('+44', 'gb'), ('+47', 'no'), ('+358', 'fi'), ('+61', 'au')]) {
        await pumpRule(tester, prefix);

        expect(shownFlag(tester), 'flags/$flag.png', reason: prefix);
      }
    });

    testWidgets('for a code of one country carries that country', (tester) async {
      await pumpRule(tester, '+54');
      expect(shownFlag(tester), 'flags/ar.png');

      await pumpRule(tester, '+1268');
      expect(shownFlag(tester), 'flags/ag.png');
    });

    testWidgets('still reads out the code it stores', (tester) async {
      await pumpRule(tester, '+1');

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('=>  555306'), findsOneWidget);
    });
  });
}
