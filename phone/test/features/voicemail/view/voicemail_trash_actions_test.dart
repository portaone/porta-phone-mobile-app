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

// Deleting a message means two different things, and the difference is the
// whole point of this change: with a trash it happens and is offered back,
// without one it is asked about first and then final.
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
    when(() => cubit.removeVoicemail(any())).thenAnswer((_) async => true);
    when(() => cubit.restoreVoicemail(any())).thenAnswer((_) async {});
    when(() => cubit.removeVoicemailPermanently(any())).thenAnswer((_) async {});

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  VoicemailState loaded({
    VoicemailFilter filter = VoicemailFilter.all,
    List<VoicemailFilter> filters = VoicemailFilter.values,
    List<Voicemail>? items,
  }) {
    final messages = items ?? [_voicemail('vm-1')];
    return VoicemailState(
      status: VoicemailStatus.loaded,
      items: filter == VoicemailFilter.trash ? const [] : messages,
      trashedItems: filter == VoicemailFilter.trash ? messages : const [],
      filter: filter,
      filters: filters,
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

  Future<void> chooseFromMenu(WidgetTester tester, String action) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('moving to the trash asks nothing and offers the way back', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Move to trash');

    // No dialog: a question before every delete trains people to dismiss it,
    // and this one has nothing to warn about.
    expect(find.text('Delete voicemail?'), findsNothing);
    verify(() => cubit.removeVoicemail('vm-1')).called(1);
    expect(find.text('Moved to trash'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('undoing a move to the trash puts the message back', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Move to trash');
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    verify(() => cubit.restoreVoicemail('vm-1')).called(1);
  });

  testWidgets('a move the server refused is not offered back', (tester) async {
    // Offering to undo something that never happened is worse than saying
    // nothing: the message is still there and the offer says it is not.
    when(() => cubit.removeVoicemail(any())).thenAnswer((_) async => false);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Move to trash');

    expect(find.text('Moved to trash'), findsNothing);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('without a trash the delete asks first and then is final', (tester) async {
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: loaded(filters: const [VoicemailFilter.all, VoicemailFilter.unheard]),
    );

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Delete');

    expect(find.text('Delete voicemail?'), findsOneWidget);
    verifyNever(() => cubit.removeVoicemail(any()));

    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    verify(() => cubit.removeVoicemail('vm-1')).called(1);
    expect(find.text('Moved to trash'), findsNothing);
  });

  testWidgets('restoring from the trash needs no confirmation', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded(filter: VoicemailFilter.trash));

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Restore');

    verify(() => cubit.restoreVoicemail('vm-1')).called(1);
  });

  testWidgets('deleting for good from the trash asks first', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded(filter: VoicemailFilter.trash));

    await tester.pumpWidget(host());
    await chooseFromMenu(tester, 'Delete permanently');

    expect(find.text('Delete permanently?'), findsOneWidget);
    verifyNever(() => cubit.removeVoicemailPermanently(any()));

    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    verify(() => cubit.removeVoicemailPermanently('vm-1')).called(1);
  });

  testWidgets('the trash says what it still costs', (tester) async {
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded(filter: VoicemailFilter.trash));

    await tester.pumpWidget(host());

    expect(find.text('Messages in the trash still use mailbox space until the trash is emptied.'), findsOneWidget);
  });
}
