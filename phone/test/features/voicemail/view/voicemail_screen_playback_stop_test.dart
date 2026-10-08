import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_body.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_tile.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/voicemail/user_voicemail.dart';
import 'package:webtrit_phone/models/voicemail/voicemail_filter.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockVoicemailSessionCubit extends MockCubit<VoicemailSessionState> implements VoicemailSessionCubit {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _Sections extends Mock implements TabsRouter {}

class _Section extends Mock implements RouteData {}

Voicemail _voicemail(String id, {ReadStatus status = ReadStatus.read}) => Voicemail(
  id: id,
  date: '2026-07-06 10:00:00',
  duration: 10.0,
  sender: '555001',
  receiver: '555002',
  status: status,
  size: 1024,
  type: 'voicemail',
  url: 'https://example.com/vm/$id.mp3',
);

VoicemailSessionState _mailbox(List<Voicemail> items) =>
    VoicemailSessionState(status: VoicemailStatus.loaded, items: items);

void main() {
  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
  });

  late _MockVoicemailCubit cubit;
  late _MockVoicemailSessionCubit session;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUp(() {
    cubit = _MockVoicemailCubit();
    session = _MockVoicemailSessionCubit();
    player = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast(sync: true);

    when(() => player.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => player.playing).thenReturn(true);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => player.duration).thenReturn(const Duration(seconds: 10));

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  Widget host({Widget screen = const VoicemailScreen()}) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          BlocProvider<VoicemailCubit>.value(value: cubit),
          BlocProvider<VoicemailSessionCubit>.value(value: session),
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
        child: PresenceViewParams(
          hybridPresenceSupport: false,
          blfViaSipSupport: false,
          presenceViaSipSupport: false,
          child: screen,
        ),
      ),
    );
  }

  testWidgets('stops playback when the active voicemail disappears from the list', (tester) async {
    final vm1 = _voicemail('vm-1');
    final vm2 = _voicemail('vm-2');

    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: const VoicemailState());
    whenListen(
      session,
      Stream.fromIterable([
        _mailbox([vm2]),
      ]),
      initialState: _mailbox([vm1, vm2]),
    );

    await controller.play(id: 'vm-1', uri: Uri.parse(vm1.url!), isLocal: true);
    expect(controller.activeId, 'vm-1');
    clearInteractions(player);

    await tester.pumpWidget(host());
    await tester.pump();

    expect(controller.activeId, isNull);
    verify(() => player.stop()).called(1);
  });

  testWidgets('keeps playback when a different voicemail is removed', (tester) async {
    final vm1 = _voicemail('vm-1');
    final vm2 = _voicemail('vm-2');

    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: const VoicemailState());
    whenListen(
      session,
      Stream.fromIterable([
        _mailbox([vm1]),
      ]),
      initialState: _mailbox([vm1, vm2]),
    );

    await controller.play(id: 'vm-1', uri: Uri.parse(vm1.url!), isLocal: true);
    clearInteractions(player);

    await tester.pumpWidget(host());
    await tester.pump();

    expect(controller.activeId, 'vm-1');
    verifyNever(() => player.stop());
  });

  group('under the New filter', () {
    const listening = VoicemailState(filter: VoicemailFilter.unheard, heardByListening: ['vm-1']);

    testWidgets('a new message that playing marks heard stays listed and goes on playing', (tester) async {
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: listening);
      whenListen(
        session,
        Stream.fromIterable([
          _mailbox([_voicemail('vm-1'), _voicemail('vm-2', status: ReadStatus.unread)]),
        ]),
        initialState: _mailbox([
          _voicemail('vm-1', status: ReadStatus.unread),
          _voicemail('vm-2', status: ReadStatus.unread),
        ]),
      );

      await controller.play(id: 'vm-1', uri: Uri.parse('https://example.com/vm/vm-1.mp3'), isLocal: true);
      clearInteractions(player);

      await tester.pumpWidget(host());
      await tester.pump();

      expect(controller.activeId, 'vm-1');
      verifyNever(() => player.stop());
      expect(find.byType(VoicemailTile), findsNWidgets(2));
    });

    testWidgets('a message marked heard that nobody listened to takes its player with it', (tester) async {
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: const VoicemailState(filter: VoicemailFilter.unheard),
      );
      whenListen(
        session,
        Stream.fromIterable([
          _mailbox([_voicemail('vm-1')]),
        ]),
        initialState: _mailbox([_voicemail('vm-1', status: ReadStatus.unread)]),
      );

      await controller.play(id: 'vm-1', uri: Uri.parse('https://example.com/vm/vm-1.mp3'), isLocal: true);
      clearInteractions(player);

      await tester.pumpWidget(host());
      await tester.pump();

      expect(controller.activeId, isNull);
      verify(() => player.stop()).called(1);
    });

    testWidgets('playback stops when the messages heard by listening are let go of', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([const VoicemailState(filter: VoicemailFilter.unheard)]),
        initialState: listening,
      );
      whenListen(session, const Stream<VoicemailSessionState>.empty(), initialState: _mailbox([_voicemail('vm-1')]));

      await controller.play(id: 'vm-1', uri: Uri.parse('https://example.com/vm/vm-1.mp3'), isLocal: true);
      clearInteractions(player);

      await tester.pumpWidget(host());
      await tester.pump();

      // A refresh or another filter: the row is gone, and a player left
      // behind would be sound with nothing on screen to stop it.
      expect(controller.activeId, isNull);
      expect(find.byType(VoicemailTile), findsNothing);
    });
  });

  group('what New keeps for having been heard by listening is let go of', () {
    const kept = VoicemailState(filter: VoicemailFilter.unheard, heardByListening: ['vm-1']);

    late _Sections sections;
    late _Section voicemail;
    late _Section contacts;
    late List<VoidCallback> sectionListeners;

    /// The list as the bottom menu holds it: in one of the router's sections.
    /// Never torn down, so nothing but this would take those rows off again.
    Widget section() => TabsRouterScope(
      controller: sections,
      stateHash: 0,
      child: RouteDataScope(
        routeData: voicemail,
        child: const Scaffold(body: VoicemailBody(origin: VoicemailScreenPageRoute())),
      ),
    );

    void show(_Section shown) {
      when(() => sections.currentChild).thenReturn(shown);
      for (final listener in List.of(sectionListeners)) {
        listener();
      }
    }

    setUp(() {
      sections = _Sections();
      voicemail = _Section();
      contacts = _Section();
      sectionListeners = [];
      when(() => voicemail.parent).thenReturn(null);
      when(() => sections.stackData).thenReturn([voicemail, contacts]);
      when(() => sections.currentChild).thenReturn(voicemail);
      when(() => sections.addListener(any())).thenAnswer((call) {
        sectionListeners.add(call.positionalArguments.single as VoidCallback);
      });
      when(() => sections.removeListener(any())).thenAnswer((call) {
        sectionListeners.remove(call.positionalArguments.single);
      });

      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: kept);
      whenListen(session, const Stream<VoicemailSessionState>.empty(), initialState: _mailbox([_voicemail('vm-1')]));
      when(() => player.pause()).thenAnswer((_) async {});
      when(() => player.seek(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    /// The message is in the player: played to the end, or left part-way.
    Future<void> listen(WidgetTester tester, {required bool playedOut, Widget? on}) async {
      when(() => player.playing).thenReturn(false);
      await controller.play(id: 'vm-1', uri: Uri.parse('https://example.com/vm/vm-1.mp3'), isLocal: true);
      if (playedOut) playerStateController.add(PlayerState(false, ProcessingState.completed));

      await tester.pumpWidget(host(screen: on ?? section()));
      await tester.pump();
    }

    testWidgets('not while the section is shown', (tester) async {
      await listen(tester, playedOut: true);

      verifyNever(() => cubit.forgetHeardByListening());
    });

    testWidgets('when another section is shown', (tester) async {
      await listen(tester, playedOut: true);

      show(contacts);

      verify(() => cubit.forgetHeardByListening()).called(1);
    });

    testWidgets('when the app goes to the background', (tester) async {
      await listen(tester, playedOut: true);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      verify(() => cubit.forgetHeardByListening()).called(1);
    });

    testWidgets('not while a message is left part-way, and then once it has played out', (tester) async {
      await listen(tester, playedOut: false);

      show(contacts);

      // Paused for a look at another section, or still playing from there:
      // the person comes back to the message where they left it.
      verifyNever(() => cubit.forgetHeardByListening());

      playerStateController.add(PlayerState(false, ProcessingState.completed));

      verify(() => cubit.forgetHeardByListening()).called(1);
    });

    testWidgets('not when the screen locks in the middle of a message', (tester) async {
      await listen(tester, playedOut: false);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      // The app stops the sound in the background. The message was not
      // listened to, so it has to be there to go back to.
      verifyNever(() => cubit.forgetHeardByListening());
    });

    testWidgets('a screen of its own does not follow the sections', (tester) async {
      // The screen reached from settings is pushed over whichever section was
      // shown and has no bottom menu's router above it.
      await listen(tester, playedOut: true, on: const VoicemailScreen());

      show(contacts);

      verifyNever(() => cubit.forgetHeardByListening());
    });

    testWidgets('and with the rows goes the player that held one of them', (tester) async {
      // The cubit here answers as the real one does: the rows are let go of
      // once, and after that there is nothing to let go of.
      final states = StreamController<VoicemailState>.broadcast();
      addTearDown(states.close);
      var held = true;
      whenListen(cubit, states.stream, initialState: kept);
      when(() => cubit.forgetHeardByListening()).thenAnswer((_) {
        if (!held) return;
        held = false;
        states.add(const VoicemailState(filter: VoicemailFilter.unheard));
      });
      await listen(tester, playedOut: true);
      expect(find.byType(VoicemailTile), findsOneWidget);
      clearInteractions(player);

      show(contacts);
      await tester.pump();
      await tester.pump();

      // Let go of -> the row is no longer listed -> its player is stopped ->
      // the player says so -> asked again, with nothing left to do.
      expect(find.byType(VoicemailTile), findsNothing);
      expect(controller.activeId, isNull);
      verify(() => player.stop()).called(1);
    });
  });
}
