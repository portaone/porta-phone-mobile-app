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

    test('takes the country picked for a rule only when it has the rule\'s code', () {
      expect(countrySelectionForRule('+1', 'CA'), 'CA');
      expect(countrySelectionForRule('+1', 'GB'), 'US');
      expect(countrySelectionForRule('+1', 'XX'), 'US');
      expect(countrySelectionForRule('+1', null), 'US');
      expect(countrySelectionForRule('+54', null), '+54');
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
    Future<void> pumpRule(WidgetTester tester, String prefix, {String? country}) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Keyed by the code, so each rule is a row of its own, the way the
        // screen builds them, rather than one row told to change.
        home: Scaffold(
          body: MatcherTile(
            key: ValueKey(prefix),
            matcher: PrefixMatcher(prefix, '555306', country: country),
            index: 0,
          ),
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

    testWidgets('for +1 picked as Canada carries the flag of Canada', (tester) async {
      // +1 is shared, so only the country kept with the rule can tell Canada
      // from the United States, which the code alone would show.
      await pumpRule(tester, '+1', country: 'CA');

      expect(shownFlag(tester), 'flags/ca.png');
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('with a country of another code carries the flag of its own code', (tester) async {
      // The picker draws the code of the country it is handed: GB would turn
      // a +1 rule into a +44 one on screen.
      await pumpRule(tester, '+1', country: 'GB');

      expect(shownFlag(tester), 'flags/us.png');
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('with a country the picker does not know carries the flag of its code', (tester) async {
      // Unknown to the picker, the code would fall to the first country of
      // its list, Afghanistan.
      await pumpRule(tester, '+1', country: 'XX');

      expect(shownFlag(tester), 'flags/us.png');
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('names the country it keeps to a screen reader', (tester) async {
      await pumpRule(tester, '+1', country: 'CA');

      expect(find.bySemanticsLabel('Calls to +1, Canada, show 555306'), findsOneWidget);
    });

    testWidgets('without a country reads out the code and the number alone', (tester) async {
      await pumpRule(tester, '+1');

      expect(find.bySemanticsLabel('Calls to +1 show 555306'), findsOneWidget);
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
