import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/about/about.dart';
import 'package:webtrit_phone/features/terms_conditions/terms_conditions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockAboutBloc extends MockBloc<AboutEvent, AboutState> implements AboutBloc {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockAboutBloc bloc;

  AboutState state({bool progress = false, String? bundle = '7', bool core = true}) => AboutState(
    progress: progress,
    packageName: 'com.webtrit.phone',
    appIdentifier: 'a8f3-21c9',
    coreUrl: Uri.parse('https://core.example.test'),
    userAgent: 'agent',
    appInfo: 'PortaPhone/1.4.0(1.4.0+412)',
    deviceInfo: 'Pixel Watch 3; OS: 16',
    fcmPushToken: 'fZ2kQm9xT0a',
    coreVersion: core ? Version(1, 9, 2) : null,
    bundleVersion: bundle,
  );

  setUp(() => bloc = _MockAboutBloc());

  Widget app(Widget home) {
    final router = _MockStackRouter();
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(false);
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
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
            child: BlocProvider<AboutBloc>.value(value: bloc, child: home),
          ),
        ),
      ),
    );
  }

  group('About', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the app and the device under the title, the values as rows; no app bar', (tester) async {
        preset.apply(tester);
        when(() => bloc.state).thenReturn(state());
        expect(await pumpCollectingOverflows(tester, app(const AboutScreen())), isEmpty);

        expect(find.byType(AppBar), findsNothing);
        expect(find.text('PortaPhone/1.4.0(1.4.0+412)'), findsOneWidget);
        expect(find.text('Third-party licenses', skipOffstage: false), findsNothing);
      });
    }

    testWidgets('the Core address and the session id carry the phone\'s ids; the version and bundle are rows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      watchPresets.last.apply(tester);
      when(() => bloc.state).thenReturn(state());
      await tester.pumpWidget(app(const AboutScreen()));

      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(find.bySemanticsIdentifier(aboutCoreUrlId), 40, scrollable: list);
      expect(find.text('https://core.example.test'), findsOneWidget);
      // A node of its own: the address alone, as on the phone.
      expect(find.semantics.byLabel('https://core.example.test').evaluate().single.identifier, aboutCoreUrlId);
      await tester.scrollUntilVisible(find.text('1.9.2'), 40, scrollable: list);
      await tester.scrollUntilVisible(find.bySemanticsIdentifier(aboutAppSessionIdentifierId), 40, scrollable: list);
      expect(find.semantics.byLabel('a8f3-21c9').evaluate().single.identifier, aboutAppSessionIdentifierId);
      await tester.scrollUntilVisible(find.text('Bundle version'), 40, scrollable: list);
      handle.dispose();
    });

    testWidgets('a Core that could not be asked reads ?.?.?, as on the phone; no bundle, no row', (tester) async {
      watchPresets.last.apply(tester);
      when(() => bloc.state).thenReturn(state(core: false, bundle: null));
      await tester.pumpWidget(app(const AboutScreen()));

      await tester.scrollUntilVisible(find.text('?.?.?'), 40, scrollable: find.byType(Scrollable).last);
      expect(find.text('Bundle version', skipOffstage: false), findsNothing);
    });
  });

  group('WatchOpenOnPhonePage', () {
    Future<void> open(WidgetTester tester, WatchPhoneOpener opener) async {
      watchPresets.first.apply(tester);
      await tester.pumpWidget(app(const Scaffold(body: Text('Settings list'))));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WatchOpenOnPhonePage(
              title: 'Terms and conditions',
              uri: Uri.parse('https://example.test/terms'),
              opener: opener,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the page says it opens on the phone; sent, it says where to look and goes back', (tester) async {
      final handle = tester.ensureSemantics();
      Uri? sent;
      await open(tester, (uri) async {
        sent = uri;
        return true;
      });

      expect(find.text('Opens on your phone'), findsOneWidget);
      await tapViaSemantics(tester, find.bySemanticsIdentifier(watchOpenOnPhoneId));
      await tester.pump();
      expect(sent, Uri.parse('https://example.test/terms'));
      expect(find.text('Check your phone'), findsOneWidget);

      await tester.pump(WatchOpenOnPhonePage.sentFor);
      await tester.pumpAndSettle();
      expect(find.text('Settings list'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a page opened over it in the meantime stays: only this page goes back, once it is on top', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, (_) async => true);
      await tapViaSemantics(tester, find.bySemanticsIdentifier(watchOpenOnPhoneId));
      await tester.pump();
      expect(find.text('Check your phone'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('A call')))));
      await tester.pumpAndSettle();
      await tester.pump(WatchOpenOnPhonePage.sentFor);
      await tester.pumpAndSettle();
      expect(find.text('A call'), findsOneWidget);

      navigator.pop();
      await tester.pumpAndSettle();
      // Back on it, the page offers to send again rather than saying to look.
      expect(find.bySemanticsIdentifier(watchOpenOnPhoneId), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no phone to take it: it says so, and Try again sends it again', (tester) async {
      final handle = tester.ensureSemantics();
      var tries = 0;
      await open(tester, (_) async => ++tries > 1);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(watchOpenOnPhoneId));
      await tester.pumpAndSettle();
      expect(find.text('No phone connected'), findsOneWidget);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(watchOpenOnPhoneRetryId));
      await tester.pump();
      expect(tries, 2);
      expect(find.text('Check your phone'), findsOneWidget);
      await tester.pump(WatchOpenOnPhonePage.sentFor);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('a phone that never answers counts as none: Try again is offered', (tester) async {
      await open(tester, (_) => Completer<bool>().future);

      await tester.tap(find.text('Open on phone'));
      await tester.pump();
      await tester.pump(WatchOpenOnPhonePage.answerWithin);
      await tester.pumpAndSettle();
      expect(find.text('No phone connected'), findsOneWidget);
    });

    testWidgets('a phone that answers late has still opened it: the face says where to look', (tester) async {
      final answer = Completer<bool>();
      await open(tester, (_) => answer.future);

      await tester.tap(find.text('Open on phone'));
      await tester.pump();
      await tester.pump(WatchOpenOnPhonePage.answerWithin);
      await tester.pumpAndSettle();
      expect(find.text('No phone connected'), findsOneWidget);

      answer.complete(true);
      await tester.pump();
      await tester.pump();
      expect(find.text('Check your phone'), findsOneWidget);
      await tester.pump(WatchOpenOnPhonePage.sentFor);
      await tester.pumpAndSettle();
      expect(find.text('Settings list'), findsOneWidget);
    });
  });

  testWidgets('the terms on a watch are the open-on-phone page', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      app(TermsConditionsScreen(initialUri: Uri.parse('https://example.test/terms'), userAgent: 'agent')),
    );

    final page = tester.widget<WatchOpenOnPhonePage>(find.byType(WatchOpenOnPhonePage));
    expect(page.uri, Uri.parse('https://example.test/terms?localeName=en'));
    expect(find.text('Terms and conditions'), findsOneWidget);
  });
}
