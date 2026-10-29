import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo {}

/// A call that could not get the microphone or the camera offers a way to fix it.
/// The way leads to the diagnostic screen, which asks again or opens the system
/// settings when it has to - not straight out of the app to the system settings
/// (App Store Review Guideline 5.1.1(iv)).
void main() {
  late _MockStackRouter router;
  late BuildContext context;

  setUpAll(() => registerFallbackValue(_FakePageRouteInfo()));

  setUp(() {
    router = _MockStackRouter();
    when(() => router.push<Object?>(any())).thenAnswer((_) async => null);
  });

  Future<void> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: Builder(
              builder: (inner) {
                context = inner;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  for (final (name, notification) in <(String, MessageNotification)>[
    ('a media error', const CallUserMediaErrorNotification()),
    ('a call answered without the camera', const CallVideoDowngradedNotification()),
  ]) {
    testWidgets('$name leads to the diagnostic screen', (tester) async {
      await pumpContext(tester);

      notification.action(context)!.onPressed();

      final route = verify(() => router.push<Object?>(captureAny())).captured.single as PageRouteInfo;
      expect(route.routeName, SettingsRouterPageRoute.name);
      expect(route.initialChildren?.single.routeName, DiagnosticScreenPageRoute.name);
    });
  }
}
