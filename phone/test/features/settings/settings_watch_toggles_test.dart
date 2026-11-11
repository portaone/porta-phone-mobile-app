import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/settings/features/media_settings/media_settings.dart';
import 'package:webtrit_phone/features/settings/features/network/bloc/network_cubit.dart';
import 'package:webtrit_phone/features/settings/features/network/models/models.dart';
import 'package:webtrit_phone/features/settings/features/network/network.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockNetworkCubit extends MockCubit<NetworkState> implements NetworkCubit {}

class _MockMediaSettingsCubit extends MockCubit<MediaSettingsState> implements MediaSettingsCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

class _MockRootStackRouter extends Mock implements RootStackRouter {}

MediaSettingsState _media({EncodingPreset? preset, bool speakerConfigurable = true}) => MediaSettingsState(
  encodingSettings: EncodingSettings.blank(),
  encodingPreset: preset,
  audioProcessingSettings: AudioProcessingSettings.blank(),
  videoCapturingSettings: VideoCapturingSettings.blank(),
  iceSettings: IceSettings.blank(),
  pearConnectionSettings: PeerConnectionSettings.blank(),
  certificateVerificationConfigurable: false,
  speakerOnMinimize: false,
  speakerOnMinimizeConfigurable: speakerConfigurable,
);

