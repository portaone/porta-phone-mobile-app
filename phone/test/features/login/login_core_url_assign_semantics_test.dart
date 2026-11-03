import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

class _RecordedHistory implements AutocompleteHistoryRepository {
  final saved = <String>[];

  @override
  List<String> getHistory(String key) => saved;

  @override
  Future<void> addToHistory(String key, String value, {int maxItems = 8}) async => saved.add(value);
}

void main() {
  const url = 'core.example.com';

  _MockLoginCubit login({bool processing = false}) {
    final cubit = _MockLoginCubit();
    whenListen(
      cubit,
      const Stream<LoginState>.empty(),
      initialState: LoginState(
        mode: LoginMode.customCore,
        coreUrlInput: const UrlInput.dirty(url),
        processing: processing,
      ),
    );
    return cubit;
  }

  for (final preset in [...watchPresets, handsetPresets.first]) {
    testWidgets('on $preset Proceed acts through semantics and saves the URL', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      final cubit = login();
      final history = _RecordedHistory();
      await pumpCollectingOverflows(
        tester,
        LoginHarness.wrapCubit(cubit, const LoginCoreUrlAssignScreen(), history: history),
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(coreUrlButtonId));

      verify(cubit.loginCoreUrlAssignSubmitted).called(1);
      expect(history.saved, [url]);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('after a switch to the phone arrangement Proceed still saves the URL', (tester) async {
    final handle = tester.ensureSemantics();
    final cubit = login();
    final history = _RecordedHistory();
    final screen = LoginHarness.wrapCubit(cubit, const LoginCoreUrlAssignScreen(), history: history);

    watchPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, screen);
    handsetPresets.first.apply(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget, reason: 'the phone arrangement is on');

    await tapViaSemantics(tester, find.bySemanticsIdentifier(coreUrlButtonId));

    expect(history.saved, [url], reason: 'the URL comes back from the cubit and goes to history');
    handle.dispose();
  });

  for (final preset in watchPresets) {
    testWidgets('on $preset the swipe back waits while the URL is checked', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(
        tester,
        LoginHarness.wrapCubit(login(processing: true), const LoginCoreUrlAssignScreen()),
      );

      final pop = tester.widget<PopScope>(
        find.ancestor(of: find.byType(WatchActionLayout), matching: find.byWidgetPredicate((w) => w is PopScope)),
      );
      expect(pop.canPop, isFalse);
    });

    testWidgets('on $preset no history list drops over the face', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, LoginHarness.wrapCubit(login(), const LoginCoreUrlAssignScreen()));

      expect(tester.widget<HistoryAutocompleteField>(find.byType(HistoryAutocompleteField)).suggestHistory, isFalse);
    });
  }
}
