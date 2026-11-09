import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

void main() {
  group('parsing', () {
    test('from language tag', () {
      const l1 = Locale('en');
      expect(LocaleExtension.fromLanguageTag(l1.toLanguageTag()), l1);

      const l2 = Locale('fr', 'CH');
      expect(LocaleExtension.fromLanguageTag(l2.toLanguageTag()), l2);

      const l3 = Locale.fromSubtags(countryCode: 'zh', scriptCode: 'cmn', languageCode: 'TW');
      expect(LocaleExtension.fromLanguageTag(l3.toLanguageTag()), l3);
    });

    test('from incorrect language tag', () {
      expect(() => LocaleExtension.fromLanguageTag(''), throwsA(isAssertionError));
      expect(() => LocaleExtension.fromLanguageTag('a-b-c-d'), throwsA(isArgumentError));
    });
  });

  group('flags', () {
    test('und country code is default', () {
      expect(LocaleExtension.defaultNull.isDefaultNull, true);
      expect(const Locale.fromSubtags(languageCode: 'und', scriptCode: 'und', countryCode: 'und').isDefaultNull, true);
    });

    test('not und country code is not default', () {
      expect(const Locale('en').isDefaultNull, false);
      expect(const Locale.fromSubtags(languageCode: 'uk').isDefaultNull, false);
    });
  });

  group('display name', () {
    Future<String> nameOf(WidgetTester tester, Locale shown, Locale ui) async {
      late String name;
      await tester.pumpWidget(
        MaterialApp(
          locale: ui,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              name = shown.l10n(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return name;
    }

    testWidgets('every supported locale has a name, not its code', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        expect(await nameOf(tester, locale, const Locale('en')), isNot(locale.toString()), reason: '$locale');
      }
    });

    testWidgets('French is named in English and in French', (tester) async {
      expect(await nameOf(tester, const Locale('fr'), const Locale('en')), 'French');
      expect(await nameOf(tester, const Locale('fr'), const Locale('fr')), 'Français');
    });
  });
}
