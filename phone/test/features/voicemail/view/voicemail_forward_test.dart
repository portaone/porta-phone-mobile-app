import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockForwardingCubit extends MockCubit<VoicemailForwardingState> implements VoicemailForwardingCubit {}

class _MockFeatureAccess extends Mock implements FeatureAccess {}

class _MockBottomMenuConfig extends Mock implements BottomMenuConfig {}

class _MockRouter extends Mock implements StackRouter {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _AnyRoute extends PageRouteInfo<void> {
  const _AnyRoute() : super('AnyRoute');
}

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

// Forwarding has no picker of its own any more. The screen's whole job is to
// remember which message is being passed on and send the person to the address
// book; who may be chosen there, and what happens when they are, belongs to the
// purpose and is tested with it.
void main() {
  late _MockVoicemailCubit cubit;
  late _MockForwardingCubit forwarding;
  late _MockFeatureAccess featureAccess;
  late _MockRouter router;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
    registerFallbackValue(_voicemail('fallback'));
    registerFallbackValue(const _AnyRoute());
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
    forwarding = _MockForwardingCubit();
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
    when(() => forwarding.start(any())).thenReturn(null);
    when(() => router.navigate(any())).thenAnswer((_) async {});
    whenListen(
      forwarding,
      const Stream<VoicemailForwardingState>.empty(),
      initialState: const VoicemailForwardingState(),
    );

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

  VoicemailState loaded() => VoicemailState(
    status: VoicemailStatus.loaded,
    items: [_voicemail('vm-1')],
    filters: VoicemailFilter.values,
    forwardSupported: true,
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              BlocProvider<VoicemailCubit>.value(value: cubit),
              BlocProvider<VoicemailForwardingCubit>.value(value: forwarding),
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

    final started = verify(() => forwarding.start(captureAny())).captured.single as Voicemail;
    expect(started.id, 'vm-1');
    verify(() => router.navigate(any())).called(1);
  });

  testWidgets('a menu with no address book in it forwards nothing', (tester) async {
    // Without somewhere to choose from there is nothing to send the person to,
    // and a message left waiting would sit there with no way to finish it.
    addressBookIsConfigured(configured: false);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await pump(tester);
    await chooseForward(tester);

    verifyNever(() => forwarding.start(any()));
    verifyNever(() => router.navigate(any()));
  });
}
