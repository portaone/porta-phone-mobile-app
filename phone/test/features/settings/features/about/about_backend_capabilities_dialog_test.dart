import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/settings/features/about/about.dart';
import 'package:webtrit_phone/features/settings/features/about/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';

import '../../../../helpers/feature_access_factories.dart';
import '../../../../helpers/semantics.dart';

class _MockAboutBloc extends MockBloc<AboutEvent, AboutState> implements AboutBloc {}

class _MockSystemInfoRepository extends Mock implements SystemInfoRepository {}

const _removed = 'Turned off on the server - still in use until the app is started again';
const _added = 'Turned on on the server - not in use until the app is started again';

void main() {
  setUpAll(() => registerFallbackValue(FetchPolicy.cacheOnly));

  late _MockAboutBloc bloc;
  late _MockSystemInfoRepository systemInfoRepository;

  setUp(() {
    bloc = _MockAboutBloc();
    systemInfoRepository = _MockSystemInfoRepository();
    when(() => bloc.state).thenReturn(
      AboutState(
        embeddedResources: const [],
        packageName: 'com.webtrit.phone',
        appIdentifier: 'app-identifier',
        coreUrl: Uri.parse('https://core.webtrit.com'),
        userAgent: 'user-agent',
        appInfo: 'app-info',
        deviceInfo: 'device-info',
        callkeepVersion: '1.3.3',
      ),
    );
  });

  /// The About screen of a session started with [session], while the stored
  /// answer of the backend names [server] (null: nothing stored).
  Future<void> openDialog(WidgetTester tester, {required List<String> session, required List<String>? server}) async {
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: any(named: 'fetchPolicy')))
        .thenAnswer((_) async => server == null ? null : systemInfoWithSupported(server));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FeatureAccess>.value(value: featureAccessFor(systemInfoWithSupported(session))),
          Provider<SystemInfoRepository>.value(value: systemInfoRepository),
        ],
        child: ThemeProvider(
          settings: const ThemeSettings(),
          lightDynamic: null,
          darkDynamic: null,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<AboutBloc>.value(value: bloc, child: const AboutScreen()),
          ),
        ),
      ),
    );
    await tapViaSemantics(tester, find.bySemanticsIdentifier(aboutBackendCapabilitiesButtonId));
    await tester.pumpAndSettle();
  }

  group('BackendCapability.compare', () {
    test('lists every name either side knows, by name', () {
      final rows = BackendCapability.compare(session: {'voicemail', 'callHistory'}, server: {'voicemail', 'sms'});

      expect(rows.map((row) => row.name), ['callHistory', 'sms', 'voicemail']);
      expect(rows.map((row) => row.inSession), [true, false, true]);
      expect(rows.map((row) => row.onServer), [false, true, true]);
    });

    test('with nothing stored from the backend the session speaks for both', () {
      final rows = BackendCapability.compare(session: {'voicemail'}, server: null);

      expect(rows.single.inSession, isTrue);
      expect(rows.single.onServer, isTrue);
    });
  });

  testWidgets('the button is reachable by its identifier and names itself', (tester) async {
    final semantics = tester.ensureSemantics();
    await openDialog(tester, session: const ['voicemail'], server: const ['voicemail']);
    Navigator.of(tester.element(find.byType(BackendCapabilitiesDialog))).pop();
    await tester.pumpAndSettle();

    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(aboutBackendCapabilitiesButtonId),
      identifier: aboutBackendCapabilitiesButtonId,
      label: 'Backend capabilities',
    );
    semantics.dispose();
  });

  testWidgets('lists what the session was started with', (tester) async {
    await openDialog(
      tester,
      session: const ['voicemail', 'voicemailForward'],
      server: const ['voicemail', 'voicemailForward'],
    );

    expect(find.text('voicemail'), findsOneWidget);
    expect(find.text('voicemailForward'), findsOneWidget);
    expect(find.text(_removed), findsNothing);
    expect(find.text(_added), findsNothing);
  });

  // WT-2067: the capability is off on the server and the app still offers the
  // feature - the session keeps what it was started with.
  testWidgets('a capability the server turned off is still listed, and says so', (tester) async {
    await openDialog(tester, session: const ['voicemail', 'voicemailForward'], server: const ['voicemail']);

    expect(find.text('voicemailForward'), findsOneWidget);
    expect(find.text(_removed), findsOneWidget);
    expect(find.text(_added), findsNothing);
  });

  testWidgets('a capability the server turned on is listed as not in use yet', (tester) async {
    await openDialog(tester, session: const ['voicemail'], server: const ['voicemail', 'voicemailForward']);

    expect(find.text('voicemailForward'), findsOneWidget);
    expect(find.text(_added), findsOneWidget);
    expect(find.text(_removed), findsNothing);
  });

  testWidgets('each capability is one node: its name with what differs', (tester) async {
    final semantics = tester.ensureSemantics();
    await openDialog(tester, session: const ['voicemailForward'], server: const []);

    expect(find.bySemanticsLabel('voicemailForward\n$_removed'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('with nothing stored from the backend the session list is shown as it is', (tester) async {
    await openDialog(tester, session: const ['voicemail'], server: null);

    expect(find.text('voicemail'), findsOneWidget);
    expect(find.text(_removed), findsNothing);
  });

  testWidgets('an empty list says so', (tester) async {
    await openDialog(tester, session: const [], server: const []);

    expect(find.text('The backend names no capabilities.'), findsOneWidget);
  });

  testWidgets('the dialog meets the tap target guideline', (tester) async {
    final semantics = tester.ensureSemantics();
    await openDialog(tester, session: const ['voicemail'], server: const ['voicemail']);

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
