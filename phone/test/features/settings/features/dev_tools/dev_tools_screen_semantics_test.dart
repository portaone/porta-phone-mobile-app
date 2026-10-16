import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/dev_tools/view/dev_tools_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../../../../helpers/semantics.dart';

class _MockSystemInfoRepository extends Mock implements SystemInfoRepository {}

class _MockStackRouter extends Mock implements StackRouter {}

StackRouter _router() {
  final router = _MockStackRouter();
  when(
    () => router.canPop(
      ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
      ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
      ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
    ),
  ).thenReturn(false);
  when(() => router.topPage).thenReturn(null);
  when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
  return router;
}

// The dev tools item that makes the next start one without stored server
// details, reached the way automation reaches it.
void main() {
  late _MockSystemInfoRepository repository;
  late int processEnds;

  setUp(() {
    repository = _MockSystemInfoRepository();
    when(() => repository.clear()).thenAnswer((_) async {});
    processEnds = 0;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = _router();
    await tester.pumpWidget(
      Provider<SystemInfoRepository>.value(
        value: repository,
        child: MaterialApp(
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
              child: DevToolsScreen(endProcess: () => processEnds++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('clearing the server details is named, asks first, then clears them and ends the app', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);

    final finder = find.bySemanticsIdentifier(devToolsClearSystemInfoId);
    expectTapTargetSemantics(
      tester,
      finder,
      label: 'Clear stored server details\nCloses the app; the next start loads them first, as after an update',
      identifier: devToolsClearSystemInfoId,
    );

    await tapViaSemantics(tester, finder);
    await tester.pumpAndSettle();
    verifyNever(() => repository.clear());
    expect(processEnds, 0);

    await tester.tap(find.text('Clear and close'));
    await tester.pumpAndSettle();

    verify(() => repository.clear()).called(1);
    expect(processEnds, 1);
    handle.dispose();
  });

  testWidgets('cancelling leaves the server details and the app alone', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(devToolsClearSystemInfoKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.clear());
    expect(processEnds, 0);
  });
}
