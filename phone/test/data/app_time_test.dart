import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clock/clock.dart';

import 'package:webtrit_phone/data/app_time.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

void main() {
  final at = DateTime(2026, 11, 6, 15, 19);
  final appTime = AppTime(is24HourFormat: true);

  // The date data comes from Flutter's own localizations, as in the app:
  // nothing initialises intl by hand here.
  Widget app(Locale locale, String Function(BuildContext) builder) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) => Text(builder(context))),
  );

  testWidgets('dates are written in the language the app is shown in', (tester) async {
    String show(BuildContext context) {
      final locale = Localizations.localeOf(context);
      return [
        appTime.dateTimeFormat(locale).format(at),
        appTime.dayMonthFormat(locale).format(at),
        appTime.weekdayFormat(locale).format(at),
        appTime.weekdayDayMonthFormat(locale).format(at),
      ].join(' | ');
    }

    await tester.pumpWidget(app(const Locale('en'), show));
    expect(find.text('Nov 6, 2026 15:19 | 6 Nov | Friday | Fri, 6 Nov'), findsOneWidget);

    await tester.pumpWidget(app(const Locale('fr'), show));
    await tester.pumpAndSettle();
    expect(find.text('6 nov. 2026 15:19 | 6 nov. | vendredi | ven., 6 nov.'), findsOneWidget);

    await tester.pumpWidget(app(const Locale('uk'), show));
    await tester.pumpAndSettle();
    // Ukrainian puts a narrow no-break space between the year and its "р.".
    expect(find.text('6 лист. 2026\u202fр. 15:19 | 6 лист. | пʼятниця | пт, 6 лист.'), findsOneWidget);
  });

  testWidgets('a moment today is a clock time, any other a date', (tester) async {
    late TimeOrDateFormat format;
    await tester.pumpWidget(
      app(const Locale('fr'), (context) {
        format = appTime.timeOrDateFormat(Localizations.localeOf(context));
        return '';
      }),
    );
    await tester.pumpAndSettle();

    // A fixed clock, so the test does not depend on the day or the hour it runs at.
    withClock(Clock.fixed(DateTime(2026, 11, 9, 12)), () {
      expect(format.format(DateTime(2026, 11, 9, 0, 1)), '00:01');
      expect(format.format(DateTime(2026, 11, 6, 15, 19)), '6 nov.');
    });
  });
}
