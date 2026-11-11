import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/settings/features/caller_id/caller_id.dart';
import 'package:webtrit_phone/features/settings/features/language/language.dart';
import 'package:webtrit_phone/features/settings/features/presence/presence.dart';
import 'package:webtrit_phone/features/settings/features/theme_mode/theme_mode.dart';
import 'package:webtrit_phone/features/settings/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'features/presence/presence_settings_harness.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockCallerIdSettingsCubit extends MockCubit<CallerIdSettingsState?> implements CallerIdSettingsCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockAppBloc appBloc;
  late _MockCallerIdSettingsCubit callerId;

  setUpAll(() {
    registerFallbackValue(const AppLocaleChanged(Locale('en')));
  });

  setUp(() {
    appBloc = _MockAppBloc();
    callerId = _MockCallerIdSettingsCubit();
    when(() => appBloc.state).thenReturn(
      const AppState(
        themeMode: ThemeMode.light,
        locale: Locale('en'),
        userAgreementStatus: AgreementStatus.accepted,
        contactsAgreementStatus: AgreementStatus.accepted,
      ),
    );
    when(() => callerId.state).thenReturn(
      CallerIdSettingsState(
        settings: CallerIdSettings(matchers: const []),
        mainNumber: '555007',
        additionalNumbers: const ['+12025550143'],
      ),
    );
  });

  /// The page opened over a list the way Settings opens it, so going back
  /// can be seen.
  Future<void> open(WidgetTester tester, Widget page, {ThemeSettings themeSettings = const ThemeSettings()}) async {
    final router = _MockStackRouter();
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(true);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: MultiProvider(
              providers: [
                BlocProvider<AppBloc>.value(value: appBloc),
                BlocProvider<CallerIdSettingsCubit>.value(value: callerId),
                Provider<ThemeSettings>.value(value: themeSettings),
              ],
              child: child!,
            ),
          ),
        ),
        home: const Scaffold(body: Text('Settings list')),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => page)));
    // Not settled: a page on its way spins for as long as it waits.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('SettingsWatchChoicePage', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the current option is tinted with a tick; a tap chooses it and goes back', (
        tester,
      ) async {
        preset.apply(tester);
        String? chosen;
        await open(
          tester,
          SettingsWatchChoicePage<String>(
            title: 'Theme mode',
            options: const [
              SettingsWatchOption(value: 'system', label: 'System'),
              SettingsWatchOption(value: 'light', label: 'Light'),
              SettingsWatchOption(value: 'dark', label: 'Dark'),
            ],
            selected: 'light',
            onChosen: (value) => chosen = value,
          ),
        );
        expect(tester.takeException(), isNull);

        final light = tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Light'));
        expect(light.selected, isTrue);
        expect(light.trailing, isNotNull);
        expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Dark')).selected, isFalse);

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(chosen, 'dark');
        expect(find.text('Settings list'), findsOneWidget);
        expect(find.text('Theme mode'), findsNothing);
      });
    }

    testWidgets('a tap on the option in force applies nothing again and goes back', (tester) async {
      watchPresets.first.apply(tester);
      var chosen = 0;
      await open(
        tester,
        SettingsWatchChoicePage<int>(
          title: 'Theme mode',
          options: const [
            SettingsWatchOption(value: 1, label: 'Light'),
            SettingsWatchOption(value: 2, label: 'Dark'),
          ],
          selected: 1,
          onChosen: (_) => chosen++,
        ),
      );

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(chosen, 0);
      expect(find.text('Settings list'), findsOneWidget);
    });

    testWidgets('disabled, the rows offer nothing and the page stays', (tester) async {
      watchPresets.first.apply(tester);
      var chosen = 0;
      await open(
        tester,
        SettingsWatchChoicePage<int>(
          title: 'Theme mode',
          options: const [SettingsWatchOption(value: 1, label: 'Light')],
          selected: 1,
          enabled: false,
          onChosen: (_) => chosen++,
        ),
      );

      await tester.tap(find.text('Light'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(chosen, 0);
      expect(find.text('Theme mode'), findsOneWidget);
    });
  });

  testWidgets('Language: Default first, then the languages; a tap changes the app language and goes back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await open(tester, const LanguageScreen());

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Default'), findsOneWidget);
    expect(find.bySemanticsIdentifier(settingsOptionId(settingsLanguageOptionIdPrefix, 'system')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ukrainian'), 60, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Ukrainian'));
    await tester.pumpAndSettle();

    verify(() => appBloc.add(const AppLocaleChanged(Locale('uk')))).called(1);
    expect(find.text('Settings list'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Theme mode where the brand fixes it: the rows dimmed, offering nothing', (tester) async {
    watchPresets.first.apply(tester);
    await open(tester, const ThemeModeScreen());

    expect(find.text('Light'), findsOneWidget);
    expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Dark')).onTap, isNull);
  });

  testWidgets('Caller ID: the main number and the others; dial code matching is said to stay on the phone', (
    tester,
  ) async {
    watchPresets.last.apply(tester);
    when(() => callerId.setDefaultNumber(any())).thenReturn(null);
    await open(tester, const CallerIdSettingsScreen());

    expect(find.text('DEFAULT CALLER ID'), findsOneWidget);
    expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, '555007')).selected, isTrue);
    await tester.scrollUntilVisible(
      find.text('Dial code matching: on the phone'),
      60,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text('+12025550143'));
    await tester.pumpAndSettle();
    verify(() => callerId.setDefaultNumber('+12025550143')).called(1);
  });

  testWidgets('Caller ID on its way: a loading page', (tester) async {
    watchPresets.first.apply(tester);
    when(() => callerId.state).thenReturn(null);
    await open(tester, const CallerIdSettingsScreen());

    expect(find.byType(WatchSpinner), findsOneWidget);
  });

  group('SIP Presence', () {
    Future<FakePresenceSettingsRepository> openPresence(WidgetTester tester, PresenceSettings settings) async {
      final repository = FakePresenceSettingsRepository(settings);
      await open(
        tester,
        BlocProvider(create: (_) => PresenceSettingsCubit(repository), child: const PresenceSettingsScreen()),
      );
      return repository;
    }

    testWidgets('settings off the presets read Custom over the presets; a preset sets them all', (tester) async {
      watchPresets.last.apply(tester);
      final repository = await openPresence(tester, statusOffThePresets(available: false, note: 'In the lab'));

      expect(find.text('Custom'), findsOneWidget);
      // Pressed as a screen reader presses it.
      final handle = tester.ensureSemantics();
      await tester.scrollUntilVisible(find.text('Available'), 60, scrollable: find.byType(Scrollable).last);
      await tapViaSemantics(tester, find.bySemanticsLabel('Available'));
      await tester.pumpAndSettle();
      handle.dispose();

      expect(repository.presenceSettings.available, isTrue);
      expect(repository.presenceSettings.note, isEmpty);
      expect(find.text('Settings list'), findsOneWidget);
    });

    testWidgets('the preset in force is tinted; the rest of the configuration is said to stay on the phone', (
      tester,
    ) async {
      watchPresets.last.apply(tester);
      await openPresence(
        tester,
        PresenceSettings.blank(device: 'watch').copyWithAvailable(false).copyWithNote('').copyWithActivity(null),
      );

      expect(find.text('Custom'), findsNothing);
      expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Unavailable')).selected, isTrue);
      await tester.scrollUntilVisible(
        find.textContaining('on the phone'),
        60,
        scrollable: find.byType(Scrollable).last,
      );
    });
  });
}
