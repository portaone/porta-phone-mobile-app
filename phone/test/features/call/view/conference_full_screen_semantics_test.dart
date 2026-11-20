import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/keys.dart';
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

  Future<void> openFullScreen(WidgetTester tester) async {
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

  testWidgets('a tile mutes its participant for everyone and the menu ends his call', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    final mute = find.bySemanticsIdentifier(numberedId(conferenceTileMuteId, 1));
    expectTapTargetSemantics(
      tester,
      mute,
      label: 'Mute Boris Klein for everyone',
      identifier: numberedId(conferenceTileMuteId, 1),
    );
    await tapViaSemantics(tester, mute);
    verify(() => callBloc.add(const CallControlEvent.conferenceParticipantMuted('boris', true))).called(1);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.ended('boris', endedBy: CallkeepEndedBy.user))).called(1);

    semantics.dispose();
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

  testWidgets('a tile opens its participant through semantics, the page an anchor of its own', (tester) async {
    final semantics = tester.ensureSemantics();
    await openFullScreen(tester);

    final tile = find.bySemanticsIdentifier(numberedId(conferenceTileId, 0));
    expectTapTargetSemantics(tester, tile, label: 'Anna Marchenko', identifier: numberedId(conferenceTileId, 0));
    await tapViaSemantics(tester, tile);
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(conferenceParticipantPageId), findsOneWidget);

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
