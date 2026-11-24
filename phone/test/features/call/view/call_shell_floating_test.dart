import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

/// What floats over the call screen: what goes out from this phone - the camera preview (the
/// call's, the host's room's, the camera published to a room the call was invited to) or the tile
/// of a share from the call or to the host's room - in one window on every call screen.
void main() {
  ActiveCall call(String callId, {int line = 0, bool video = false}) => ActiveCall(
    callId: callId,
    direction: CallDirection.outgoing,
    line: line,
    handle: const CallkeepHandle.number('100'),
    createdTime: DateTime(2024),
    acceptedTime: DateTime(2024),
    video: video,
    processingStatus: CallProcessingStatus.connected,
  );

  final room = ConferenceState(
    phase: ConferencePhase.active,
    legs: const {'a': 0, 'b': 1},
    participants: const [
      ConferenceParticipant(line: 0, callId: 'a'),
      ConferenceParticipant(line: 1, callId: 'b'),
    ],
  );

  test('a leg of the room floats the room\'s camera while it is on, over the panel as over the full screen', () {
    final calls = [call('a', video: true), call('b', line: 1)];
    final withCamera = CallState(
      activeCalls: calls,
      conference: room.copyWith(selfVideo: _Stream()),
    );

    expect(CallShell.floatingOf(CallState(activeCalls: calls, conference: room)), CallFloating.none);
    expect(CallShell.floatingOf(withCamera), CallFloating.cameraPreview);
    expect(CallShell.cameraOf(withCamera, calls.first), withCamera.conference.selfVideo);
    expect(CallShell.roomFrontCamera(withCamera), isTrue, reason: 'the front one, where no leg says');
  });

  test('a participant invited to a room floats its camera there while it is published', () {
    // A voice call: the call itself sends no video, the camera goes to the host's room only.
    final calls = [call('a')];
    final invitedOff = CallState(activeCalls: calls, invitedVideo: const InvitedConferenceVideo(line: 0));
    final invitedOn = CallState(
      activeCalls: calls,
      invitedVideo: InvitedConferenceVideo(line: 0, selfVideo: _Stream()),
    );

    expect(CallShell.floatingOf(invitedOff), CallFloating.none);
    expect(CallShell.floatingOf(invitedOn), CallFloating.cameraPreview);
    expect(CallShell.cameraOf(invitedOn, calls.single), invitedOn.invitedVideo!.selfVideo);
  });

  test('the host\'s share to his room floats its tile in the camera\'s place', () {
    final state = CallState(
      activeCalls: [call('a'), call('b', line: 1)],
      conference: room.copyWith(selfVideo: _Stream()),
      screenShare: const ScreenShareState(target: RoomScreenShareTarget(), status: ScreenShareStatus.sharing),
    );

    expect(CallShell.floatingOf(state), CallFloating.screenShareTile);
  });

  test('a share on the call\'s own sender floats its tile in the preview\'s place', () {
    final state = CallState(
      activeCalls: [call('a')],
      screenShare: const ScreenShareState(target: CallScreenShareTarget('a'), status: ScreenShareStatus.sharing),
    );

    expect(CallShell.floatingOf(state), CallFloating.screenShareTile);
  });

  test('a share to the room the far end invited the call to floats its tile, as in a call', () {
    final state = CallState(
      activeCalls: [call('a')],
      screenShare: const ScreenShareState(
        target: RoomScreenShareTarget(invitedCallId: 'a'),
        status: ScreenShareStatus.sharing,
      ),
    );

    expect(CallShell.floatingOf(state), CallFloating.screenShareTile);
  });

  test('an ordinary call floats its preview while its camera is on', () {
    expect(CallShell.floatingOf(CallState(activeCalls: [call('a')])), CallFloating.none);
  });
}

class _Stream extends Fake implements MediaStream {}
