import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_active_scaffold_harness.dart';

/// The room in full screen is a page of the call screen's routes on a phone:
/// opened from the panel, a participant one tap further, back the router's,
/// and closed by itself when it stops applying.
void main() {
  late MockCallBloc callBloc;
  late List<String> rendererCalls;

  setUp(() {
    callBloc = newCallBloc();
    pinPortraitSurface();
    rendererCalls = [];
    var textures = 0;
    // The tiles render the room's cameras; their renderers ask the platform
    // for a texture, which a test has none of.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      (call) async {
        rendererCalls.add(call.method);
        return call.method == 'createVideoRenderer' ? {'textureId': ++textures} : null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      null,
    );
  });

  final anna = makeCall(callId: 'anna', acceptedTime: DateTime(2024), displayName: 'Anna Marchenko');
  final boris = makeCall(callId: 'boris', acceptedTime: DateTime(2024), displayName: 'Boris Klein').copyWith(line: 1);
  final outside = makeCall(
    callId: 'outside',
    acceptedTime: DateTime(2024),
    displayName: 'Clara Diaz',
    held: true,
  ).copyWith(line: 2);
  final ringing = makeCall(
    callId: 'ringing',
    processingStatus: CallProcessingStatus.incomingFromOffer,
  ).copyWith(line: 3);
  final room = ConferenceState(
    phase: ConferencePhase.active,
    legs: const {'anna': 0, 'boris': 1},
    videoFeeds: {2: ParticipantCamera(stream: _Camera(), trackId: 'anna-video')},
  );
  const conferences = CallCapabilitiesConfig(isConferenceEnabled: true, isConferenceVideoEnabled: true);

  Widget screen({List<ActiveCall>? calls, ActiveCall? focused, ConferenceState? conference}) {
    final activeCalls = calls ?? [anna, boris];
    final shownRoom = conference ?? room;
    when(() => callBloc.state).thenReturn(CallState(activeCalls: activeCalls, conference: shownRoom));
    return buildCallScaffold(
      callBloc,
      activeCalls: activeCalls,
      focusedCall: focused ?? anna,
      conference: shownRoom,
      callConfig: conferences,
      keepControlsVisible: true,
    );
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  bool fullScreenShown() => find.byType(ConferenceFullScreen).evaluate().isNotEmpty;

  Future<void> openFullScreen(WidgetTester tester) async {
    await pumpCallScaffold(tester, screen());
    await tester.tap(byId(conferenceFullScreenId));
    await tester.pumpAndSettle();
    expect(fullScreenShown(), isTrue);
    expect(find.byType(CallControls), findsNothing, reason: 'the tiles take the place of the default screen');
  }

  testWidgets('the tiles open from the panel, a participant from his tile, back goes one page at a time', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.tap(byId(conferenceTileId));
    await tester.pumpAndSettle();
    expect(byId(conferenceParticipantPageId), findsOneWidget);

    await tester.tap(byId(conferenceFullScreenBackId));
    await tester.pumpAndSettle();
    expect(byId(conferenceParticipantPageId), findsNothing);
    expect(fullScreenShown(), isTrue, reason: 'back from a participant is the tiles');

    await tester.tap(byId(conferenceFullScreenBackId));
    await tester.pumpAndSettle();
    expect(fullScreenShown(), isFalse);
    expect(find.byType(CallControls), findsOneWidget);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the system back leaves the tiles for the default screen', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isFalse);
    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('a room that is gone closes the full screen: a call with one participant is left', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.pumpWidget(screen(calls: [anna], conference: const ConferenceState()));
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isFalse);
    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('a ringing call closes the full screen for its answer buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.pumpWidget(screen(calls: [anna, boris, ringing], focused: ringing));
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isFalse);
    expect(find.byType(IncomingCallActions), findsOneWidget);
    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the focus moving to a call outside the room closes the full screen', (tester) async {
    // Calling somebody in through Add moves it so.
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.pumpWidget(screen(calls: [anna, boris, outside], focused: outside));
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isFalse);
    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('a participant who leaves takes his page with him, and the tiles say so', (tester) async {
    final semantics = tester.ensureSemantics();
    final carol = makeCall(callId: 'carol', acceptedTime: DateTime(2024), displayName: 'Carol Young').copyWith(line: 2);
    final three = room.copyWith(legs: const {'anna': 0, 'boris': 1, 'carol': 2});
    await pumpCallScaffold(tester, screen(calls: [anna, boris, carol], conference: three));
    await tester.tap(byId(conferenceFullScreenId));
    await tester.pumpAndSettle();
    await tester.tap(byId('${conferenceTileId}3'));
    await tester.pumpAndSettle();
    expect(byId(conferenceParticipantPageId), findsOneWidget);

    await tester.pumpWidget(screen(calls: [anna, boris], conference: room));
    await tester.pumpAndSettle();

    expect(byId(conferenceParticipantPageId), findsNothing);
    expect(fullScreenShown(), isTrue, reason: 'two are still in the room');
    expect(find.text('Carol Young left the conference'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(conferenceFullScreenNoticeId)),
      isSemantics(
        identifier: conferenceFullScreenNoticeId,
        label: 'Carol Young left the conference',
        isLiveRegion: true,
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Carol Young left the conference'), findsNothing, reason: 'the notice is short');
    expect(find.bySemanticsIdentifier(conferenceFullScreenNoticeId), findsNothing);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the first leg leaving a room that goes on keeps the full screen, and the tiles say so', (tester) async {
    // The focus of a room is its first leg: it moves to the next one.
    final semantics = tester.ensureSemantics();
    final carol = makeCall(callId: 'carol', acceptedTime: DateTime(2024), displayName: 'Carol Young').copyWith(line: 2);
    final three = room.copyWith(legs: const {'anna': 0, 'boris': 1, 'carol': 2});
    await pumpCallScaffold(tester, screen(calls: [anna, boris, carol], conference: three));
    await tester.tap(byId(conferenceFullScreenId));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      screen(
        calls: [boris, carol],
        focused: boris,
        conference: room.copyWith(legs: const {'boris': 1, 'carol': 2}),
      ),
    );
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isTrue, reason: 'two are still in the room');
    expect(find.text('Anna Marchenko left the conference'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the keypad of More is shown on the default screen', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tester.tap(byId(conferenceFullScreenMoreId));
    await tester.pumpAndSettle();
    await tester.tap(byId(conferenceFullScreenKeypadId));
    await tester.pumpAndSettle();

    expect(fullScreenShown(), isFalse);
    expect(byId(callActionsHideKeypadId), findsOneWidget, reason: 'the keypad is open on the default screen');
    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  group('three in the room', () {
    final carol = makeCall(callId: 'carol', acceptedTime: DateTime(2024), displayName: 'Carol Young').copyWith(line: 2);
    // Carol's camera is the one that moves when Anna, before her, leaves.
    final three = room.copyWith(
      legs: const {'anna': 0, 'boris': 1, 'carol': 2},
      videoFeeds: {
        2: ParticipantCamera(stream: _Camera(), trackId: 'anna-video'),
        4: ParticipantCamera(stream: _Camera(), trackId: 'carol-video'),
      },
    );

    Future<void> openThree(WidgetTester tester) async {
      await pumpCallScaffold(tester, screen(calls: [anna, boris, carol], conference: three));
      await tester.tap(byId(conferenceFullScreenId));
      await tester.pumpAndSettle();
    }

    /// The cameras being shown anywhere, the pages under the top one counted.
    int camerasHeld() => find
        .byWidgetPredicate((widget) => widget is ParticipantVideo && widget.camera != null, skipOffstage: false)
        .evaluate()
        .length;

    testWidgets('a camera tile that moves to another row keeps its renderer', (tester) async {
      final semantics = tester.ensureSemantics();
      await openThree(tester);
      final made = rendererCalls.where((method) => method == 'createVideoRenderer').length;

      // Anna leaves: Carol's tile moves up to the first row.
      await tester.pumpWidget(
        screen(
          calls: [boris, carol],
          focused: boris,
          conference: three.copyWith(
            legs: const {'boris': 1, 'carol': 2},
            videoFeeds: {4: ParticipantCamera(stream: three.videoFeeds[4]!.stream, trackId: 'carol-video')},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(rendererCalls.where((method) => method == 'createVideoRenderer'), hasLength(made));
      await tester.pump(const Duration(seconds: 4));
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('the tiles under a participant hold no cameras, and get them back on top', (tester) async {
      final semantics = tester.ensureSemantics();
      await openThree(tester);
      expect(camerasHeld(), 4, reason: 'the default screen and the tiles, each with Anna and Carol');

      await tester.tap(byId(conferenceTileId));
      await tester.pumpAndSettle();
      expect(camerasHeld(), 3, reason: "the default screen's two and Anna's page");

      await tester.tap(byId(conferenceFullScreenBackId));
      await tester.pumpAndSettle();
      expect(camerasHeld(), 4);
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('a participant who leaves is said on the page on top', (tester) async {
      final semantics = tester.ensureSemantics();
      await openThree(tester);
      await tester.tap(byId('${conferenceTileId}2'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        screen(
          calls: [anna, boris],
          conference: three.copyWith(legs: const {'anna': 0, 'boris': 1}),
        ),
      );
      await tester.pumpAndSettle();

      expect(byId(conferenceParticipantPageId), findsOneWidget, reason: "Boris's page stays");
      expect(find.text('Carol Young left the conference'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('the page of a participant who leaves shows him to the end, never the tiles', (tester) async {
      final semantics = tester.ensureSemantics();
      await openThree(tester);
      await tester.tap(byId('${conferenceTileId}3'));
      await tester.pumpAndSettle();
      final onPage = find.text('Carol Young').evaluate().length;

      await tester.pumpWidget(
        screen(
          calls: [anna, boris],
          conference: three.copyWith(legs: const {'anna': 0, 'boris': 1}),
        ),
      );
      // Mid-way through the page's exit.
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Carol Young'), findsNWidgets(onPage), reason: 'the leaving page is still about Carol');
      await tester.pumpAndSettle();
      expect(find.text('Carol Young'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      semantics.dispose();
      await teardownCallScaffold(tester);
    });
  });

  group('the You tile', () {
    final self = _SelfCamera();
    testWidgets('mirrors the front camera, as the local preview does', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCallScaffold(tester, screen(conference: room.copyWith(selfVideo: self)));
      await tester.tap(byId(conferenceFullScreenId));
      await tester.pumpAndSettle();

      expect(_selfVideo(tester).mirror, isTrue);
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('shows the rear camera as it is', (tester) async {
      final semantics = tester.ensureSemantics();
      final rear = anna.copyWith(video: true, frontCamera: false);
      await pumpCallScaffold(
        tester,
        screen(
          calls: [rear, boris],
          focused: rear,
          conference: room.copyWith(selfVideo: self),
        ),
      );
      await tester.tap(byId(conferenceFullScreenId));
      await tester.pumpAndSettle();

      expect(_selfVideo(tester).mirror, isFalse);
      semantics.dispose();
      await teardownCallScaffold(tester);
    });
  });

  testWidgets('a page of the room outside the phone\'s call screen shows nothing and leaves', (tester) async {
    // A watch hosts the same routes; a link or a restored stack naming the
    // room there must not build it.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ConferenceFullScreenPage())),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ConferenceFullScreenPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}

/// The camera tile of the host: the one [ParticipantVideo] with his track.
ParticipantVideo _selfVideo(WidgetTester tester) => tester.widget<ParticipantVideo>(
  find.byWidgetPredicate((widget) => widget is ParticipantVideo && widget.camera?.trackId == 'self-video'),
);

/// This client's own camera as the room gets it: a local stream of one track.
class _SelfCamera extends Fake implements MediaStream {
  final _track = _Track();

  @override
  String get id => 'self';

  @override
  String get ownerTag => 'local';

  @override
  List<MediaStreamTrack> getVideoTracks() => [_track];
}

class _Track extends Fake implements MediaStreamTrack {
  @override
  String? get id => 'self-video';
}

/// A camera the room sends, as far as a renderer asks of it.
class _Camera extends Fake implements MediaStream {
  @override
  String get id => 'anna-camera';

  @override
  String get ownerTag => 'room';

  @override
  List<MediaStreamTrack> getVideoTracks() => const [];
}
