import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

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

// Opening the card of whoever left a message. The tile knows a contact exists
// because it is showing that person's name; what it does not have is the row's
// id, so the card is looked up when it is asked for.
void main() {
  late _MockVoicemailCubit cubit;
  late _MockContactsRepository contacts;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStateController;
  late VoicemailPlaybackController controller;

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
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

  VoicemailState loaded() =>
      VoicemailState(status: VoicemailStatus.loaded, items: [_voicemail('vm-1')], filters: VoicemailFilter.values);

  Widget host() {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          BlocProvider<VoicemailCubit>.value(value: cubit),
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
    when(() => contacts.getContactByPhoneNumber(any())).thenAnswer((_) async => null);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    expect(find.text('That contact is no longer in your address book'), findsOneWidget);
  });

  testWidgets('the card is asked for by the number that left the message', (tester) async {
    when(() => contacts.getContactByPhoneNumber(any())).thenAnswer((_) async => null);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    verify(() => contacts.getContactByPhoneNumber('555001')).called(1);
  });
}