void main() {
  late _MockNetworkCubit network;
  late _MockMediaSettingsCubit media;
  late _MockStackRouter router;
  late _MockRootStackRouter root;

  final push = IncomingCallTypeModel(IncomingCallType.pushNotification, true);
  final socket = IncomingCallTypeModel(IncomingCallType.socket, false);

  setUpAll(() {
    registerFallbackValue(push);
    registerFallbackValue(WatchTextScreenPageRoute(text: ''));
  });

  setUp(() {
    network = _MockNetworkCubit();
    media = _MockMediaSettingsCubit();
    router = _MockStackRouter();
    root = _MockRootStackRouter();
    when(() => network.state).thenReturn(NetworkState(incomingCallTypeModels: [push, socket]));
    when(() => network.smsFallbackAvailable).thenReturn(false);
    when(() => network.selectIncomingCallType(any())).thenAnswer((_) async {});
    when(() => media.state).thenReturn(_media());
    when(() => router.root).thenReturn(root);
    when(() => root.navigate(any())).thenAnswer((_) async => null);
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(false);
  });

  Widget app(Widget screen) => MaterialApp(
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider<NetworkCubit>.value(value: network),
            BlocProvider<MediaSettingsCubit>.value(value: media),
          ],
          child: screen,
        ),
      ),
    ),
  );

  Finder list() => find.byType(Scrollable).last;

  group('Network settings', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the two ways as a choice under their label; no app bar', (tester) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, app(const NetworkScreen())), isEmpty);

        expect(find.byType(AppBar), findsNothing);
        expect(find.text('INCOMING CALL DELIVERY'), findsOneWidget);
        expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Push Notification')).selected, isTrue);
      });
    }

    testWidgets('a tap chooses the way and the page stays', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.last.apply(tester);
      await tester.pumpWidget(app(const NetworkScreen()));

      await tapViaSemantics(
        tester,
        find.bySemanticsIdentifier(settingsOptionId(settingsIncomingCallTypeOptionIdPrefix, 'socket')),
      );
      await tester.pumpAndSettle();

      verify(() => network.selectIncomingCallType(socket)).called(1);
      expect(find.byType(NetworkScreen), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a tap on the way in force applies nothing again', (tester) async {
      watchPresets.last.apply(tester);
      await tester.pumpWidget(app(const NetworkScreen()));

      await tester.tap(find.text('Push Notification'));
      await tester.pumpAndSettle();

      verifyNever(() => network.selectIncomingCallType(any()));
      expect(find.byType(NetworkScreen), findsOneWidget);
    });

    testWidgets('How they differ opens both explanations on the text page', (tester) async {
      watchPresets.last.apply(tester);
      await tester.pumpWidget(app(const NetworkScreen()));
      await tester.scrollUntilVisible(find.text('How they differ'), 60, scrollable: list());

      await tester.tap(find.text('How they differ'));
      final route = verify(() => root.navigate(captureAny())).captured.single as WatchTextScreenPageRoute;
      expect(route.args!.text, startsWith('Push Notification\n\n'));
      expect(route.args!.text, contains('Persistent Connection to the Server\n\n'));
    });

    testWidgets('the SMS backup is a toggle pill, offering nothing where the brand does not offer it', (tester) async {
      watchPresets.last.apply(tester);
      await tester.pumpWidget(app(const NetworkScreen()));
      await tester.scrollUntilVisible(find.text('SMS as a backup channel'), 60, scrollable: list());

      expect(tester.widget<WatchToggleChip>(find.byType(WatchToggleChip)).onChanged, isNull);
    });
  });

  group('Media settings', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the presets as a choice, Recommended in force; no Custom while it is not', (
        tester,
      ) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, app(const MediaSettingsScreen())), isEmpty);

        expect(find.byType(AppBar), findsNothing);
        expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Recommended')).selected, isTrue);
        expect(find.text('Custom', skipOffstage: false), findsNothing);
      });
    }

    testWidgets('Custom set on the phone shows in force; a tap on another preset sets it and the page stays', (
      tester,
    ) async {
      watchPresets.last.apply(tester);
      when(() => media.state).thenReturn(_media(preset: EncodingPreset.custom));
      await tester.pumpWidget(app(const MediaSettingsScreen()));

      await tester.scrollUntilVisible(find.text('Custom'), 60, scrollable: list());
      expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Custom')).selected, isTrue);
      await tester.scrollUntilVisible(find.text('Recommended'), -60, scrollable: list());
      await tester.ensureVisible(find.text('Recommended'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();

      verify(() => media.setEncodingPreset(null)).called(1);
      expect(find.byType(MediaSettingsScreen), findsOneWidget);
    });

    testWidgets('the speaker toggle and Reset to default act; a line names what stays on the phone', (tester) async {
      watchPresets.last.apply(tester);
      await tester.pumpWidget(app(const MediaSettingsScreen()));

      await tester.scrollUntilVisible(find.byType(WatchToggleChip), 60, scrollable: list());
      await tester.ensureVisible(find.byType(WatchToggleChip));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WatchToggleChip));
      verify(() => media.setSpeakerOnMinimize(true)).called(1);

      await tester.scrollUntilVisible(find.text('Reset to default'), 60, scrollable: list());
      await tester.ensureVisible(find.text('Reset to default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset to default'));
      await tester.pumpAndSettle();
      // Asked first: the reset clears what only the phone shows.
      verifyNever(() => media.reset());
      expect(find.byType(WatchConfirm), findsOneWidget);
      await tester.tap(find.byKey(confirmDialogYesButtonKey));
      await tester.pumpAndSettle();
      verify(() => media.reset()).called(1);

      await tester.scrollUntilVisible(find.textContaining('on the phone'), 60, scrollable: list());
    });

    testWidgets('no speaker toggle where the deployment does not offer it', (tester) async {
      watchPresets.last.apply(tester);
      when(() => media.state).thenReturn(_media(speakerConfigurable: false));
      await tester.pumpWidget(app(const MediaSettingsScreen()));

      expect(find.byType(WatchToggleChip, skipOffstage: false), findsNothing);
    });
  });

  testWidgets('an acknowledgement on a watch: its title and text on the face, OK on the edge', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(const Scaffold(body: Text('Settings list'))));
    final context = tester.element(find.text('Settings list'));
    var closed = false;
    AcknowledgeDialog.show(
      context,
      title: 'Important Reminder',
      content: 'Launch the app after a restart.',
    ).then((_) => closed = true);
    await tester.pumpAndSettle();

    expect(find.byType(WatchActionLayout), findsOneWidget);
    expect(find.text('Important Reminder'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(acknowledgeDialogOkButtonId));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    handle.dispose();
  });
}
