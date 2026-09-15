import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// What a handshake says about the conference, and what the bloc does about
/// it: a room lives on the media server and outlives the socket, so every
/// (re)connect settles the two accounts of it - the server's and this
/// client's (`packages/signaling/docs/conference_protocol.md`, section 7).
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  StateHandshake handshake({ConferenceInfo? conference, List<Line?> lines = const []}) => StateHandshake(
    keepaliveInterval: const Duration(seconds: 30),
    timestamp: 0,
    registration: const Registration(status: RegistrationStatus.registered),
    lines: lines,
    presenceInfos: const [],
    dialogInfos: const [],
    guestLine: null,
    conference: conference,
  );

  /// The state of a client hosting room 7 with two legs, as the bloc leaves
  /// it once the room is up: both legs quiet, their audio in the mix.
  /// Returns their peer connections.
  Map<String, FakePeerConnection> seedRoom({int room = 7}) {
    final peers = {'a': h.seedEstablishedCall('a', line: 0), 'b': h.seedEstablishedCall('b', line: 1)};
    for (final entry in peers.entries) {
      entry.value.fakeSenders.single.replaceTrack(null);
      h.bloc.state.retrieveActiveCall(entry.key)?.remoteStream?.getAudioTracks().single.enabled = false;
    }
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(
      h.bloc.state.copyWith(
        conference: ConferenceState(
          room: room,
          phase: ConferencePhase.active,
          legs: const {'a': 0, 'b': 1},
          participants: const [
            ConferenceParticipant(line: 0, callId: 'a'),
            ConferenceParticipant(line: 1, callId: 'b'),
          ],
        ),
      ),
    );
    return peers;
  }

  /// The lines the server would report for the two merged calls.
  List<Line?> roomLines() => [
    Line(
      callId: 'a',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 0, callId: 'a'))],
    ),
    Line(
      callId: 'b',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 1, callId: 'b'))],
    ),
  ];

  test('a room in the handshake is hung up', () async {
    h.signaling.emitHandshake(handshake(conference: const ConferenceInfo(room: 4242)));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.errors.errors, isEmpty);
  });

  test('a handshake without a room asks for nothing', () async {
    h.signaling.emitHandshake(handshake());
    await pumpEventQueue();

    expect(h.signaling.requests, isEmpty);
  });

  test('a refused hangup is reported, not thrown', () async {
    h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'no_conference');

    h.signaling.emitHandshake(handshake(conference: const ConferenceInfo(room: 4242)));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.errors.errors, hasLength(1));
  });

  test('the room this client hosts survives the drop, with the server\'s membership', () async {
    final peers = seedRoom();

    // The mixer kept mixing while the socket was down, and one leg left in
    // the meantime.
    h.signaling.emitHandshake(
      handshake(
        lines: roomLines(),
        conference: const ConferenceInfo(room: 7, participants: [ConferenceParticipant(line: 0, callId: 'a')]),
      ),
    );
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
    expect(h.bloc.state.conference.phase, ConferencePhase.active);
    expect(h.bloc.state.conference.legs, {'a': 0});
    // The leg that left is an ordinary call again: it talks, it is heard and
    // it is held. The one still in the room stays quiet.
    expect(peers['b']!.fakeSenders.single.track, isNotNull);
    expect(h.bloc.state.retrieveActiveCall('b')!.remoteStream!.getAudioTracks().single.enabled, isTrue);
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(peers['a']!.fakeSenders.single.track, isNull);
    expect(h.callkeep.groups.last.callIds, ['a']);
  });

  test('a room the server no longer has is dropped and its legs are calls again', () async {
    final peers = seedRoom();

    h.signaling.emitHandshake(handshake(lines: roomLines()));
    await pumpEventQueue();

    expect(h.bloc.state.conference, const ConferenceState());
    for (final callId in ['a', 'b']) {
      expect(peers[callId]!.fakeSenders.single.track, isNotNull);
      expect(h.bloc.state.retrieveActiveCall(callId)!.remoteStream!.getAudioTracks().single.enabled, isTrue);
    }
    expect(h.callkeep.ungroups.single, ['a', 'b']);
    expect(h.callkeep.held, [
      (callId: 'a', onHold: false),
      (callId: 'b', onHold: true),
    ], reason: 'one carries on, the rest are held');
    expect(h.notifications.single, isA<ConferenceEndedNotification>());
  });

  test('a different room on the server ends there and is dropped here', () async {
    seedRoom();

    h.signaling.emitHandshake(handshake(lines: roomLines(), conference: const ConferenceInfo(room: 99)));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.bloc.state.conference, const ConferenceState());
    expect(h.callkeep.held, [(callId: 'a', onHold: false), (callId: 'b', onHold: true)]);
  });
}
