import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/voicemail/bloc/voicemail_playback_controller.dart';
import 'package:webtrit_phone/features/voicemail/models/voicemail_screen_context.dart';
import 'package:webtrit_phone/features/voicemail/widgets/audio_view.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../helpers/helpers.dart';

class _MockPlaybackController extends Mock implements VoicemailPlaybackController {}

class _MockScreenContext extends Mock implements VoicemailScreenContext {}

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  const path = 'https://example.test/voicemail.mp3';

  late _MockPlaybackController controller;
  late _MockScreenContext screenContext;

  setUpAll(() {
    registerFallbackValue(Uri.parse(path));
  });

  setUp(() {
    controller = _MockPlaybackController();
    when(() => controller.isLoading).thenReturn(false);
    when(() => controller.error).thenReturn(null);
    when(() => controller.addListener(any())).thenReturn(null);
    when(() => controller.removeListener(any())).thenReturn(null);

    screenContext = _MockScreenContext();
    when(() => screenContext.mediaHeaders).thenReturn(const {});
    when(() => screenContext.mediaCacheBasePath).thenReturn('/tmp/vm-cache');
  });

  Widget wrap({Duration? length}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<VoicemailPlaybackController>.value(value: controller),
            Provider<VoicemailScreenContext>.value(value: screenContext),
          ],
          child: AudioView(path: path, length: length),
        ),
      ),
    );
  }

  AudioPlayer stubPlayer({required bool playing, Duration? at}) {
    final player = _MockAudioPlayer();
    when(() => player.positionStream)
        .thenAnswer((_) => at == null ? const Stream<Duration>.empty() : Stream<Duration>.value(at));
    when(() => player.duration).thenReturn(const Duration(seconds: 30));
    when(() => player.playing).thenReturn(playing);
    return player;
  }

  testWidgets('the idle play button is named and starts playback through semantics', (tester) async {
    final handle = tester.ensureSemantics();

    when(() => controller.activeId).thenReturn(null);
    when(
      () => controller.play(
        id: any(named: 'id'),
        uri: any(named: 'uri'),
        headers: any(named: 'headers'),
        cacheBasePath: any(named: 'cacheBasePath'),
        cacheKey: any(named: 'cacheKey'),
        isLocal: any(named: 'isLocal'),
      ),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(wrap());

    final finder = find.bySemanticsIdentifier(voicemailPlaybackId);
    expectTapTargetSemantics(tester, finder, label: 'Play', identifier: voicemailPlaybackId, isButton: true);

    await tapViaSemantics(tester, finder);
    verify(
      () => controller.play(
        id: any(named: 'id'),
        uri: any(named: 'uri'),
        headers: any(named: 'headers'),
        cacheBasePath: any(named: 'cacheBasePath'),
        cacheKey: any(named: 'cacheKey'),
        isLocal: any(named: 'isLocal'),
      ),
    ).called(1);

    handle.dispose();
  });

  testWidgets('while playing, the same button is named "Pause", keeps its id and pauses through semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    // Build the mock before stubbing: mocktail forbids `when` inside a stub.
    final player = stubPlayer(playing: true);
    when(() => controller.activeId).thenReturn(path);
    when(() => controller.player).thenReturn(player);
    when(() => controller.isPlaying).thenReturn(true);
    when(() => controller.pause()).thenAnswer((_) async {});
    await tester.pumpWidget(wrap());

    final finder = find.bySemanticsIdentifier(voicemailPlaybackId);
    expectTapTargetSemantics(tester, finder, label: 'Pause', identifier: voicemailPlaybackId, isButton: true);

    await tapViaSemantics(tester, finder);
    verify(() => controller.pause()).called(1);

    handle.dispose();
  });

  testWidgets('a paused message offers Play again and resumes through semantics', (tester) async {
    final handle = tester.ensureSemantics();

    final player = stubPlayer(playing: false);
    when(() => controller.activeId).thenReturn(path);
    when(() => controller.player).thenReturn(player);
    when(() => controller.isPlaying).thenReturn(false);
    when(() => controller.resume()).thenAnswer((_) async {});
    await tester.pumpWidget(wrap());

    final finder = find.bySemanticsIdentifier(voicemailPlaybackId);
    expectTapTargetSemantics(tester, finder, label: 'Play', identifier: voicemailPlaybackId, isButton: true);

    await tapViaSemantics(tester, finder);
    verify(() => controller.resume()).called(1);

    handle.dispose();
  });

  testWidgets('the loading state says what is happening instead of going silent', (tester) async {
    final handle = tester.ensureSemantics();

    when(() => controller.activeId).thenReturn(path);
    when(() => controller.isLoading).thenReturn(true);
    await tester.pumpWidget(wrap());

    // Activating play replaces the button with this view, so it must announce
    // itself - otherwise focus is dropped with nothing spoken.
    expect(tester.getSemantics(find.byType(AudioLoadingView)), isSemantics(label: 'Loading', isLiveRegion: true));

    handle.dispose();
  });

  testWidgets('a failed playback offers a named retry that works through semantics', (tester) async {
    final handle = tester.ensureSemantics();

    when(() => controller.activeId).thenReturn(path);
    when(() => controller.error).thenReturn(Exception('boom'));
    when(
      () => controller.play(
        id: any(named: 'id'),
        uri: any(named: 'uri'),
        headers: any(named: 'headers'),
        cacheBasePath: any(named: 'cacheBasePath'),
        cacheKey: any(named: 'cacheKey'),
        isLocal: any(named: 'isLocal'),
      ),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(wrap());

    final finder = find.bySemanticsIdentifier(voicemailRetryId);
    expectTapTargetSemantics(tester, finder, label: 'Try again', identifier: voicemailRetryId, isButton: true);

    await tapViaSemantics(tester, finder);
    verify(
      () => controller.play(
        id: any(named: 'id'),
        uri: any(named: 'uri'),
        headers: any(named: 'headers'),
        cacheBasePath: any(named: 'cacheBasePath'),
        cacheKey: any(named: 'cacheKey'),
        isLocal: any(named: 'isLocal'),
      ),
    ).called(1);

    handle.dispose();
  });

  testWidgets('the idle placeholder slider is not offered as a control', (tester) async {
    final handle = tester.ensureSemantics();

    when(() => controller.activeId).thenReturn(null);
    await tester.pumpWidget(wrap());

    expect(find.byType(Slider), findsOneWidget);
    expect(find.semantics.byValue('0%'), findsNothing);

    handle.dispose();
  });

  group('how long a message is', () {
    // The mailbox lists every message with its length. The player used to draw
    // 0:00 on both sides until the recording was loaded - that is, until after
    // the person had already chosen what to listen to - and a screen reader was
    // told no length at all.
    testWidgets('is shown before anybody presses play', (tester) async {
      when(() => controller.activeId).thenReturn(null);
      await tester.pumpWidget(wrap(length: const Duration(milliseconds: 10783)));

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0:10'), findsOneWidget);
    });

    testWidgets('is said in words, not as a time of day, and the idle slider still is no control', (tester) async {
      final handle = tester.ensureSemantics();

      when(() => controller.activeId).thenReturn(null);
      await tester.pumpWidget(wrap(length: const Duration(milliseconds: 10783)));

      expect(find.bySemanticsLabel(RegExp('10 seconds')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('0:10')), findsNothing);
      expect(find.semantics.byValue(RegExp('seconds')), findsNothing);

      handle.dispose();
    });

    testWidgets('a message listed without a length shows no time at all', (tester) async {
      // Neither 0:00 nor a dash: both would be a length the message does not
      // have.
      final handle = tester.ensureSemantics();

      when(() => controller.activeId).thenReturn(null);
      await tester.pumpWidget(wrap());

      expect(find.text('0:00'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('second')), findsNothing);
      expect(find.byType(Slider), findsOneWidget);

      handle.dispose();
    });

    testWidgets('once the recording is loaded its own length replaces the listed one', (tester) async {
      final handle = tester.ensureSemantics();

      final player = stubPlayer(playing: true, at: const Duration(seconds: 12));
      when(() => controller.activeId).thenReturn(path);
      when(() => controller.player).thenReturn(player);
      await tester.pumpWidget(wrap(length: const Duration(seconds: 4)));
      await tester.pump();

      expect(find.text('0:30'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('30 seconds')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('4 seconds')), findsNothing);

      handle.dispose();
    });

    testWidgets('a message without a listed length gets one when its recording is loaded', (tester) async {
      final handle = tester.ensureSemantics();

      final player = stubPlayer(playing: false);
      when(() => controller.activeId).thenReturn(path);
      when(() => controller.player).thenReturn(player);
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('0:30'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('30 seconds')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the slider says how far into the message it is, in time', (tester) async {
      // It used to say a percentage, and the drawn 0:12 next to it was read as
      // twelve minutes past midnight.
      final handle = tester.ensureSemantics();

      final player = stubPlayer(playing: true, at: const Duration(seconds: 12));
      when(() => controller.activeId).thenReturn(path);
      when(() => controller.player).thenReturn(player);
      await tester.pumpWidget(wrap(length: const Duration(seconds: 30)));
      await tester.pump();

      expect(find.semantics.byValue('12 seconds of 30 seconds'), findsOne);
      expect(find.text('0:12'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('0:12')), findsNothing);

      handle.dispose();
    });
  });
}
