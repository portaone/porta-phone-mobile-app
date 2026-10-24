import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intl/intl.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:api/api.dart' show AppType;

import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Widget wrap(
    ActiveSession session, {
    bool revoking = false,
    ValueChanged<ActiveSession>? onRevoke,
    Version? ownAppVersion,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SessionTile(
          session: session,
          index: 0,
          dateFormat: dateFormat,
          revoking: revoking,
          onRevoke: onRevoke ?? (_) {},
          ownAppVersion: ownAppVersion,
        ),
      ),
    );
  }

  testWidgets('names the device after the User-Agent, and the system under it', (tester) async {
    await tester.pumpWidget(
      wrap(
        ActiveSession(
          id: 'a',
          current: false,
          appType: AppType.android,
          userAgent: 'PortaPhone/1.18.0+0 (Samsung Galaxy XCover 5; Android: 14)',
          lastActivityLocation: 'ua',
          lastActivityAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ),
    );

    expect(find.text('Samsung Galaxy XCover 5'), findsOneWidget);
    expect(find.text('Android 14 \u00B7 UA \u00B7 Active now'), findsOneWidget);
    expect(find.text('Android app'), findsNothing);
  });

  testWidgets('falls back to the app type when the User-Agent is not one the app writes', (tester) async {
    await tester.pumpWidget(
      wrap(const ActiveSession(id: 'a', current: false, appType: AppType.ios, userAgent: 'Dart/3.9 (dart:io)')),
    );

    expect(find.text('iOS app'), findsOneWidget);
  });

  testWidgets('falls back to an unknown device when nothing names it', (tester) async {
    await tester.pumpWidget(wrap(const ActiveSession(id: 'a', current: false)));

    expect(find.text('Unknown device'), findsOneWidget);
  });

  testWidgets('says how long ago the device was seen, and the date once it is more than a day', (tester) async {
    final now = DateTime.now();
    ActiveSession seenAt(DateTime at) =>
        ActiveSession(id: 'a', current: false, appType: AppType.android, lastActivityAt: at);

    await tester.pumpWidget(wrap(seenAt(now.subtract(const Duration(minutes: 12)))));
    expect(find.text('12 minutes ago'), findsOneWidget);

    await tester.pumpWidget(wrap(seenAt(now.subtract(const Duration(hours: 2)))));
    expect(find.text('2 hours ago'), findsOneWidget);

    await tester.pumpWidget(wrap(seenAt(DateTime(2026, 8, 12, 18, 30))));
    expect(find.text('2026-08-12 18:30'), findsOneWidget);
  });

  testWidgets('the current device is seen like the others and offers no sign-out', (tester) async {
    await tester.pumpWidget(
      wrap(
        ActiveSession(
          id: 'a',
          current: true,
          appType: AppType.android,
          userAgent: 'PortaPhone/1.18.0+0 (Google Pixel 9; Android: 17)',
          createdAt: DateTime(2026, 8, 1, 10),
          lastActivityAt: DateTime.now(),
        ),
      ),
    );

    expect(find.text('Android 17 \u00B7 Active now'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('says the app version only where it is not this build', (tester) async {
    const session = ActiveSession(
      id: 'a',
      current: false,
      appType: AppType.android,
      userAgent: 'PortaPhone/1.17.0+0 (SM-G525F; Android: 14)',
    );

    await tester.pumpWidget(wrap(session, ownAppVersion: Version(1, 18, 0)));
    expect(find.text('App 1.17.0'), findsOneWidget);

    await tester.pumpWidget(wrap(session, ownAppVersion: Version(1, 17, 0)));
    expect(find.textContaining('App '), findsNothing);

    await tester.pumpWidget(wrap(session));
    expect(find.textContaining('App '), findsNothing);

    await tester.pumpWidget(
      wrap(
        const ActiveSession(id: 'a', current: false, appType: AppType.web, userAgent: 'Dialer/1.18 (Chrome; Web: 130)'),
        ownAppVersion: Version(1, 18, 0),
      ),
    );
    expect(find.textContaining('App '), findsNothing);
  });

  testWidgets('shows a tablet by its name', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ActiveSession(
          id: 'a',
          current: false,
          appType: AppType.android,
          userAgent: 'PortaPhone/1.18.0+0 (Lenovo Tab M8 [4th Gen]; Android: 13)',
        ),
      ),
    );

    expect(find.byIcon(Icons.tablet_android), findsOneWidget);
  });

  testWidgets('reports the session to revoke when its button is tapped', (tester) async {
    const session = ActiveSession(id: 'a', current: false, appType: AppType.android);
    final revoked = <ActiveSession>[];
    await tester.pumpWidget(wrap(session, onRevoke: revoked.add));

    await tester.tap(find.byIcon(Icons.logout));

    expect(revoked, equals([session]));
  });

  testWidgets('shows progress instead of the button while the session is being revoked', (tester) async {
    await tester.pumpWidget(
      wrap(const ActiveSession(id: 'a', current: false, appType: AppType.android), revoking: true),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);
    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
  });
}
