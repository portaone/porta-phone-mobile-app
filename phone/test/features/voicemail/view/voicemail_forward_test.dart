import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockVoicemailSessionCubit extends MockCubit<VoicemailSessionState> implements VoicemailSessionCubit {}

class _MockRepository extends Mock implements VoicemailRepository {}

class _MockFeatureAccess extends Mock implements FeatureAccess {}

class _MockBottomMenuConfig extends Mock implements BottomMenuConfig {}

class _MockRouter extends Mock implements StackRouter {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _AnyRoute extends PageRouteInfo<void> {
  const _AnyRoute() : super('AnyRoute');
}

final _colleague = Contact(
  id: 1,
  sourceType: ContactSourceType.external,
  kind: ContactKind.visible,
  sourceId: 'user-7',
  isCurrentUser: false,
  aliasName: 'Iryna Shevchuk',
);

Voicemail _voicemail(String id) => Voicemail(
  id: id,
  date: '2026-09-16 10:00:00',
  duration: 10.0,
  sender: '555001',
  displaySender: 'User 555001',
  receiver: '555002',
  status: ReadStatus.read,
  size: 1024,
  type: 'voicemail',
  url: 'https://example.test/$id.mp3',
);

// Forwarding has no picker of its own any more, and no state of its own
// either. The screen's whole job is to leave a request for somebody to be
// chosen and send the person to the address book; who may be chosen there, and
// what happens when they are, belongs to the purpose and is tested with it.
void main() {
  late _MockVoicemailCubit cubit;
  late _MockVoicemailSessionCubit session;
  late DestinationPickingCubit picking;
  late _MockRepository repository;
  late _MockFeatureAccess featureAccess;
  late _MockRouter router;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
    registerFallbackValue(_voicemail('fallback'));
    registerFallbackValue(_colleague);
    registerFallbackValue(const _AnyRoute());
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
    session = _MockVoicemailSessionCubit();
    picking = DestinationPickingCubit();
    repository = _MockRepository();
    featureAccess = _MockFeatureAccess();
    router = _MockRouter();
    player = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast(sync: true);

    when(() => player.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => player.playing).thenReturn(false);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => player.duration).thenReturn(const Duration(seconds: 10));
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => router.navigate(any())).thenAnswer((_) async {});

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  void addressBookIsConfigured({required bool configured}) {
    final menu = _MockBottomMenuConfig();
    when(menu.getTabEnabled<ContactsBottomMenuTab>).thenReturn(
      configured
          ? ContactsBottomMenuTab(
              enabled: true,
              initial: false,
              titleL10n: 'main_BottomNavigationBarItemLabel_contacts',
              icon: Icons.contacts,
              contactSourceTypes: const [ContactSourceType.external],
              layout: const ContactsTabbedLayout(),
            )
          : null,
    );
    when(() => featureAccess.bottomMenuConfig).thenReturn(menu);
  }

  /// What the session knows of the mailbox, which the screen reads beside its
  /// own state.
  void mailboxHolds(List<Voicemail> items, {VoicemailForward? forward}) => whenListen(
    session,
    const Stream<VoicemailSessionState>.empty(),
    initialState: VoicemailSessionState(
      status: VoicemailStatus.loaded,
      items: items,
      forwards: {for (final item in items) item.id: ?forward},
    ),
  );

  VoicemailState loaded({VoicemailForward? forward}) {
    mailboxHolds([_voicemail('vm-1')], forward: forward);
    return const VoicemailState(filters: VoicemailFilter.values, forwardSupported: true);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              BlocProvider<VoicemailCubit>.value(value: cubit),
              BlocProvider<VoicemailSessionCubit>.value(value: session),
              BlocProvider<DestinationPickingCubit>.value(value: picking),
              RepositoryProvider<VoicemailRepository>.value(value: repository),
              Provider<FeatureAccess>.value(value: featureAccess),
              Provider<AppCacheManager>(create: (_) => AppCacheManager(sections: const [])),
              Provider<VoicemailScreenContext>(
                create: (_) => VoicemailScreenContext(
                  mediaCacheBasePath: '/tmp/vm-cache',
                  dateFormat: DateFormat('yyyy-MM-dd HH:mm'),
                  mediaHeaders: const {},
                ),
              ),
              ChangeNotifierProvider<VoicemailPlaybackController>.value(value: controller),
            ],
            child: const PresenceViewParams(
              hybridPresenceSupport: false,
              blfViaSipSupport: false,
              presenceViaSipSupport: false,
              child: VoicemailScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> chooseForward(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forward'));
    await tester.pumpAndSettle();
  }

  testWidgets('forwarding remembers the message and sends the person to the address book', (tester) async {
    addressBookIsConfigured(configured: true);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await pump(tester);
    await chooseForward(tester);

    final purpose = picking.state.purpose as ForwardVoicemailPurpose;
    expect(purpose.messageId, 'vm-1');
    verify(() => router.navigate(any())).called(1);
  });

  testWidgets('the request names this screen as the one to come back to', (tester) async {
    // Reached from settings, this page is gone by the time a colleague is
    // chosen. The way back is through the settings list it was opened from, so
    // closing the page afterwards lands where it did before the forward.
    addressBookIsConfigured(configured: true);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await pump(tester);
    await chooseForward(tester);

    final origin = (picking.state.purpose as ForwardVoicemailPurpose).origin;
    expect(origin.routeName, SettingsRouterPageRoute.name);
    expect(origin.initialChildren?.map((it) => it.routeName), [
      SettingsScreenPageRoute.name,
      VoicemailScreenPageRoute.name,
    ]);
  });

  testWidgets('a message on its way to a colleague shows that in place of its menu', (tester) async {
    addressBookIsConfigured(configured: true);
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: loaded(forward: const VoicemailForwardSending()),
    );

    await pump(tester);

    expect(find.byKey(voicemailForwardingKey), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  group('a forward that did not go through', () {
    VoicemailForwardFailed failed(VoicemailForwardOutcome outcome) =>
        VoicemailForwardFailed(outcome: outcome, recipient: _colleague);

    testWidgets('is marked on the message, which keeps its menu', (tester) async {
      addressBookIsConfigured(configured: true);
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(forward: failed(VoicemailForwardOutcome.failed)),
      );

      await pump(tester);

      expect(find.text('Not forwarded · Iryna Shevchuk'), findsOneWidget);
      expect(find.byKey(voicemailForwardFailedBadgeKey), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('is forwarded again from the menu to the same colleague, without choosing again', (tester) async {
      addressBookIsConfigured(configured: true);
      when(() => session.forward(any(), any())).thenAnswer((_) async => VoicemailForwardOutcome.sent);
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(forward: failed(VoicemailForwardOutcome.failed)),
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forward again'));
      await tester.pumpAndSettle();

      final sent = verify(() => session.forward(captureAny(), captureAny())).captured;
      expect((sent[0] as Voicemail).id, 'vm-1');
      expect(sent[1], _colleague);
      // Nobody is sent to the address book for it, and it is said when it lands.
      verifyNever(() => router.navigate(any()));
      expect(picking.state.report?.message, 'Forwarded to Iryna Shevchuk');
    });

    testWidgets('is not marked on a message in the trash, which could do nothing about it', (tester) async {
      addressBookIsConfigured(configured: true);
      final message = _voicemail('vm-1');
      whenListen(
        session,
        const Stream<VoicemailSessionState>.empty(),
        initialState: VoicemailSessionState(
          status: VoicemailStatus.loaded,
          forwards: {'vm-1': failed(VoicemailForwardOutcome.failed)},
        ),
      );
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: VoicemailState(
          filters: VoicemailFilter.values,
          filter: VoicemailFilter.trash,
          trashedItems: [message],
        ),
      );

      await pump(tester);

      expect(find.byKey(voicemailForwardFailedBadgeKey), findsNothing);
      expect(find.textContaining('Not forwarded'), findsNothing);
    });
  });

  testWidgets('a menu with no address book in it forwards nothing', (tester) async {
    // Without somewhere to choose from there is nothing to send the person to,
    // and a message left waiting would sit there with no way to finish it.
    addressBookIsConfigured(configured: false);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await pump(tester);
    await chooseForward(tester);

    expect(picking.state.purpose, isNull);
    verifyNever(() => router.navigate(any()));
  });
}
