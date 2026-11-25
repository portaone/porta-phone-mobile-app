import 'package:material_ui/material_ui.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:webtrit_phone/features/contact/widgets/presence_info_view.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/styles/styles.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

void main() {
  // The "ago" text is counted from the real clock, so the times are too.
  final now = DateTime.now();

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: const [LeadingAvatarStyles(primary: LeadingAvatarStyle(presenceBadge: PresenceBadgeStyle()))],
      ),
      home: Scaffold(body: child),
    );
  }

  Future<void> pump(WidgetTester tester, {List<PresenceInfo> presenceInfo = const [], bool? registered, DateTime? at}) {
    return tester.pumpWidget(
      wrap(
        PresenceInfoView(
          presenceInfo: presenceInfo,
          registered: registered,
          registeredAsOf: at,
          timeFormat: DateFormat.Hm(),
        ),
      ),
    );
  }

  PresenceInfo published({required bool available}) => PresenceInfo(
    id: 'pbx',
    number: '1001',
    available: available,
    note: '',
    statusIcon: null,
    device: null,
    timeOffsetMin: null,
    timestamp: null,
    activities: const [],
    source: PresenceInfoSource.sip,
    arrivalTime: now,
  );

  group('a contact nobody publishes a status for', () {
    testWidgets('is described by the registration of their phone, named as the source', (tester) async {
      await pump(tester, registered: true, at: now.subtract(const Duration(minutes: 12)));

      // The fact, not the conclusion drawn from it: a registered phone says
      // the device is reachable, not that the person is there.
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Source: PBX registration'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });

    testWidgets('is described as not registered when their phone is not', (tester) async {
      await pump(tester, registered: false, at: now);

      expect(find.text('Not registered'), findsOneWidget);
      expect(find.text('Source: PBX registration'), findsOneWidget);
    });

    testWidgets('carries the time the registration was read', (tester) async {
      await pump(tester, registered: true, at: now.subtract(const Duration(minutes: 12)));

      expect(find.text('Updated:'), findsOneWidget);
      expect(find.text('12 minutes ago'), findsOneWidget);
    });

    testWidgets('carries no time when it is not known', (tester) async {
      await pump(tester, registered: true);

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Updated:'), findsNothing);
    });
  });

  group('the entries of a contact with published statuses', () {
    PresenceInfo record({
      required String id,
      required PresenceInfoSource source,
      bool available = true,
      String? device,
      DateTime? timestamp,
      DateTime? arrivalTime,
    }) => PresenceInfo(
      id: id,
      number: '1001',
      available: available,
      note: '',
      statusIcon: null,
      device: device,
      timeOffsetMin: null,
      timestamp: timestamp,
      activities: const [],
      source: source,
      arrivalTime: arrivalTime ?? now,
    );

    testWidgets('name the source in words a user can follow', (tester) async {
      await pump(
        tester,
        presenceInfo: [record(id: 'app', source: PresenceInfoSource.direct)],
      );
      expect(find.text('Source: app to app (direct)'), findsOneWidget);

      await pump(
        tester,
        presenceInfo: [record(id: 'pbx', source: PresenceInfoSource.sip)],
      );
      expect(find.text('Source: SIP presence'), findsOneWidget);
    });

    testWidgets('spell out which of our clients published the status', (tester) async {
      await pump(
        tester,
        presenceInfo: [
          record(id: 'web', source: PresenceInfoSource.direct, device: 'Web-dialer/0.2.13 (Chrome; macOS)'),
        ],
      );

      expect(find.text('Client: Web-dialer 0.2.13 \u00B7 Chrome \u00B7 macOS'), findsOneWidget);
    });

    testWidgets('show what a third-party device calls itself as it came', (tester) async {
      await pump(
        tester,
        presenceInfo: [record(id: 'desk', source: PresenceInfoSource.sip, device: 'Yealink T54W')],
      );

      expect(find.text('Yealink T54W'), findsOneWidget);
      expect(find.textContaining('Client:'), findsNothing);
    });

    testWidgets('number the devices when there are several', (tester) async {
      await pump(
        tester,
        presenceInfo: [
          record(id: 'phone', source: PresenceInfoSource.direct),
          record(id: 'web', source: PresenceInfoSource.direct, available: false),
        ],
      );

      expect(find.text('Device: 1'), findsOneWidget);
      expect(find.text('Device: 2'), findsOneWidget);
    });

    testWidgets('list a device heard both ways once, with both sources named', (tester) async {
      await pump(
        tester,
        presenceInfo: [
          record(id: 'web', source: PresenceInfoSource.sip),
          record(id: 'web', source: PresenceInfoSource.direct),
        ],
      );

      expect(find.text('Source: SIP presence and app to app'), findsOneWidget);
      expect(find.text('Source: SIP presence'), findsNothing);
      expect(find.textContaining('Device:'), findsNothing);
    });

    testWidgets('keep both records of one source that happen to share an id', (tester) async {
      await pump(
        tester,
        presenceInfo: [
          record(id: 'same', source: PresenceInfoSource.sip),
          record(id: 'same', source: PresenceInfoSource.sip, available: false),
        ],
      );

      expect(find.text('Source: SIP presence'), findsNWidgets(2));
      expect(find.text('Source: PBX registration'), findsNothing);
    });

    testWidgets('never date a status in the future', (tester) async {
      // The publisher's clock runs an hour ahead; the time shown is cut back to
      // when Core heard of the status, as the time the records are ordered by.
      await pump(
        tester,
        presenceInfo: [
          record(
            id: 'fast',
            source: PresenceInfoSource.direct,
            timestamp: now.add(const Duration(hours: 1)),
            arrivalTime: now.subtract(const Duration(minutes: 3)),
          ),
        ],
      );

      expect(find.text('3 minutes ago'), findsOneWidget);
    });
  });

  group('the explanation behind the info button', () {
    testWidgets('opens, names the sources and shows a mark for each case, and closes', (tester) async {
      await pump(tester, registered: true, at: now);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('How to read the status'), findsOneWidget);
      expect(find.textContaining('App to app (direct):'), findsOneWidget);
      expect(find.textContaining('SIP presence:'), findsOneWidget);
      expect(find.textContaining('PBX registration:'), findsOneWidget);
      // One real mark per case: tick, cross, activity, do not disturb, call,
      // registered, not registered.
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.byType(SipPresenceIndicator)),
        findsNWidgets(7),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Ok'));
      await tester.pumpAndSettle();

      expect(find.text('How to read the status'), findsNothing);
    });
  });

  group('a contact with a published status', () {
    testWidgets('is described by it, and the registration is not listed beside it', (tester) async {
      await pump(tester, presenceInfo: [published(available: false)], registered: true, at: now);

      expect(find.text('Unreachable'), findsOneWidget);
      expect(find.text('Source: SIP presence'), findsOneWidget);
      expect(find.text('Registered'), findsNothing);
      expect(find.text('Source: PBX registration'), findsNothing);
    });
  });
}
