import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/undefined/undefined.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockStackRouter router;

  setUp(() {
    router = _MockStackRouter();
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(() => router.maybePop<Object?>(any())).thenAnswer((_) async => true);
  });

  Widget subject(UndefinedType undefinedType) => MaterialApp(
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
        child: UndefinedScreen(undefinedType: undefinedType),
      ),
    ),
  );

  for (final preset in watchPresets) {
    for (final undefinedType in UndefinedType.values) {
      testWidgets('on $preset ${undefinedType.name}: the state page with Continue on the edge', (tester) async {
        preset.apply(tester);
        await tester.pumpWidget(subject(undefinedType));

        expect(find.byType(WatchStatePage), findsOneWidget);
        expect(find.descendant(of: find.byType(WatchEdgeButton), matching: find.text('Continue')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Continue through semantics goes back', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(subject(UndefinedType.deeplinkConfigurationInvalid));

    expect(find.text('Invalid configuration'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsLabel('Continue'));

    verify(() => router.maybePop<Object?>(any())).called(1);
    handle.dispose();
  });
}
