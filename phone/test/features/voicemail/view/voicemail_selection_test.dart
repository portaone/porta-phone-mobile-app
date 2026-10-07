import 'dart:async';

import 'package:flutter/services.dart';

import 'package:material_ui/material_ui.dart';
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
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockVoicemailSessionCubit extends MockCubit<VoicemailSessionState> implements VoicemailSessionCubit {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

Voicemail _voicemail(String id) => Voicemail(
  id: id,
  date: '2026-09-15 10:00:00',
  duration: 10.0,
  sender: '555001',
  senderContact: Contact(
    id: 1,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    aliasName: 'User 555001',
  ),
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
  late _MockVoicemailSessionCubit session;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
    registerFallbackValue(_voicemail('fallback'));
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
    session = _MockVoicemailSessionCubit();
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

  /// What the session knows of the mailbox, which the screen reads beside its
  /// own state.
  void mailboxHolds(List<Voicemail> items) => whenListen(
    session,
    const Stream<VoicemailSessionState>.empty(),
    initialState: VoicemailSessionState(status: VoicemailStatus.loaded, items: items),
  );

  VoicemailState selecting({VoicemailFilter filter = VoicemailFilter.all, int count = 2, bool trashSupported = true}) {
    final messages = [for (var i = 0; i < count; i++) _voicemail('vm-$i')];
    final inTrash = filter == VoicemailFilter.trash;
    mailboxHolds(inTrash ? const [] : messages);
    return VoicemailState(
      trashedItems: inTrash ? messages : const [],
      selectedVoicemailsIds: messages.map((message) => message.id).toList(),
      filter: filter,
      // A backend has a trash exactly when the screen offers the trash filter.
      filters: [
        for (final offered in VoicemailFilter.values)
          if (trashSupported || offered != VoicemailFilter.trash) offered,
      ],
    );
  }

  Widget host() {
    return MaterialApp(
      locale: const Locale('en'),
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

    // Nothing is asked: they can be had back, as one message deleted from its
    // menu can. It used to ask whether to delete them permanently, while they
    // went to the trash.
    expect(find.byKey(confirmDialogYesButtonKey), findsNothing);
    expect(find.textContaining('permanently'), findsNothing);

    verify(() => cubit.removeSelectedVoicemails()).called(1);
    verifyNever(() => cubit.removeSelectedVoicemailsPermanently());
  });

  testWidgets('in the mailbox of a backend without a trash the same press is final, and the question says so', (
    tester,
  ) async {
    // There the messages do not go anywhere they could be had back from, so
    // the old question is the true one.
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: selecting(trashSupported: false));

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Delete selected voicemails?'), findsOneWidget);
    expect(find.text('Selected voicemails will be permanently deleted. Do you want to continue?'), findsOneWidget);
    expect(find.textContaining('trash'), findsNothing);
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    verify(() => cubit.removeSelectedVoicemails()).called(1);
  });

  testWidgets('one message picked in the trash is asked about as one', (tester) async {
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: selecting(filter: VoicemailFilter.trash, count: 1),
    );

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    expect(find.text('Delete the message permanently?'), findsOneWidget);
    expect(find.textContaining('1 messages'), findsNothing);
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

  group('what is picked, for a screen reader', () {
    // A picked row is tinted and says "selected" when focus comes to it, but at
    // the moment of the press nothing is read out: TalkBack stayed silent or
    // read the row's name again. So the number picked is announced whenever it
    // changes - and it changes without a press too.

    /// What the app asked the screen reader to say, in order.
    List<String> announcements(WidgetTester tester) {
      final said = <String>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
        message,
      ) async {
        final event = message as Map<dynamic, dynamic>;
        if (event['type'] == 'announce') said.add((event['data'] as Map<dynamic, dynamic>)['message'] as String);
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
      );
      return said;
    }

    /// The screen over a mailbox whose selection goes through [steps], on a
    /// platform that does or does not take announcements.
    Future<void> pick(WidgetTester tester, List<List<String>> steps, {bool announces = true}) async {
      final first = selecting(count: 3).copyWith(selectedVoicemailsIds: const []);
      final states = StreamController<VoicemailState>();
      addTearDown(states.close);
      whenListen(cubit, states.stream, initialState: first);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(supportsAnnounce: announces),
          child: host(),
        ),
      );
      for (final picked in steps) {
        states.add(first.copyWith(selectedVoicemailsIds: picked));
        await tester.pump();
      }
    }

    testWidgets('each change says how many are picked now, in words that stand alone', (tester) async {
      final said = announcements(tester);

      await pick(tester, [
        ['vm-0'],
        ['vm-0', 'vm-1'],
        ['vm-0'],
        [],
      ]);

      expect(said, ['1 message selected', '2 messages selected', '1 message selected', 'Nothing selected']);
    });

    testWidgets('a change nobody pressed for is said too', (tester) async {
      // A message deleted elsewhere drops out of what is picked; a bulk action
      // clears it. Announcing from the press would leave both silent.
      final said = announcements(tester);

      await pick(tester, [
        ['vm-0', 'vm-1', 'vm-2'],
        ['vm-0', 'vm-1'],
      ]);

      expect(said, ['3 messages selected', '2 messages selected']);
    });

    testWidgets('the same number again says nothing', (tester) async {
      final said = announcements(tester);

      await pick(tester, [
        ['vm-0'],
        ['vm-0'],
      ]);

      expect(said, ['1 message selected']);
    });

    testWidgets('nothing is announced where the platform does not take announcements', (tester) async {
      final said = announcements(tester);

      await pick(tester, [
        ['vm-0'],
      ], announces: false);

      expect(said, isEmpty);
    });
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
