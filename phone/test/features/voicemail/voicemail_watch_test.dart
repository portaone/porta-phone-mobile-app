import 'dart:async';

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
import 'package:webtrit_phone/features/voicemail/view/voicemail_tab_screen.dart';
import 'package:webtrit_phone/features/voicemail/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/view_params/presence_view_params.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockVoicemailCubit extends MockCubit<VoicemailState> implements VoicemailCubit {}

class _MockVoicemailSessionCubit extends MockCubit<VoicemailSessionState> implements VoicemailSessionCubit {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

Voicemail _voicemail(
  String id, {
  String sender = '555001',
  Contact? contact,
  ReadStatus status = ReadStatus.read,
  bool? saved = false,
  double duration = 42,
}) => Voicemail(
  id: id,
  date: '2026-11-10 14:02:00',
  duration: duration,
  sender: sender,
  senderContact: contact,
  receiver: '555002',
  status: status,
  size: 1024,
  type: 'voicemail',
  // Local, so playing it opens no cache and no network.
  url: '/tmp/vm/$id.mp3',
  saved: saved,
);

final _jane = Contact(
  id: 1,
  sourceType: ContactSourceType.external,
  kind: ContactKind.visible,
  firstName: 'Jane',
  lastName: 'Smith',
);

void main() {
  late _MockVoicemailCubit cubit;
  late _MockVoicemailSessionCubit session;
  late _MockAudioPlayer player;
  late StreamController<PlayerState> playerStates;
  late VoicemailPlaybackController controller;

  final jane = _voicemail('vm-jane', contact: _jane, status: ReadStatus.unread);
  final stranger = _voicemail('vm-stranger', sender: '+12025550143', duration: 65);

  setUpAll(() {
    registerFallbackValue(AudioSource.uri(Uri.parse('file:///fallback')));
    registerFallbackValue(jane);
  });

  setUp(() {
    cubit = _MockVoicemailCubit();
    session = _MockVoicemailSessionCubit();
    player = _MockAudioPlayer();
    playerStates = StreamController<PlayerState>.broadcast(sync: true);

    when(() => player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(() => player.playing).thenReturn(false);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
    when(() => player.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => player.duration).thenReturn(const Duration(seconds: 42));
    when(() => player.setAudioSource(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.markHeardByListening(any())).thenAnswer((_) async {});
    when(() => cubit.removeVoicemail(any())).thenAnswer((_) async {});
    when(() => cubit.toggleSavedStatus(any())).thenAnswer((_) async {});
    when(() => cubit.toggleSeenStatus(any())).thenAnswer((_) async {});

    controller = VoicemailPlaybackController(player: player, setupAudioSession: () async {});
  });

  tearDown(() async {
    await playerStates.close();
  });

  void mailbox(
    List<Voicemail> items, {
    VoicemailStatus status = VoicemailStatus.loaded,
    Object? error,
    Stream<VoicemailSessionState> changes = const Stream.empty(),
  }) => whenListen(
    session,
    changes,
    initialState: VoicemailSessionState(status: status, items: items, error: error),
  );

  void screen({
    VoicemailFilter filter = VoicemailFilter.all,
    List<VoicemailFilter> filters = VoicemailFilter.values,
    List<Voicemail> trash = const [],
  }) => whenListen(
    cubit,
    const Stream<VoicemailState>.empty(),
    initialState: VoicemailState(
      filter: filter,
      filters: filters,
      trashedItems: trash,
      trashStatus: filter == VoicemailFilter.trash ? VoicemailStatus.loaded : VoicemailStatus.initial,
    ),
  );

  Widget app(Widget screen) => ThemeProvider(
    settings: const ThemeSettings(),
    lightDynamic: null,
    darkDynamic: null,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          BlocProvider<VoicemailCubit>.value(value: cubit),
          BlocProvider<VoicemailSessionCubit>.value(value: session),
          Provider<AppTime>.value(value: AppTime(is24HourFormat: true)),
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
    ),
  );

  Future<void> openJane(WidgetTester tester) async {
    await tester.tap(find.text('Jane Smith'));
    await tester.pumpAndSettle();
  }

  /// Scrolls the message's page down to [finder]: on a small face the rows
  /// under the player start below the fold.
  Future<void> reach(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(
    finder,
    40,
    scrollable: find.descendant(of: find.byType(VoicemailWatchPage), matching: find.byType(Scrollable)).first,
  );

  Future<void> back(WidgetTester tester) async {
    unawaited(tester.state<NavigatorState>(find.byType(Navigator)).maybePop());
    await tester.pumpAndSettle();
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the list is the title, the filter pill and a row per message, no app bar', (tester) async {
      preset.apply(tester);
      mailbox([jane, stranger]);
      screen();
      expect(await pumpCollectingOverflows(tester, app(const VoicemailScreen())), isEmpty);

      expect(find.text('Voicemail'), findsOneWidget);
      expect(find.byKey(voicemailWatchFilterKey), findsOneWidget);
      expect(find.byType(WatchSeparator), findsOneWidget);
      expect(find.byType(VoicemailWatchTile), findsNWidgets(2));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(VoicemailFilterRow), findsNothing);
    });

    testWidgets('on $preset a message page is the player, its rows and Call back on the edge', (tester) async {
      preset.apply(tester);
      mailbox([jane, stranger]);
      screen();
      await tester.pumpWidget(app(const VoicemailScreen()));
      await openJane(tester);

      expect(find.byType(VoicemailWatchPage), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Tue, 10 Nov, 14:02'), findsOneWidget);
      expect(find.byType(WatchPlayButton), findsOneWidget);
      expect(find.text('0:42'), findsOneWidget);
      expect(find.bySemanticsIdentifier(voicemailWatchCallId), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the section in the bottom menu is headed by its own name', (tester) async {
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen();
    await tester.pumpWidget(app(const VoicemailTabScreen(watchTitle: 'Mailbox')));

    expect(find.text('Mailbox'), findsOneWidget);
    expect(find.byType(VoicemailWatchTile), findsOneWidget);
  });

  testWidgets('a row says who, how long and when; a new one is marked, and says New', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    mailbox([jane, stranger]);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.textContaining('0:42 · '), findsOneWidget);
    expect(find.textContaining('1:05 · '), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Jane Smith, New, 42 seconds, ')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^\+12025550143, 1 minute 5 seconds, ')), findsOneWidget);
    expect(find.byType(CircleIndicator), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the pill names the filter, and a tap shows the next one', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen(filter: VoicemailFilter.unheard);
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.bySemanticsLabel('Filter, currently New'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchFilterId));
    verify(() => cubit.setFilter(VoicemailFilter.saved)).called(1);
    handle.dispose();
  });

  testWidgets('one filter is no choice: no pill and no bar', (tester) async {
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen(filters: const [VoicemailFilter.all]);
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.byKey(voicemailWatchFilterKey), findsNothing);
    expect(find.byType(WatchSeparator), findsNothing);
  });

  for (final preset in watchPresets) {
    testWidgets('on $preset an empty filter is a state page with the pill under it', (tester) async {
      preset.apply(tester);
      mailbox([jane]);
      screen(filter: VoicemailFilter.saved);
      expect(await pumpCollectingOverflows(tester, app(const VoicemailScreen())), isEmpty);

      expect(find.byType(WatchStatePage), findsOneWidget);
      expect(find.text('No saved messages'), findsOneWidget);
      expect(find.byKey(voicemailWatchFilterKey), findsOneWidget);
    });
  }

  testWidgets('an empty mailbox offers Refresh on the edge, where a phone pulls to refresh', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    when(() => cubit.refresh()).thenAnswer((_) async {});
    mailbox([jane]);
    screen(filter: VoicemailFilter.saved);
    await tester.pumpWidget(app(const VoicemailScreen()));

    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchRefreshId));
    verify(() => cubit.refresh()).called(1);
    handle.dispose();
  });

  testWidgets('an empty trash says what the trash costs', (tester) async {
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen(filter: VoicemailFilter.trash);
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.text('Trash is empty'), findsOneWidget);
    expect(find.textContaining('still use mailbox space'), findsOneWidget);
  });

  testWidgets('on its way a loading page; failed, Try again on the edge reads the box again', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    mailbox(const [], status: VoicemailStatus.loading);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    expect(find.byType(WatchSpinner), findsOneWidget);

    mailbox(const [], status: VoicemailStatus.loaded, error: Exception('offline'));
    await tester.pumpWidget(app(const VoicemailScreen(key: ValueKey('again'))));
    await tester.pump();
    expect(find.text('Something went wrong'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchRetryId));
    verify(() => cubit.refresh()).called(1);
    handle.dispose();
  });

  testWidgets('a backend without voicemail says so, with nothing to press', (tester) async {
    watchPresets.first.apply(tester);
    mailbox(const [], status: VoicemailStatus.featureNotSupported);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.text('Feature not supported'), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsNothing);
  });

  testWidgets('Play starts the message and marks it heard; the ring and the time follow it', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    when(() => player.positionStream).thenAnswer((_) => Stream.value(const Duration(seconds: 12)));
    mailbox([jane]);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchPlayId));
    await tester.pump();
    await tester.pump();

    verify(() => cubit.markHeardByListening(jane)).called(1);
    verify(() => player.setAudioSource(any())).called(1);
    expect(controller.activeId, jane.id);
    expect(find.text('0:12 / 0:42'), findsOneWidget);
    expect(find.semantics.byValue('12 seconds of 42 seconds'), findsOne);
    final ring = tester.widget<CircularProgressIndicator>(
      find.descendant(of: find.byType(WatchPlayButton), matching: find.byType(CircularProgressIndicator)),
    );
    expect(ring.value, closeTo(12 / 42, 0.01));
    handle.dispose();
  });

  testWidgets('going back from a playing message stops it', (tester) async {
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);
    await tester.tap(find.byKey(voicemailWatchPlayKey));
    await tester.pump();
    expect(controller.activeId, jane.id);

    await back(tester);

    expect(controller.activeId, isNull);
    expect(find.byType(VoicemailWatchPage), findsNothing);
  });

  testWidgets('the rows mark it, keep it and move it to the trash; Call back calls who left it', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);

    await reach(tester, find.text('Mark as heard'));
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchHeardId));
    verify(() => cubit.toggleSeenStatus(jane)).called(1);
    expect(find.text('Mark as heard'), findsOneWidget);

    await reach(tester, find.text('Save'));
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchSaveId));
    verify(() => cubit.toggleSavedStatus(jane)).called(1);
    expect(find.text('Save'), findsOneWidget);

    // A mailbox with a trash takes a delete back, so it goes without asking.
    await reach(tester, find.text('Move to trash'));
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchDeleteId));
    verify(() => cubit.removeVoicemail(jane.id)).called(1);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchCallId));
    verify(() => cubit.startCall(jane)).called(1);
    handle.dispose();
  });

  testWidgets('without a trash Delete asks first, on the watch confirm', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    mailbox([jane]);
    screen(filters: const [VoicemailFilter.all, VoicemailFilter.unheard]);
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);

    await reach(tester, find.text('Delete'));
    expect(find.text('Save'), findsNothing);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchDeleteId));
    await tester.pumpAndSettle();

    expect(find.byType(WatchConfirm), findsOneWidget);
    verifyNever(() => cubit.removeVoicemail(any()));
    handle.dispose();
  });

  testWidgets('in the trash the rows are Restore and Delete permanently, and nobody is called back', (tester) async {
    watchPresets.first.apply(tester);
    when(() => cubit.restoreVoicemail(any())).thenAnswer((_) async {});
    mailbox(const []);
    screen(filter: VoicemailFilter.trash, trash: [jane]);
    await tester.pumpWidget(app(const VoicemailScreen()));

    expect(find.textContaining('still use mailbox space'), findsOneWidget);
    await openJane(tester);

    await reach(tester, find.text('Delete permanently'));
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.bySemanticsIdentifier(voicemailWatchCallId), findsNothing);

    await tester.tap(find.text('Restore'));
    verify(() => cubit.restoreVoicemail(jane.id)).called(1);
  });

  testWidgets('a message nobody is known to have left has no Call back', (tester) async {
    watchPresets.first.apply(tester);
    mailbox([_voicemail('vm-unknown', sender: '')]);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    await tester.tap(find.text('Unknown'));
    await tester.pumpAndSettle();

    expect(find.byType(VoicemailWatchPage), findsOneWidget);
    expect(find.bySemanticsIdentifier(voicemailWatchCallId), findsNothing);
  });

  testWidgets('the page closes once its message has left the list', (tester) async {
    watchPresets.first.apply(tester);
    final changes = StreamController<VoicemailSessionState>();
    addTearDown(changes.close);
    mailbox([jane, stranger], changes: changes.stream);
    screen();
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);
    expect(find.byType(VoicemailWatchPage), findsOneWidget);

    changes.add(VoicemailSessionState(status: VoicemailStatus.loaded, items: [stranger]));
    await tester.pumpAndSettle();

    expect(find.byType(VoicemailWatchPage), findsNothing);
    expect(find.byType(VoicemailWatchTile), findsOneWidget);
  });

  testWidgets('a message that leaves the list while its delete asks closes the page, not the question', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    final changes = StreamController<VoicemailSessionState>();
    addTearDown(changes.close);
    mailbox([jane, stranger], changes: changes.stream);
    screen(filters: const [VoicemailFilter.all, VoicemailFilter.unheard]);
    await tester.pumpWidget(app(const VoicemailScreen()));
    await openJane(tester);
    await reach(tester, find.text('Delete'));
    await tapViaSemantics(tester, find.bySemanticsIdentifier(voicemailWatchDeleteId));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsOneWidget);

    changes.add(VoicemailSessionState(status: VoicemailStatus.loaded, items: [stranger]));
    await tester.pumpAndSettle();

    expect(find.byType(VoicemailWatchPage), findsNothing);
    handle.dispose();
  });
}
