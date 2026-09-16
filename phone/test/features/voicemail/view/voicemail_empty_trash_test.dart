import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/features/voicemail/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

Voicemail _voicemail(String id) => Voicemail(
  id: id,
  date: '2026-09-15 10:00:00',
  duration: 10.0,
  sender: '555001',
  displaySender: 'User 555001',
  receiver: '555002',
  status: ReadStatus.read,
  size: 1024,
  type: 'voicemail',
  url: 'https://example.test/$id.mp3',
);

// Which bulk destructive action a header carries, and where. One per screen:
// two of them side by side is how the wrong one gets pressed.
void main() {
  late _MockVoicemailCubit cubit;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
    player = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast(sync: true);

    when(() => player.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => player.playing).thenReturn(false);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => player.duration).thenReturn(const Duration(seconds: 10));
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.emptyVoicemailTrash()).thenAnswer((_) async {});
    when(() => cubit.removeAllVoicemails()).thenReturn(null);

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  VoicemailState loaded({
    VoicemailFilter filter = VoicemailFilter.all,
    List<VoicemailFilter> filters = VoicemailFilter.values,
    int count = 1,
  }) {
    final messages = [for (var i = 0; i < count; i++) _voicemail('vm-$i')];
    final inTrash = filter == VoicemailFilter.trash;
    return VoicemailState(
      status: VoicemailStatus.loaded,
      items: inTrash ? const [] : messages,
      trashedItems: inTrash ? messages : const [],
      filter: filter,
      filters: filters,
    );
  }

  Widget host(Widget screen) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          BlocProvider<VoicemailCubit>.value(value: cubit),
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

  group('emptying the trash', () {
    testWidgets('is offered on the trash and asks how much it removes', (tester) async {
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(filter: VoicemailFilter.trash, count: 4),
      );

      await tester.pumpWidget(host(const VoicemailScreen()));
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      expect(find.text('Empty trash?'), findsOneWidget);
      // The count is in the question because it is the part a person cannot
      // check once the dialog is covering the list.
      expect(
        find.text('All 4 messages in the trash will be removed and the space they use will be freed.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(confirmDialogYesButtonKey));
      await tester.pumpAndSettle();

      verify(() => cubit.emptyVoicemailTrash()).called(1);
    });

    testWidgets('is offered by the header that does not offer deleting everything', (tester) async {
      // That header is the bottom-menu tab's. It is where most people live and
      // where the trash is reached from, so refusing to finish the job there
      // would be arbitrary.
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded(filter: VoicemailFilter.trash));

      await tester.pumpWidget(host(const Scaffold(body: VoicemailDeleteAction(offersDeleteAll: false))));

      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });

    testWidgets('an empty trash leaves the control with nothing to do', (tester) async {
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(filter: VoicemailFilter.trash, count: 0),
      );

      await tester.pumpWidget(host(const VoicemailScreen()));

      expect(
        tester
            .widget<IconButton>(find.ancestor(of: find.byIcon(Icons.delete_sweep), matching: find.byType(IconButton)))
            .onPressed,
        isNull,
      );
    });
  });

  group('deleting every message', () {
    testWidgets('is not offered while there is a trash', (tester) async {
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

      await tester.pumpWidget(host(const VoicemailScreen()));

      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });

    testWidgets('is still offered where there is no trash', (tester) async {
      // Without a trash this is the only way to clear a mailbox, so taking it
      // away would leave nothing in its place.
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(filters: const [VoicemailFilter.all, VoicemailFilter.unheard]),
      );

      await tester.pumpWidget(host(const VoicemailScreen()));
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete all voicemails?'), findsOneWidget);
    });

    testWidgets('the header that never offered it still does not', (tester) async {
      whenListen(
        cubit,
        const Stream<VoicemailState>.empty(),
        initialState: loaded(filters: const [VoicemailFilter.all, VoicemailFilter.unheard]),
      );

      await tester.pumpWidget(host(const Scaffold(body: VoicemailDeleteAction(offersDeleteAll: false))));

      expect(find.byIcon(Icons.delete), findsNothing);
    });
  });
}
