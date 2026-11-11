import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/blocs/app/app_bloc.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/version_gate/version_gate.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockAppInfo extends Mock implements AppInfo {}

class _FakePackageInfo implements PackageInfo {
  _FakePackageInfo(this.version, [this.buildNumber = '0']);

  @override
  final String version;

  @override
  final String buildNumber;

  @override
  String get appName => 'PortaPhone';

  @override
  String get packageName => 'com.webtrit.phone';
}

AppState _appState(AppCompatibility compatibility) => AppState(
  themeMode: ThemeMode.system,
  locale: const Locale('en'),
  userAgreementStatus: AgreementStatus.accepted,
  contactsAgreementStatus: AgreementStatus.accepted,
  appCompatibility: compatibility,
);

void main() {
  late _MockAppBloc appBloc;
  late _MockAppInfo appInfo;

  setUpAll(() => registerFallbackValue(const AppLogoutRequested(reason: AppLogoutReason.userRequest)));

  setUp(() {
    appBloc = _MockAppBloc();
    appInfo = _MockAppInfo();
  });

  Widget host(AppCompatibility compatibility, Widget page) {
    when(() => appBloc.state).thenReturn(_appState(compatibility));
    when(() => appInfo.version).thenReturn(Version(1, 14, 0));
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          Provider<AppInfo>.value(value: appInfo),
          Provider<PackageInfo>.value(value: _FakePackageInfo('4.4.9', '7')),
          BlocProvider<AppBloc>.value(value: appBloc),
        ],
        child: page,
      ),
    );
  }

  Widget updateRequired() => host(
    AppVersionTooOld(appVersion: Version(1, 14, 0), minSupportedVersion: Version(1, 15, 0)),
    const UpdateRequiredScreenPage(),
  );

  Widget compatibilityIssue() => host(
    CoreVersionUnsupported(coreVersion: Version(3, 0, 0), constraint: VersionConstraint.parse('>=2.0.0 <3.0.0')),
    const CompatibilityIssueScreenPage(),
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset Update required: why, the versions as rows, Log out as a row', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, updateRequired()), isEmpty);

      expect(find.text('Update required'), findsOneWidget);
      final list = find.byType(Scrollable).last;
      for (final value in ['1.14.0', '1.15.0', 'Logout']) {
        await tester.scrollUntilVisible(find.text(value), 40, scrollable: list);
      }
    });

    testWidgets('on $preset Compatibility issue: the phone\'s text, Log out on the edge', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, compatibilityIssue()), isEmpty);

      expect(find.text('Compatibility issue'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.descendant(of: find.byType(WatchEdgeButton), matching: find.text('Logout')), findsOneWidget);
    });
  }

  testWidgets('Log out on the compatibility gate logs out', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(compatibilityIssue());
    await tester.pump();
    await tapViaSemantics(tester, find.bySemanticsLabel('Logout'));
    verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.userRequest))).called(1);
    handle.dispose();
  });

  testWidgets('Log out on the update gate logs out', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(updateRequired());
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Logout'), 40, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Logout'));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsLabel('Logout'));
    verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.userRequest))).called(1);
    handle.dispose();
  });

  for (final (name, gate) in [('update', updateRequired), ('compatibility', compatibilityIssue)]) {
    testWidgets('Back does not leave the $name gate', (tester) async {
      watchPresets.first.apply(tester);
      await tester.pumpWidget(gate());
      await tester.pump();

      final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
      expect(popScope.canPop, isFalse);
    });
  }
}
