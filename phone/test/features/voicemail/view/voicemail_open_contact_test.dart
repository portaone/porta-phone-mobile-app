import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockVoicemailSessionCubit extends MockCubit<VoicemailSessionState> implements VoicemailSessionCubit {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

/// A message from [sender]; [name] is what the address book calls them, and
/// without [inAddressBook] it has no card for them at all.
Voicemail _voicemail(String id, {String sender = '555001', String? name = 'User 555001', bool inAddressBook = true}) =>
    Voicemail(
      id: id,
      date: '2026-09-15 10:00:00',
      duration: 10.0,
      sender: sender,
      senderContact: inAddressBook
          ? Contact(id: 5, sourceType: ContactSourceType.external, kind: ContactKind.visible, aliasName: name)
          : null,
      receiver: '555002',
      status: ReadStatus.read,
      size: 1024,
      type: 'voicemail',
      url: 'https://example.test/$id.mp3',
    );

// Opening the card of whoever left a message. The tile knows a contact exists
// because it is showing that person's name; what it does not have is the row's
// id, so the card is looked up when it is asked for.
void main() {
  late _MockVoicemailCubit cubit;
  late _MockVoicemailSessionCubit session;
  late _MockContactsRepository contacts;
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
    contacts = _MockContactsRepository();
    player = _MockAudioPlayer();
    playerStateController = StreamController<PlayerState>.broadcast(sync: true);

    when(() => player.playerStateStream).thenAnswer((_) => playerStateController.stream);
    when(() => player.playing).thenReturn(false);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => player.duration).thenReturn(const Duration(seconds: 10));
    when(() => cubit.refresh()).thenAnswer((_) async {});

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

  VoicemailState loaded() {
    mailboxHolds([_voicemail('vm-1')]);
    return const VoicemailState(filters: VoicemailFilter.values);
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
          RepositoryProvider<ContactsRepository>.value(value: contacts),
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

  testWidgets('a caller who has left the address book says so instead of opening nothing', (tester) async {
    // The list was drawn from a name that was true when it was drawn. The
    // address book can move on - a contact deleted on another device, a sync
    // that dropped them - between then and the tap.
    when(() => cubit.callerOf(any())).thenAnswer((_) async => null);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    expect(find.text('That contact is no longer in your address book'), findsOneWidget);
  });

  testWidgets('the card is asked for from the mailbox, not from a repository', (tester) async {
    // Who left a message is the mailbox's business; this screen only decides
    // where the person lands.
    when(() => cubit.callerOf(any())).thenAnswer((_) async => null);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    final asked = verify(() => cubit.callerOf(captureAny())).captured.single as Voicemail;
    expect(asked.sender, '555001');
  });

  testWidgets('a contact without a name has its card opened like any other', (tester) async {
    // Such a contact is shown by its number, exactly as a stranger is; the
    // menu used to take that for "not a contact" and leave the action out.
    when(() => cubit.callerOf(any())).thenAnswer((_) async => null);
    mailboxHolds([_voicemail('vm-1', name: null)]);
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: const VoicemailState(filters: VoicemailFilter.values),
    );

    await tester.pumpWidget(host());
    expect(find.text('555001'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    final asked = verify(() => cubit.callerOf(captureAny())).captured.single as Voicemail;
    expect(asked.sender, '555001');
  });

  testWidgets('a number the address book does not know has no card to open', (tester) async {
    mailboxHolds([_voicemail('vm-1', inAddressBook: false)]);
    whenListen(
      cubit,
      const Stream<VoicemailState>.empty(),
      initialState: const VoicemailState(filters: VoicemailFilter.values),
    );

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Open contact'), findsNothing);
  });

  group('a message the backend listed without a sender', () {
    // It could not read who left that one. The recording is there to be heard;
    // there is nobody to call back and no card to open.
    VoicemailState nameless() {
      mailboxHolds([_voicemail('vm-1', sender: '', inAddressBook: false)]);
      return const VoicemailState(filters: VoicemailFilter.values);
    }

    testWidgets('is shown under the name for an unknown caller', (tester) async {
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: nameless());

      await tester.pumpWidget(host());

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('offers neither a call back nor a contact to open, and keeps the rest', (tester) async {
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: nameless());

      await tester.pumpWidget(host());
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Call'), findsNothing);
      expect(find.text('Open contact'), findsNothing);
      expect(find.text('Move to trash'), findsOneWidget);
    });
  });
}
