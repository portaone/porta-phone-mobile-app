import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/constants.dart';
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

Contact _contact({
  required int id,
  required String name,
  String? sourceId,
  ContactSourceType sourceType = ContactSourceType.external,
  bool? isCurrentUser = false,
  String? extension,
}) => Contact(
  id: id,
  sourceType: sourceType,
  kind: ContactKind.visible,
  sourceId: sourceId,
  isCurrentUser: isCurrentUser,
  aliasName: name,
  phones: [if (extension != null) ContactPhone(id: id, number: extension, label: kContactExtLabel, favorite: false)],
);

// Picking a colleague and hearing what came of it. Nothing in the list changes
// either way - the copy lands in somebody else's mailbox - so the sentence
// afterwards is the only report there is.
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
    when(() => cubit.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
        .thenAnswer((_) async => VoicemailForwardOutcome.sent);

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStateController.close();
  });

  void addressBookHolds(List<Contact> people) {
    when(() => contacts.watchContacts(any(), any())).thenAnswer((_) => Stream.value(people));
  }

  VoicemailState loaded() => VoicemailState(
    status: VoicemailStatus.loaded,
    items: [_voicemail('vm-1')],
    filters: VoicemailFilter.values,
    forwardSupported: true,
  );

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

  Future<void> openForwardSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forward'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet offers only colleagues a forward can reach', (tester) async {
    addressBookHolds([
      _contact(id: 1, name: 'Iryna Shevchuk', sourceId: 'user-7', extension: '102'),
      _contact(id: 2, name: 'Device Person', sourceId: 'user-8', sourceType: ContactSourceType.local),
      _contact(id: 3, name: 'No Server Id', sourceId: 'number_1001'),
      _contact(id: 4, name: 'Myself', sourceId: 'user-9', isCurrentUser: true),
    ]);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await openForwardSheet(tester);

    expect(find.text('Iryna Shevchuk'), findsOneWidget);
    expect(find.text('102'), findsOneWidget);
    // A row that cannot be a recipient is left out rather than shown
    // unselectable: the reason it cannot means nothing to a person.
    expect(find.text('Device Person'), findsNothing);
    expect(find.text('No Server Id'), findsNothing);
    expect(find.text('Myself'), findsNothing);
  });

  testWidgets('an address book with nobody to forward to says so', (tester) async {
    addressBookHolds([_contact(id: 1, name: 'Myself', sourceId: 'user-9', isCurrentUser: true)]);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await openForwardSheet(tester);

    expect(find.text('No colleagues found'), findsOneWidget);
  });

  testWidgets('one tap sends, and the colleague is named back', (tester) async {
    addressBookHolds([_contact(id: 1, name: 'Iryna Shevchuk', sourceId: 'user-7')]);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await openForwardSheet(tester);
    await tester.tap(find.text('Iryna Shevchuk'));
    await tester.pumpAndSettle();

    verify(() => cubit.forwardVoicemail('vm-1', toUserId: 'user-7')).called(1);
    expect(find.text('Forwarded to Iryna Shevchuk'), findsOneWidget);
  });

  testWidgets('dismissing the sheet forwards nothing', (tester) async {
    addressBookHolds([_contact(id: 1, name: 'Iryna Shevchuk', sourceId: 'user-7')]);
    whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

    await tester.pumpWidget(host());
    await openForwardSheet(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.forwardVoicemail(any(), toUserId: any(named: 'toUserId')));
  });

  group('what the screen says when it does not go through', () {
    Future<void> forwardWith(WidgetTester tester, VoicemailForwardOutcome outcome) async {
      when(() => cubit.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) async => outcome);
      addressBookHolds([_contact(id: 1, name: 'Iryna Shevchuk', sourceId: 'user-7')]);
      whenListen(cubit, const Stream<VoicemailState>.empty(), initialState: loaded());

      await tester.pumpWidget(host());
      await openForwardSheet(tester);
      await tester.tap(find.text('Iryna Shevchuk'));
      await tester.pumpAndSettle();
    }

    testWidgets('a recording too big is not offered a retry', (tester) async {
      await forwardWith(tester, VoicemailForwardOutcome.tooLarge);

      expect(find.text('Message too large to forward'), findsOneWidget);
      // Retrying sends the same recording, so a button there would only spend
      // a person's attention on a second no.
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a colleague who is full is named and not offered a retry', (tester) async {
      await forwardWith(tester, VoicemailForwardOutcome.recipientFull);

      expect(find.text('Iryna Shevchuk cannot receive more forwarded messages'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a backend that does not forward is offered a retry', (tester) async {
      await forwardWith(tester, VoicemailForwardOutcome.unavailable);

      expect(find.text('Forwarding is not available'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('anything else gets one sentence and a retry that works', (tester) async {
      await forwardWith(tester, VoicemailForwardOutcome.failed);

      expect(find.text('Could not forward'), findsOneWidget);

      when(() => cubit.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
          .thenAnswer((_) async => VoicemailForwardOutcome.sent);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // The retry sends to the same colleague without asking again: the person
      // already chose, and the failure was not about who they chose.
      verify(() => cubit.forwardVoicemail('vm-1', toUserId: 'user-7')).called(2);
      expect(find.text('Forwarded to Iryna Shevchuk'), findsOneWidget);
    });
  });
}
