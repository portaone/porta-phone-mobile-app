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

// What the header offers over a handful of picked messages. It is not the same
// question in the trash: there is nowhere further for them to go, and a plain
// delete there would send an already-trashed message to the trash again.
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
    when(() => cubit.removeSelectedVoicemails()).thenReturn(null);
    when(() => cubit.removeSelectedVoicemailsPermanently()).thenReturn(null);
    when(() => cubit.restoreSelectedVoicemails()).thenReturn(null);

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  VoicemailState selecting({VoicemailFilter filter = VoicemailFilter.all, int count = 2}) {
    final messages = [for (var i = 0; i < count; i++) _voicemail('vm-$i')];
    final inTrash = filter == VoicemailFilter.trash;
    return VoicemailState(
      status: VoicemailStatus.loaded,
      items: inTrash ? const [] : messages,
      trashedItems: inTrash ? messages : const [],
      selectedVoicemailsIds: messages.map((message) => message.id).toList(),
      filter: filter,
      filters: VoicemailFilter.values,
    );
  }

  Widget host() {
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
        child: const PresenceViewParams(
          hybridPresenceSupport: false,
          blfViaSipSupport: false,
          presenceViaSipSupport: false,
          child: VoicemailScreen(),
        ),
      ),
    );
  }

  testWidgets('in the mailbox the picked messages go to the trash', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: selecting());

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Delete selected voicemails?'), findsOneWidget);
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    verify(() => cubit.removeSelectedVoicemails()).called(1);
    verifyNever(() => cubit.removeSelectedVoicemailsPermanently());
  });

  testWidgets('in the trash the same control ends them, and counts them first', (tester) async {
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: selecting(filter: VoicemailFilter.trash, count: 4),
    );

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    expect(find.text('Delete 4 messages permanently?'), findsOneWidget);
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    // A plain delete here would send an already-trashed message to the trash
    // again: accepted by the backend, and doing nothing at all.
    verify(() => cubit.removeSelectedVoicemailsPermanently()).called(1);
    verifyNever(() => cubit.removeSelectedVoicemails());
  });

  testWidgets('putting the picked messages back is not offered in the mailbox', (tester) async {
    // Nothing there has been deleted, so there is nothing to put back.
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: selecting());

    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.restore_from_trash), findsNothing);
  });

  testWidgets('putting the picked messages back is offered in the trash', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: selecting(filter: VoicemailFilter.trash));

    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.restore_from_trash), findsOneWidget);
  });

  testWidgets('putting them back needs no confirmation', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: selecting(filter: VoicemailFilter.trash));

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.restore_from_trash));
    await tester.pumpAndSettle();

    // It is what the trash is for, and anything it undoes is one tap from
    // being redone.
    verify(() => cubit.restoreSelectedVoicemails()).called(1);
  });

  testWidgets('with nothing picked the trash offers emptying instead', (tester) async {
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: selecting(filter: VoicemailFilter.trash).copyWith(selectedVoicemailsIds: const []),
    );

    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.restore_from_trash), findsNothing);
    expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
  });
}
