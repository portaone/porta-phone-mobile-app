import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../helpers/helpers.dart';
import 'call_active_scaffold_harness.dart';

/// The room in full screen through semantics: its controls are named, carry
/// their ids and act on the room when a screen reader activates them.
void main() {
  late MockCallBloc callBloc;

  setUp(() {
    callBloc = newCallBloc();
    pinPortraitSurface();
    // The tiles render the room's cameras; their renderers ask the platform
    // for a texture, which a test has none of.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      (call) async => call.method == 'createVideoRenderer' ? {'textureId': 1} : null,
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
  final room = ConferenceState(
    phase: ConferencePhase.active,
    legs: const {'anna': 0, 'boris': 1},
    participants: const [
      ConferenceParticipant(line: 0, callId: 'anna'),
      ConferenceParticipant(line: 1, callId: 'boris'),
    ],
    videoFeeds: {2: ParticipantCamera(stream: _Camera(), trackId: 'anna-video')},
  );
  const conferences = CallCapabilitiesConfig(isConferenceEnabled: true, isConferenceVideoEnabled: true);

  Future<void> openFullScreen(
    WidgetTester tester, {
    ConferenceState? conference,
    bool canShareScreen = false,
    ScreenShareStatus? roomShare,
    List<ActiveCall>? calls,
  }) async {
    final shown = conference ?? room;
    final activeCalls = calls ?? [anna, boris];
    final share = roomShare == null ? null : ScreenShareState(target: const RoomScreenShareTarget(), status: roomShare);
    when(() => callBloc.state).thenReturn(CallState(activeCalls: activeCalls, conference: shown, screenShare: share));
    await pumpCallScaffold(
      tester,
      buildCallScaffold(
        callBloc,
        activeCalls: activeCalls,
        focusedCall: anna,
        conference: shown,
        callConfig: conferences,
        keepControlsVisible: true,
        canShareScreen: canShareScreen,
        screenShare: share,
      ),
    );
    await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenId));
    await tester.pumpAndSettle();
    expect(find.byType(ConferenceFullScreen), findsOneWidget);
  }

  testWidgets('the end of the bar is named for the room and ends it', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    final end = find.bySemanticsIdentifier(conferenceFullScreenEndId);
    expectTapTargetSemantics(
      tester,
      end,
      label: 'End the conference and every call in it',
      identifier: conferenceFullScreenEndId,
    );
    await tapViaSemantics(tester, end);
    verify(() => callBloc.add(const CallControlEvent.conferenceEnded(endedBy: CallkeepEndedBy.user))).called(1);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('a tap on a tile opens its menu: mute for everyone, end the call', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    final tile = find.bySemanticsIdentifier(numberedId(conferenceTileId, 1));
    expectTapTargetSemantics(tester, tile, label: 'More for Boris Klein', identifier: numberedId(conferenceTileId, 1));
    expect(find.bySemanticsIdentifier(numberedId(conferenceTileMuteId, 1)), findsNothing, reason: 'no corner controls');

    await tapViaSemantics(tester, tile);
    await tester.pumpAndSettle();
    expect(find.text('Mute Boris Klein for everyone'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileMuteId, 1)));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.conferenceParticipantMuted('boris', true))).called(1);

    await tapViaSemantics(tester, tile);
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.ended('boris', endedBy: CallkeepEndedBy.user))).called(1);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the title counts everyone in the room, the host too', (tester) async {
    await openFullScreen(tester);

    expect(find.text('Conference · 3 participants'), findsOneWidget);

    await teardownCallScaffold(tester);
  });

  testWidgets('who sends video is a big tile; who does not, a thumbnail with the name under it', (tester) async {
    await openFullScreen(tester);

    final video = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
    final avatar = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 1)));
    expect(avatar.top, greaterThan(video.bottom), reason: 'the thumbnails go under the video');
    expect(video.height, greaterThan(avatar.height * 2));
    expect(avatar.width, greaterThan(video.width * 0.9), reason: 'alone in its row, the thumbnail stretches');
    expect(find.text('Boris Klein'), findsOneWidget);

    await teardownCallScaffold(tester);
  });

  testWidgets('the muted sign is on a tile only while its participant is muted', (tester) async {
    await openFullScreen(
      tester,
      conference: room.copyWith(
        participants: const [
          ConferenceParticipant(line: 0, callId: 'anna'),
          ConferenceParticipant(line: 1, callId: 'boris', muted: true),
        ],
      ),
    );

    expect(find.bySemanticsIdentifier(numberedId(conferenceTileMutedId, 1)), findsOneWidget);
    expect(find.bySemanticsIdentifier(numberedId(conferenceTileMutedId, 0)), findsNothing);

    await teardownCallScaffold(tester);
  });

  testWidgets('Hold says on a long press why it cannot be chosen', (tester) async {
    await openFullScreen(tester);

    await tester.tap(find.bySemanticsIdentifier(conferenceFullScreenMoreId));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Hold'));
    await tester.pumpAndSettle();

    expect(find.text('Hold is not available in a conference'), findsOneWidget);

    await teardownCallScaffold(tester);
  });

  testWidgets('the microphone of the bar mutes the host in the room', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMicId));
    verify(() => callBloc.add(const CallControlEvent.conferenceSelfMuted(true))).called(1);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  group('the screen share', () {
    testWidgets('More offers it where the room can take a screen, and starts it for the room', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester, canShareScreen: true);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMoreId));
      await tester.pumpAndSettle();
      final item = find.bySemanticsIdentifier(callScreenShareConferenceId);
      expect(item, findsOneWidget);
      expect(find.text('Share screen'), findsOneWidget);
      await tapViaSemantics(tester, item);
      await tester.pumpAndSettle();
      // The focused leg asks; the bloc takes a leg's share for the room's.
      verify(() => callBloc.add(const CallControlEvent.screenShareStarted('anna'))).called(1);

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('while the host shares, the call screen\'s menu carries the mark and an accented Stop', (tester) async {
      // A room without video has no full screen to go to: the call screen says the share itself.
      final semantics = tester.ensureSemantics();
      final share = const ScreenShareState(target: RoomScreenShareTarget(), status: ScreenShareStatus.sharing);
      when(() => callBloc.state)
          .thenReturn(CallState(activeCalls: [anna, boris], conference: room, screenShare: share));
      await pumpCallScaffold(
        tester,
        buildCallScaffold(
          callBloc,
          activeCalls: [anna, boris],
          focusedCall: anna,
          conference: room,
          callConfig: conferences,
          keepControlsVisible: true,
          screenShare: share,
        ),
      );

      expect(find.bySemanticsIdentifier(callActionsScreenShareBadgeId), findsOneWidget);
      expect(find.bySemanticsIdentifier(conferenceFullScreenId), findsOneWidget, reason: 'the way to the full screen');
      // Touched where a phone's automation touches it: the middle of the control's own node.
      final options = find.bySemanticsIdentifier(callActionsOptionsId);
      final badge = tester.getRect(find.bySemanticsIdentifier(callActionsScreenShareBadgeId));
      final optionsRect = tester.getRect(options);
      final screen = tester.getSize(find.byType(MaterialApp).first);
      expect(badge.right, lessThanOrEqualTo(screen.width), reason: 'the mark inside the screen');
      await tester.tapAt(optionsRect.center);
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(callActionsScreenShareId), findsOneWidget, reason: 'the menu opened');
      final stop = find.text('Stop sharing');
      expect(stop, findsOneWidget);
      final stopText = tester.element(stop);
      expect(
        DefaultTextStyle.of(stopText).style.color,
        Theme.of(stopText).colorScheme.primary,
        reason: 'in the accent',
      );

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('no mark on the call screen\'s menu while nothing is shared', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester, canShareScreen: true);
      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenBackId));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(callActionsScreenShareBadgeId), findsNothing);
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('a thumbnail carries the name on its card, at the bottom', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester);

      // Boris sends no video: a thumbnail in the row.
      final card = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 1)));
      final name = find
          .text('Boris Klein')
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((x) => identical(x, e))));
      expect(
        name.any((rect) => card.contains(rect.center) && rect.center.dy > card.center.dy),
        isTrue,
        reason: 'on the card, in its lower half, not under it',
      );

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('Add participant is in More, first, and no longer on the bar', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester);

      expect(find.bySemanticsIdentifier(conferenceFullScreenAddId), findsNothing, reason: 'not on the bar');
      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMoreId));
      await tester.pumpAndSettle();
      final add = find.bySemanticsIdentifier(conferenceFullScreenAddId);
      expect(add, findsOneWidget);
      expect(
        tester.getRect(add).top,
        lessThan(tester.getRect(find.bySemanticsIdentifier(conferenceFullScreenKeypadId)).top),
        reason: 'the first item',
      );
      expect(find.text('Add participant'), findsOneWidget);

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('Add participant in More sends the person to the lists for the room', (tester) async {
      final semantics = tester.ensureSemantics();
      final picking = DestinationPickingCubit();
      when(() => callBloc.state).thenReturn(CallState(activeCalls: [anna, boris], conference: room));
      await pumpCallScaffold(
        tester,
        buildCallScaffold(
          callBloc,
          activeCalls: [anna, boris],
          focusedCall: anna,
          conference: room,
          callConfig: conferences,
          keepControlsVisible: true,
          addParticipantAvailability: AddParticipantAvailability.available,
          picking: picking,
        ),
      );
      await tester.tap(find.bySemanticsIdentifier(conferenceFullScreenId));
      await tester.pumpAndSettle();

      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMoreId));
      await tester.pumpAndSettle();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenAddId));
      await tester.pumpAndSettle();

      expect((picking.state.purpose! as AddParticipantPurpose).anchorCallId, 'anna');
      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('More has no share where the room cannot take one', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMoreId));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(callScreenShareConferenceId), findsNothing);

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('while the host shares, More carries the mark; no tile, the camera is unavailable', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(tester, roomShare: ScreenShareStatus.sharing);

      expect(find.bySemanticsIdentifier(callScreenShareTileId), findsNothing);
      expect(find.bySemanticsIdentifier(callScreenShareConferenceBadgeId), findsOneWidget);
      expect(
        tester
            .widget<CallActionButton>(
              find.ancestor(
                of: find.bySemanticsIdentifier(conferenceFullScreenCameraId),
                matching: find.byType(CallActionButton),
              ),
            )
            .onPressed,
        isNull,
        reason: 'the screen holds the room\'s line',
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceFullScreenMoreId));
      await tester.pumpAndSettle();
      expect(find.text('Stop sharing'), findsOneWidget);
      final stopText = tester.element(find.text('Stop sharing'));
      expect(
        DefaultTextStyle.of(stopText).style.color,
        Theme.of(stopText).colorScheme.primary,
        reason: 'in the accent',
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callScreenShareConferenceId));
      await tester.pumpAndSettle();
      verify(() => callBloc.add(const CallControlEvent.screenShareStopped('anna'))).called(1);

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('a screen the room sends takes the main place, the tiles in a row under it', (tester) async {
      final semantics = tester.ensureSemantics();
      await openFullScreen(
        tester,
        conference: room.copyWith(
          screens: {3: ParticipantCamera(stream: _Camera(), trackId: 'boris-screen')},
          presenter: 3,
        ),
      );

      final screen = find.bySemanticsIdentifier(callScreenShareConferenceScreenId);
      expect(screen, findsOneWidget);
      expect(find.text('Boris Klein is sharing the screen'), findsOneWidget);
      expect(
        tester.getRect(find.bySemanticsIdentifier(callScreenShareConferenceLabelId)).bottom,
        lessThanOrEqualTo(tester.getRect(screen).top),
        reason: 'who shares is said above the screen',
      );
      final screenRect = tester.getRect(screen);
      final tileRect = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
      expect(tileRect.top, greaterThan(screenRect.bottom), reason: 'the tiles go under the screen');
      expect(screenRect.width, greaterThan(tileRect.width * 2));
      // No picture has come yet - a phone sends its screen only when it changes: the place says who
      // shares and that the screen is on its way, rather than standing empty.
      expect(find.descendant(of: screen, matching: find.text('Boris Klein')), findsWidgets);
      expect(find.descendant(of: screen, matching: find.text('Waiting for the screen')), findsOneWidget);

      semantics.dispose();
      await teardownCallScaffold(tester);
    });

    testWidgets('the presenter is not in the row; a tap on the screen opens his menu', (tester) async {
      // The share takes Boris's one video line: a thumbnail of him would be his avatar only,
      // repeating the screen. His menu is on the screen.
      final semantics = tester.ensureSemantics();
      await openFullScreen(
        tester,
        conference: room.copyWith(
          screens: {3: ParticipantCamera(stream: _Camera(), trackId: 'boris-screen')},
          presenter: 3,
        ),
      );

      final screenRect = tester.getRect(find.bySemanticsIdentifier(callScreenShareConferenceScreenId));
      final boris = find.bySemanticsIdentifier(numberedId(conferenceTileId, 1));
      expect(boris, findsOneWidget, reason: 'one control for Boris: the screen');
      expect(screenRect.contains(tester.getCenter(boris)), isTrue, reason: 'on the screen, not in the row');
      final anna = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
      expect(anna.top, greaterThan(screenRect.bottom), reason: 'the others stay in the row under it');
      // His name at the bottom of the screen, as a big tile has it.
      final names = find.text('Boris Klein');
      final onScreen = names.evaluate().where((element) {
        final rect = tester.getRect(find.byElementPredicate((e) => identical(e, element)));
        return rect.bottom > screenRect.bottom - 60 && rect.bottom <= screenRect.bottom;
      });
      expect(onScreen, isNotEmpty, reason: 'the name strip on the screen');

      await tester.tapAt(screenRect.center);
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(numberedId(conferenceTileMuteId, 1)), findsOneWidget);
      expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(numberedId(conferenceTileOpenId, 1)),
        findsNothing,
        reason: 'the screen is large already',
      );

      semantics.dispose();
      await teardownCallScaffold(tester);
    });
  });

  testWidgets('every tile carries the three dots at its top right; they open the tile\'s menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(
      tester,
      conference: room.copyWith(
        participants: const [
          ConferenceParticipant(line: 0, callId: 'anna'),
          ConferenceParticipant(line: 1, callId: 'boris', muted: true),
        ],
      ),
    );

    for (final (index, name) in [(0, 'Anna Marchenko'), (1, 'Boris Klein')]) {
      final more = find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, index));
      expectTapTargetSemantics(
        tester,
        more,
        label: 'More for $name',
        identifier: numberedId(conferenceTileMoreId, index),
      );
      final tile = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, index)));
      final dots = tester.getRect(more);
      expect(dots.topRight, tile.topRight, reason: 'at the top right corner of the tile');
    }
    final muted = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMutedId, 1)));
    expect(
      muted.overlaps(tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 1)))),
      isFalse,
      reason: 'clear of the muted sign',
    );

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 1)));
    await tester.pumpAndSettle();
    expect(find.text('Unmute Boris Klein for everyone'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.ended('boris', endedBy: CallkeepEndedBy.user))).called(1);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 0)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(numberedId(conferenceTileOpenId, 0)), findsOneWidget);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('dots under the call screen\'s floating window step to the top left, clear of the muted sign', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => floatingThumbnailArea.value = null);
    await openFullScreen(
      tester,
      conference: room.copyWith(
        participants: const [
          ConferenceParticipant(line: 0, callId: 'anna', muted: true),
          ConferenceParticipant(line: 1, callId: 'boris'),
        ],
      ),
    );
    final tile = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
    final other = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 1)));

    // The window where it starts: over the top right corner of the first tile.
    floatingThumbnailArea.value = Rect.fromLTWH(tile.right - 98, tile.top - 20, 90, 160);
    await tester.pumpAndSettle();

    final dots = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 0)));
    expect(dots.overlaps(floatingThumbnailArea.value!), isFalse, reason: 'not under the window');
    expect(dots.left, tile.left, reason: 'at the left of the tile');
    final muted = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMutedId, 0)));
    expect(dots.overlaps(muted), isFalse, reason: 'clear of the muted sign');
    expect(
      tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 1))),
      other,
      reason: 'a tile the window is not over keeps its dots',
    );
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 0)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier(numberedId(conferenceTileOpenId, 0)), findsOneWidget);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    floatingThumbnailArea.value = null;
    await tester.pumpAndSettle();
    expect(tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileMoreId, 0))).right, tile.right);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  group('the grid of big tiles', () {
    final calls = [
      for (final (line, name) in ['Anna', 'Boris', 'Clara', 'Denys'].indexed)
        makeCall(callId: name.toLowerCase(), acceptedTime: DateTime(2024), displayName: name).copyWith(line: line),
    ];
    final fourCameras = ConferenceState(
      phase: ConferencePhase.active,
      legs: {for (final call in calls) call.callId: call.line!},
      participants: [for (final call in calls) ConferenceParticipant(line: call.line!, callId: call.callId)],
      videoFeeds: {
        for (final call in calls) call.line! + 2: ParticipantCamera(stream: _Camera(), trackId: '${call.callId}-video'),
      },
    );

    /// Every renderer its own texture, each drawing frames of [width] x [height] at once.
    void sendFrames({required int width, required int height}) {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var textures = 0;
      messenger.setMockMethodCallHandler(
        const MethodChannel('FlutterWebRTC.Method'),
        (call) async => call.method == 'createVideoRenderer' ? {'textureId': 100 + textures++} : null,
      );
      for (var texture = 100; texture < 120; texture++) {
        messenger.setMockStreamHandler(
          EventChannel('FlutterWebRTC/Texture$texture'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success({'event': 'didTextureChangeVideoSize', 'width': width, 'height': height});
              events.success({'event': 'didFirstFrameRendered'});
            },
          ),
        );
      }
      addTearDown(() {
        for (var texture = 100; texture < 120; texture++) {
          messenger.setMockStreamHandler(EventChannel('FlutterWebRTC/Texture$texture'), null);
        }
      });
    }

    Rect tile(WidgetTester tester, int index) =>
        tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, index)));

    testWidgets('four phone cameras, or four not drawn yet, make two by two', (tester) async {
      sendFrames(width: 480, height: 640);
      await openFullScreen(tester, conference: fourCameras, calls: calls);

      expect(tile(tester, 1).top, tile(tester, 0).top);
      expect(tile(tester, 2).top, greaterThan(tile(tester, 0).bottom));
      expect(tile(tester, 3).top, tile(tester, 2).top);

      await teardownCallScaffold(tester);
    });

    testWidgets('four landscape cameras go one over the other', (tester) async {
      sendFrames(width: 1280, height: 720);
      await openFullScreen(tester, conference: fourCameras, calls: calls);
      // The hold lets the layout change once its time is up.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final first = tile(tester, 0);
      expect(tile(tester, 1).top, greaterThan(first.bottom));
      expect(first.width, greaterThan(first.height), reason: 'a row across the screen for each');

      await teardownCallScaffold(tester);
    });
  });

  testWidgets('the menu of a tile shows its participant large, the page an anchor of its own', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceTileOpenId, 0)));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(conferenceParticipantPageId), findsOneWidget);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the speaker\'s tile has the border, and nothing moves for it', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);
    final big = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0)));
    final thumbnail = tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 1)));
    expect(find.bySemanticsIdentifier(RegExp('^$conferenceTileSpeakingId')), findsNothing);
    await teardownCallScaffold(tester);

    // Boris, on line 1, is feed 3.
    await openFullScreen(tester, conference: room.copyWith(speaker: 3));

    final frame = find.bySemanticsIdentifier(numberedId(conferenceTileSpeakingId, 1));
    expect(frame, findsOneWidget);
    expect(tester.getRect(frame), thumbnail, reason: 'the border lies over the thumbnail itself');
    expect(find.bySemanticsIdentifier(numberedId(conferenceTileSpeakingId, 0)), findsNothing);
    expect(tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 0))), big);
    expect(tester.getRect(find.bySemanticsIdentifier(numberedId(conferenceTileId, 1))), thumbnail);
    expect(
      find.bySemanticsIdentifier(numberedId(conferenceTileId, 1)),
      findsOneWidget,
      reason: 'the tile keeps its own node, its menu as it was',
    );

    semantics.dispose();
    await teardownCallScaffold(tester);
  });

  testWidgets('the host speaking marks no participant\'s tile', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester, conference: room.copyWith(speaker: ConferenceState.hostFeed));

    expect(find.bySemanticsIdentifier(RegExp('^$conferenceTileSpeakingId')), findsNothing);

    semantics.dispose();
    await teardownCallScaffold(tester);
  });
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
