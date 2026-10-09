import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc_harness.dart';

/// The conference as the bloc drives it, from the merge to the end of the
/// room, against the obligations of packages/signaling/docs/conference_protocol.md.
/// The server is the fake signaling module, the mixer a fake peer connection.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};
const _candidate = {'candidate': 'candidate:1 1 udp 1 10.0.0.1 5000 typ host', 'sdpMid': '0', 'sdpMLineIndex': 0};

ConferenceParticipant _participant(String callId, int line, {bool muted = false}) =>
    ConferenceParticipant(line: line, callId: callId, muted: muted);

CallBlocHarness _harness({bool peerMessages = false}) => CallBlocHarness(
  capabilities: CallCapabilitiesConfig(isConferenceEnabled: true, isPeerMessageEnabled: peerMessages),
);

/// A harness against a server that has `conference_rejoin`.
CallBlocHarness _rejoinHarness({ManualOfferDeadline? deadline}) => CallBlocHarness(
  capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true, isConferenceRejoinEnabled: true),
  offerDeadline: deadline,
);

/// Room 7 with legs a and b, up and carrying audio: the mixer's connection
/// has reached it. Returns leg a's connection and the mixer's.
Future<({FakePeerConnection a, FakePeerConnection mixer})> _roomUp(CallBlocHarness h) async {
  final a = h.seedEstablishedCall('a', line: 0);
  h.seedEstablishedCall('b', line: 1);
  await _merge(h, ['a', 'b']);
  await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
  final mixer = h.peerFactory.created.single;
  mixer.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
  return (a: a, mixer: mixer);
}

/// The handshake of a session that has just come up, with room 7 and both of
/// its legs still standing on the server.
StateHandshake _handshakeWithRoom() => StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 0,
  registration: const Registration(status: RegistrationStatus.registered),
  lines: [
    Line(
      callId: 'a',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 0, callId: 'a'))],
    ),
    Line(
      callId: 'b',
      callLogs: [CallEventLog(timestamp: 0, callEvent: const AcceptedEvent(line: 1, callId: 'b'))],
    ),
  ],
  presenceInfos: const [],
  dialogInfos: const [],
  guestLine: null,
  conference: ConferenceInfo(room: 7, participants: [_participant('a', 0), _participant('b', 1)]),
);

/// The session goes: the module is down and says so.
Future<void> _loseSession(CallBlocHarness h) async {
  h.signaling.connected = false;
  h.signaling.emitLifecycle(SignalingDisconnecting());
  await pumpEventQueue();
}

/// The mixer's connection loses its path, the way a network outage ends it.
Future<void> _failMixer(FakePeerConnection mixer) async {
  mixer.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
  mixer.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
  await pumpEventQueue();
}

Future<void> _merge(CallBlocHarness h, List<String> callIds) async {
  h.bloc.add(CallControlEvent.merged(callIds));
  await pumpEventQueue();
}

Future<void> _offerRoom(CallBlocHarness h, int room, List<ConferenceParticipant> participants) async {
  h.signaling.emit(ConferenceOfferEvent(room: room, jsep: _offer, participants: participants));
  await pumpEventQueue();
}

/// Pumps until [done], or gives up after enough turns for anything the bloc
/// queues in response to one event.
Future<void> _settle(CallBlocHarness h, bool Function() done) async {
  for (var turn = 0; turn < 50 && !done(); turn++) {
    await pumpEventQueue();
  }
}

/// A leg's audio as the bloc left it: what the sender carries and whether
/// the far end plays.
({MediaStreamTrack? sending, bool hearing}) _audioOf(CallBlocHarness h, FakePeerConnection peer, String callId) {
  final call = h.bloc.state.retrieveActiveCall(callId)!;
  return (sending: peer.fakeSenders.single.track, hearing: call.remoteStream!.getAudioTracks().single.enabled);
}

/// Quiet for the room: nothing sent, nothing heard.
bool _quiet(CallBlocHarness h, FakePeerConnection peer, String callId) {
  final audio = _audioOf(h, peer, callId);
  return audio.sending == null && !audio.hearing;
}

/// An ordinary call again: the microphone on the sender, the far end heard.
bool _restored(CallBlocHarness h, FakePeerConnection peer, String callId) {
  final audio = _audioOf(h, peer, callId);
  return audio.sending != null && audio.hearing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a room mute closes the microphone without waiting on the server', () async {
    // The host's mute is his own and is carried out locally: a participant's
    // mute still waiting on the server is no reason for the room to go on
    // hearing him. It used to be queued behind exactly that.
    final h = _harness();
    final first = Completer<void>();
    final second = Completer<void>();
    addTearDown(() async {
      if (!first.isCompleted) first.complete();
      if (!second.isCompleted) second.complete();
      await pumpEventQueue();
      await h.close();
    });
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;

    h.signaling.gate = first;
    h.bloc.add(const CallControlEvent.conferenceParticipantMuted('a', true));
    await _settle(h, () => h.signaling.requests.whereType<ConferenceMuteRequest>().length == 1);
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    h.bloc.add(const CallControlEvent.conferenceParticipantMuted('b', true));
    await pumpEventQueue();
    h.signaling.gate = second;
    first.complete();
    await _settle(h, () => h.signaling.requests.whereType<ConferenceMuteRequest>().length == 2);

    expect(h.bloc.state.conference.selfMuted, isTrue);
    expect(mixer.fakeSenders.single.track, isNull, reason: 'while the second server request is still pending');
  });

  test('a candidate during the room\'s setup does not hold up its End', () async {
    // The connection feeds a candidate in turn with its own work, so one that
    // arrives while the answer is still being prepared waits behind it there.
    // Waiting for it in the mutation queue held the room's End and its
    // assembly deadline behind a microphone that had not opened yet.
    final gate = Completer<void>();
    final media = _GatedMedia(gate);
    final h = CallBlocHarness(
      capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
      userMediaBuilder: media,
    );
    addTearDown(() async {
      if (!gate.isCompleted) gate.complete();
      await pumpEventQueue();
      await h.close();
    });
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    await _settle(h, () => media.pending);

    h.signaling.emit(const ConferenceIceTrickleEvent(candidate: _candidate));
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.conferenceEnded());
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
  });

  test('a merge quiets the legs on the ack and records the room as assembling', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);

    await _merge(h, ['a', 'b']);

    expect(h.signaling.requests.single, isA<MergeRequest>().having((r) => r.lines, 'lines', [0, 1]));
    expect(h.bloc.state.conference.phase, ConferencePhase.assembling);
    expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1});
    expect(_quiet(h, a, 'a'), isTrue);
    expect(_quiet(h, b, 'b'), isTrue);
    expect(h.bloc.state.conference.room, isNull, reason: 'the room id comes with the offer');

    await _merge(h, ['a', 'b']);
    expect(h.signaling.requests, hasLength(1), reason: 'one room per session; the second merge is not sent');
  });

  test('the offer is answered and the legs are grouped, with no hold published', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1, held: true);
    await _merge(h, ['a', 'b']);

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    expect(h.signaling.requests.last, isA<ConferenceAnswerRequest>().having((r) => r.jsep['type'], 'type', 'answer'));
    final mixer = h.peerFactory.created.single;
    expect(mixer.remoteDescriptions.single.sdp, _offer['sdp']);
    expect(mixer.addedTracks.single, h.media.microphone, reason: 'the one microphone, as every call holds it');
    final conference = h.bloc.state.conference;
    expect(conference.phase, ConferencePhase.active);
    expect(conference.room, 7);
    expect(conference.participants, [_participant('a', 0), _participant('b', 1)]);
    expect(h.callkeep.groups.single.groupId, 'room-7');
    expect(h.callkeep.groups.single.callIds, ['a', 'b']);
    // The server un-held the leg as it joined, with no event, so the flag
    // follows the list. The operating system is told the group and nothing
    // else: CallKit ends one of two ungrouped calls that are both active, and
    // a leg taken off hold before its group is declared is exactly that.
    expect(h.bloc.state.retrieveActiveCall('b')!.held, isFalse);
    expect(h.callkeep.held, isEmpty);
  });

  test('candidates flow both ways, a remote one ahead of the offer waiting for it', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    h.signaling.emit(const ConferenceIceTrickleEvent(candidate: _candidate));
    await pumpEventQueue();
    expect(h.peerFactory.created, isEmpty, reason: 'no connection before the offer');

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;
    expect(mixer.candidates.single.candidate, _candidate['candidate']);

    mixer.onIceCandidate!(RTCIceCandidate('candidate:2', '0', 0));
    mixer.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateComplete);
    await pumpEventQueue();

    final trickles = h.signaling.requests.whereType<ConferenceIceTrickleRequest>().toList();
    expect(trickles.map((r) => r.candidate?['candidate']), ['candidate:2', null]);
  });

  test('a refused merge changes nothing and tells the host why', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'conference_already_active');

    await _merge(h, ['a', 'b']);

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(a.fakeSenders.single.replaced, isEmpty);
    expect(
      h.notifications.single,
      isA<ConferenceRefusedNotification>().having((n) => n.reason, 'reason', 'conference_already_active'),
    );
  });

  test('a merge without the capability, or with a call that cannot join, sends nothing', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);

    await _merge(h, ['a', 'b']);
    expect(h.signaling.requests, isEmpty);

    final enabled = _harness();
    addTearDown(enabled.close);
    enabled.seedEstablishedCall('a', line: 0);
    enabled.seedEstablishedCall('b', line: 1);
    await _merge(enabled, ['a', 'missing']);
    expect(enabled.signaling.requests, isEmpty, reason: 'two legs are needed');
  });

  test('a failure between the ack and the offer brings the legs back', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    h.signaling.emit(const ConferenceFailedEvent(reason: 'video_not_supported', detail: 'line 1 is a video call'));
    await pumpEventQueue();

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(a.fakeSenders.single.replaced, [null, isNotNull], reason: 'off for the room, then back on');
    expect(_audioOf(h, a, 'a').hearing, isTrue);
    expect(_audioOf(h, b, 'b').hearing, isTrue);
    // The legs leave the room all active on the server: one is resumed and
    // the rest held, rather than every one of them being held.
    expect(h.callkeep.held, [(callId: 'a', onHold: false), (callId: 'b', onHold: true)]);
    expect(h.callkeep.ungroups, [
      ['a', 'b'],
    ]);
    expect(
      h.notifications.single,
      isA<ConferenceFailedNotification>().having((n) => n.reason, 'reason', 'video_not_supported'),
    );
    expect(h.peerFactory.created, isEmpty, reason: 'no offer, no mixer connection');
  });

  test('a leg the server could not mix is a call again, on hold', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);
    h.seedEstablishedCall('c', line: 2);
    await _merge(h, ['a', 'b', 'c']);

    await _offerRoom(h, 7, [_participant('a', 0), _participant('c', 2)]);

    expect(h.bloc.state.conference.legs, {'a': 0, 'c': 2});
    expect(_restored(h, b, 'b'), isTrue);
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(h.callkeep.groups.single.callIds, ['a', 'c']);
  });

  test('a participant that leaves the list after the offer is restored and held', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);
    h.seedEstablishedCall('c', line: 2);
    await _merge(h, ['a', 'b', 'c']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1), _participant('c', 2)]);

    h.signaling.emit(
      ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0), _participant('c', 2, muted: true)]),
    );
    await pumpEventQueue();

    final conference = h.bloc.state.conference;
    expect(conference.legs, {'a': 0, 'c': 2});
    expect(conference.participantMuted('c'), isTrue, reason: 'the list is replaced, not merged');
    expect(_restored(h, b, 'b'), isTrue);
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(h.callkeep.groups.last.callIds, ['a', 'c']);
  });

  test('a terminated room leaves the calls as ordinary calls, one of them live', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();

    expect(h.bloc.state.conference, const ConferenceState());
    expect(_restored(h, a, 'a'), isTrue);
    expect(_restored(h, b, 'b'), isTrue);
    expect(h.callkeep.held, [(callId: 'a', onHold: false), (callId: 'b', onHold: true)], reason: 'one stays live');
    expect(h.callkeep.ungroups.single, ['a', 'b']);
    expect(h.peerFactory.created.single.closes, 1);
    expect(h.media.released, contains(h.media.built.last), reason: 'the room gave its stream back');
    expect(h.media.microphoneLive, isTrue, reason: 'the calls that go on still hold the microphone');
    expect(h.notifications.single, isA<ConferenceEndedNotification>());
  });

  test('after a lost mixer a leg that is already ending is left alone', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    final b = h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(
      h.bloc.state.copyWithMappedActiveCall(
        'b',
        (call) => call.copyWith(processingStatus: CallProcessingStatus.disconnecting),
      ),
    );

    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();

    expect(h.callkeep.held, [(callId: 'a', onHold: false)], reason: 'a carries on, b is going and is left alone');
    expect(b.fakeSenders.single.replaced, [null], reason: 'no audio back for a call on its way out');
    expect(h.notifications.single, isA<ConferenceEndedNotification>(), reason: 'a is still a call');
  });

  test('ending the conference hangs up the room and every leg', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.bloc.add(const CallControlEvent.conferenceEnded());
    await pumpEventQueue();

    expect(h.signaling.requests.last, isA<ConferenceHangupRequest>());
    expect(h.callkeep.endCalls, ['a', 'b']);
    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(a.fakeSenders.single.replaced, [null], reason: 'no audio back for calls being hung up');
    expect(h.callkeep.held, isEmpty);

    // The server's confirmation finds nothing to restore.
    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();
    expect(h.notifications, isEmpty);
    expect(h.errors.errors, isEmpty);
  });

  test('a leg that hangs up leaves the room', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.signaling.emit(const HangupEvent(line: 1, callId: 'b', code: 487, reason: 'Request Terminated'));
    // The hangup crosses the signalling handler and the mutation queue; a
    // bounded number of turns, not a wall-clock deadline that a loaded
    // machine can miss.
    await _settle(h, () => h.bloc.state.retrieveActiveCall('b') == null);

    expect(h.bloc.state.retrieveActiveCall('b'), isNull);
    expect(h.bloc.state.conference.legs, {'a': 0});
    expect(h.bloc.state.conference.participants, [_participant('a', 0)]);
    expect(h.bloc.state.conference.phase, ConferencePhase.active, reason: 'the server says when the room is over');
  });

  test('a participant mute goes out only for a listed participant', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    h.bloc.add(const CallControlEvent.conferenceParticipantMuted('a', true));
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<ConferenceMuteRequest>(), isEmpty, reason: 'not listed yet');

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    h.bloc.add(const CallControlEvent.conferenceParticipantMuted('a', true));
    await pumpEventQueue();

    final mute = h.signaling.requests.whereType<ConferenceMuteRequest>().single;
    expect((mute.line, mute.muted), (0, true));
    expect(h.bloc.state.conference.participantMuted('a'), isFalse, reason: 'the list says when it took effect');
  });

  test('self mute takes the microphone off the room and leaves the microphone itself alone', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;

    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();

    expect(h.bloc.state.conference.selfMuted, isTrue);
    expect(mixer.fakeSenders.single.track, isNull, reason: 'the room hears nothing');
    // The microphone is one object for every call: muting the room must not
    // switch off the track the other calls are holding.
    expect(h.media.microphone.enabled, isTrue);

    h.bloc.add(const CallControlEvent.conferenceSelfMuted(false));
    await pumpEventQueue();
    expect(mixer.fakeSenders.single.track, isNotNull);
  });

  test('muting a call outside the room reaches that call alone', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    final outside = h.seedEstablishedCall('outside', line: 2);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;
    // A call outside the room stands, so the room is aside for it - see
    // conference_outside_call_test.dart. What is asserted here is that a mute
    // of that call does not reach anything else through the shared track.
    await _settle(h, () => mixer.fakeSenders.single.track == null);

    await h.bloc.performSetMuted('outside', true);
    await pumpEventQueue();

    expect(outside.fakeSenders.single.track, isNull);
    expect(h.media.microphone.enabled, isTrue, reason: 'the one track every call holds stays live');
    expect(h.bloc.state.conference.selfMuted, isFalse, reason: 'muting a call is not muting the room');
  });

  test('ending the conference leaves a muted call outside it muted', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    final outside = h.seedEstablishedCall('outside', line: 2);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    await h.bloc.performSetMuted('outside', true);
    await pumpEventQueue();

    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('outside')!.muted, isTrue);
    expect(outside.fakeSenders.single.track, isNull, reason: 'the room ending must not open a muted microphone');
  });

  test('a leg leaving the room while the host is self-muted keeps the room silent', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    h.seedEstablishedCall('c', line: 2);
    await _merge(h, ['a', 'b', 'c']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1), _participant('c', 2)]);
    final mixer = h.peerFactory.created.single;
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();

    // Core dropped one leg; restoring its audio must not reach the room.
    h.signaling.emit(ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0), _participant('b', 1)]));
    await pumpEventQueue();

    expect(h.bloc.state.conference.selfMuted, isTrue);
    expect(mixer.fakeSenders.single.track, isNull, reason: 'the host is still muted towards the room');
  });

  test('an OS mute on a leg in the room keeps the flag for when it is a call again', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    await h.bloc.performSetMuted('a', true);
    await pumpEventQueue();
    expect(h.bloc.state.retrieveActiveCall('a')!.muted, isTrue);
    expect(h.media.microphone.enabled, isTrue, reason: 'the microphone is every call\'s, not this leg\'s');
    expect(a.fakeSenders.single.track, isNull, reason: 'the leg is quiet for the room either way');

    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();
    // The call comes back as the user left it: still muted, which now means
    // its own connection carries no microphone.
    expect(a.fakeSenders.single.track, isNull, reason: 'it comes back muted, as the OS was told');
  });

  test('a call added to a live room is quiet from the ack and listed by the server', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final c = h.seedEstablishedCall('c', line: 2, held: true);

    h.bloc.add(const CallControlEvent.conferenceAdded('c'));
    await pumpEventQueue();

    expect(h.signaling.requests.last, isA<ConferenceAddRequest>().having((r) => r.line, 'line', 2));
    expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1, 'c': 2});
    expect(_quiet(h, c, 'c'), isTrue);
    expect(h.bloc.state.conference.isReady('c'), isFalse);

    h.signaling.emit(
      ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0), _participant('b', 1), _participant('c', 2)]),
    );
    await pumpEventQueue();
    expect(h.bloc.state.conference.isReady('c'), isTrue);
    expect(h.bloc.state.retrieveActiveCall('c')!.held, isFalse);
    expect(h.callkeep.held, isEmpty, reason: 'the group carries it, not a hold change');
    expect(h.callkeep.groups.last.callIds, ['a', 'b', 'c']);
  });

  test('a room given up while it was being answered is not raised from the dead', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    // The answer is in flight when something else drops the room - a session
    // reset runs on its own event stream and does exactly this.
    final gate = Completer<void>();
    h.signaling.gate = gate;
    h.signaling.emit(ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0)]));
    await pumpEventQueue();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(h.bloc.state.copyWith(conference: const ConferenceState()));
    gate.complete();
    await pumpEventQueue();

    expect(h.bloc.state.conference, const ConferenceState(), reason: 'a room with no legs would be unclearable');
  });

  test('a mute the operating system reports for a leg mutes the room', () async {
    // The leg's own microphone left its connection when it joined, so there
    // is nothing there to silence; what the host speaks into is the room.
    // This is the entrypoint the OS uses, and it must reach the same place
    // the app's own control does.
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;

    await h.bloc.performSetMuted('a', true);
    await pumpEventQueue();

    expect(mixer.fakeSenders.single.track, isNull, reason: 'the room hears nothing');
    expect(h.bloc.state.conference.selfMuted, isTrue, reason: 'and the screen says so');
    expect(h.bloc.state.retrieveActiveCall('a')!.muted, isTrue);
    expect(a.fakeSenders.single.track, isNull);

    await h.bloc.performSetMuted('a', false);
    await pumpEventQueue();
    expect(mixer.fakeSenders.single.track, isNotNull);
    expect(h.bloc.state.conference.selfMuted, isFalse);
  });

  test('a participant the server adds without an acknowledgement is silenced all the same', () async {
    // The add timed out, or its ack was lost; the server counts the call in
    // the mix regardless, and a leg still talking on its own connection is
    // heard twice by everyone.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    final late = h.seedEstablishedCall('c', line: 2);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    expect(_restored(h, late, 'c'), isTrue, reason: 'it is an ordinary call so far');

    h.signaling.emit(
      ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0), _participant('b', 1), _participant('c', 2)]),
    );
    await pumpEventQueue();

    expect(h.bloc.state.conference.legs.containsKey('c'), isTrue);
    expect(_quiet(h, late, 'c'), isTrue, reason: 'membership and where its audio goes must agree');
  });

  test('hanging up another participant does not unmute the host', () async {
    // The platform keeps a mute state per call and re-publishes it unasked -
    // on the way out of a call, and on an audio-device change. Nothing in
    // that notice says whether a person asked for it.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;

    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();
    expect(mixer.fakeSenders.single.track, isNull);
    // Every leg was told, so what the platform has stored is the room's own.
    expect(h.callkeep.muted, [(callId: 'a', muted: true), (callId: 'b', muted: true)]);

    // Ending b re-publishes b's stored state before the call goes away.
    await h.bloc.performSetMuted('b', true);
    await pumpEventQueue();

    expect(mixer.fakeSenders.single.track, isNull, reason: 'the host did not ask to be heard again');
    expect(h.bloc.state.conference.selfMuted, isTrue);
  });

  test('a stale republication from a leg that never heard of the room is refused', () async {
    // The same notice, but carrying the value a leg would have had before the
    // room was muted: still not a person pressing anything.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;
    // Muted through the grid this time: it names one leg, not the room.
    await h.bloc.performSetMuted('a', true);
    await pumpEventQueue();
    expect(mixer.fakeSenders.single.track, isNull);

    h.callkeep.muted.clear();
    await h.bloc.performSetMuted('b', true);
    await pumpEventQueue();

    expect(mixer.fakeSenders.single.track, isNull);
    expect(h.bloc.state.conference.selfMuted, isTrue);
  });

  test('a genuine unmute from the operating system still reaches the room', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();

    // A person pressing unmute in the system call UI asks for the opposite of
    // what the room is, which is what tells it apart from a republication.
    await h.bloc.performSetMuted('a', false);
    await pumpEventQueue();

    expect(mixer.fakeSenders.single.track, isNotNull);
    expect(h.bloc.state.conference.selfMuted, isFalse);
  });

  test('a call added to a room the host has muted is told the room is muted', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    h.seedEstablishedCall('c', line: 2);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();
    h.callkeep.muted.clear();

    h.bloc.add(const CallControlEvent.conferenceAdded('c'));
    await pumpEventQueue();

    // Otherwise the first thing the platform repeats about c unmutes the room.
    expect(h.callkeep.muted, contains((callId: 'c', muted: true)));
  });

  test('a report overtaken by a later mute does not reopen the microphone', () async {
    // The platform does not wait for its report before the command returns, so
    // a report can still be travelling when the host asks for the opposite.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();

    h.callkeep.deferMuteReports = true;
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(false));
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();
    expect(mixer.fakeSenders.single.track, isNull, reason: 'the last thing the host asked for');

    // Now the first of the older reports arrives, carrying the value of a
    // command the host has already changed their mind about.
    await h.callkeep.flushMuteReports(count: 1);

    expect(mixer.fakeSenders.single.track, isNull, reason: 'an old report is not a new intent');
    expect(h.bloc.state.conference.selfMuted, isTrue);

    // And the rest of them leave it where the host put it.
    await h.callkeep.flushMuteReports();
    expect(mixer.fakeSenders.single.track, isNull);
    expect(h.bloc.state.conference.selfMuted, isTrue);
  });

  test('reports of our own commands do not breed more commands', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    h.callkeep.deferMuteReports = true;
    h.callkeep.muted.clear();

    h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.conferenceSelfMuted(false));
    await pumpEventQueue();
    final commandsBefore = h.callkeep.muted.length;
    await h.callkeep.flushMuteReports();

    // Each report answers one command and asks for nothing further; otherwise
    // the two feed each other for as long as the room lives.
    expect(h.callkeep.muted.length, commandsBefore, reason: 'no new commands came out of the reports');
    expect(h.callkeep.heldMuteReports, 0, reason: 'and nothing was left queued');
    expect(h.bloc.state.conference.selfMuted, isFalse);
  });

  test('a handshake arriving while the offer is answered keeps the room', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    final gate = Completer<void>();
    h.signaling.gate = gate;
    h.signaling.emit(
      ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
    );
    await pumpEventQueue();

    // The handshake handler runs outside every queue and decides what this
    // client holds from the room id in the state.
    h.signaling.emitHandshake(
      StateHandshake(
        keepaliveInterval: const Duration(seconds: 30),
        timestamp: 0,
        registration: const Registration(status: RegistrationStatus.registered),
        lines: const [],
        presenceInfos: const [],
        dialogInfos: const [],
        guestLine: null,
        conference: const ConferenceInfo(room: 7),
      ),
    );
    gate.complete();
    await pumpEventQueue();

    expect(
      h.signaling.requests.whereType<ConferenceHangupRequest>(),
      isEmpty,
      reason: 'the client would have hung up the room it was joining',
    );
    expect(h.bloc.state.conference.room, 7);
  });

  test('a handshake arriving while a leg is taken off hold keeps the room', () async {
    // Taking a participant off hold is a native round trip, and the handshake
    // handler runs outside every queue: it decides what this client holds by
    // the room id in the state.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1, held: true);
    await _merge(h, ['a', 'b']);

    final gate = Completer<void>();
    h.callkeep.holdGate = gate;
    h.signaling.emit(
      ConferenceOfferEvent(room: 7, jsep: _offer, participants: [_participant('a', 0), _participant('b', 1)]),
    );
    await pumpEventQueue();

    h.signaling.emitHandshake(
      StateHandshake(
        keepaliveInterval: const Duration(seconds: 30),
        timestamp: 0,
        registration: const Registration(status: RegistrationStatus.registered),
        lines: const [],
        presenceInfos: const [],
        dialogInfos: const [],
        guestLine: null,
        conference: const ConferenceInfo(room: 7),
      ),
    );
    // Let the handshake be planned and acted on while the hold is still in
    // flight; that window is the whole point of this test.
    await pumpEventQueue();
    gate.complete();
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
    expect(h.bloc.state.conference.room, 7);
  });

  test('a participant list for another room is not adopted', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.signaling.emit(ConferenceUpdatedEvent(room: 99, participants: [_participant('a', 0)]));
    await pumpEventQueue();

    expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1}, reason: 'another room says nothing about this one');
    expect(h.callkeep.held, isEmpty);
  });

  test('a merge that fails leaves one call live, even one that was held before it', () async {
    // Two calls means one of them is held, so this is the ordinary shape of
    // a merge. Nothing un-held it: the room never formed, so the server
    // never did, and a client that only added holds left both held and the
    // user listening to silence.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0, held: true);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    h.signaling.emit(const ConferenceFailedEvent(reason: 'video_not_supported'));
    await pumpEventQueue();

    expect(h.callkeep.held, contains((callId: 'a', onHold: false)), reason: 'the held leg is brought back');
    expect(h.callkeep.held, contains((callId: 'b', onHold: true)));
  });

  test('a mixer connection that fails gives the calls back', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    final mixer = h.peerFactory.created.single;

    // Nobody re-offers a room, so there is nothing to recover: the calls are
    // handed back rather than left in a room that carries silence.
    mixer.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
    mixer.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
    await pumpEventQueue();

    expect(h.bloc.state.conference, const ConferenceState());
    expect(_restored(h, a, 'a'), isTrue);
    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.notifications.single, isA<ConferenceEndedNotification>());
  });

  group('rejoin after the mixer connection is lost', () {
    test('the room is kept and the server is asked for its offer again', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      final before = h.bloc.state.conference;

      await _failMixer(room.mixer);

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(1));
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
      expect(h.bloc.state.conference, before.copyWith(phase: ConferencePhase.rejoining));
      expect(room.mixer.closes, 1, reason: 'the dead connection is closed');
      expect(_quiet(h, room.a, 'a'), isTrue, reason: 'the legs stay in the mix, not handed back');
      expect(h.notifications, isEmpty);
      expect(h.callkeep.held, isEmpty);
    });

    test('the new offer for the same room is answered on a fresh connection', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      final answersBefore = h.signaling.requests.whereType<ConferenceAnswerRequest>().length;

      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.bloc.state.conference.phase == ConferencePhase.active);

      expect(h.bloc.state.conference.phase, ConferencePhase.active);
      expect(h.peerFactory.created, hasLength(2));
      expect(h.peerFactory.created.last.remoteDescriptions.single.type, 'offer');
      expect(h.signaling.requests.whereType<ConferenceAnswerRequest>(), hasLength(answersBefore + 1));
      expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1});
      expect(_quiet(h, room.a, 'a'), isTrue);
      expect(h.notifications, isEmpty);
    });

    test('the host\'s mute is carried into the new connection', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
      await pumpEventQueue();
      await _failMixer(room.mixer);

      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.bloc.state.conference.phase == ConferencePhase.active);

      expect(h.bloc.state.conference.selfMuted, isTrue);
      expect(h.peerFactory.created.last.fakeSenders.single.track, isNull);
    });

    test('a candidate of the dead connection is not trickled', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      final gathering = room.mixer.onIceCandidate!;
      await _failMixer(room.mixer);
      final before = h.signaling.requests.whereType<ConferenceIceTrickleRequest>().length;

      gathering(RTCIceCandidate('candidate:stale', '0', 0));
      await pumpEventQueue();

      expect(h.signaling.requests.whereType<ConferenceIceTrickleRequest>(), hasLength(before));
    });

    test('a refused rejoin gives the calls back', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'no_conference');

      await _failMixer(room.mixer);
      h.signaling.failure = null;
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
      expect(h.notifications.single, isA<ConferenceEndedNotification>());
    });

    test('a rejoin refused because an offer is already on its way waits for it, under the deadline', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'conference_not_established');

      await _failMixer(room.mixer);
      h.signaling.failure = null;
      await pumpEventQueue();

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(h.notifications, isEmpty);

      // The offer it promised never comes: the wait has an end all the same.
      expect(deadline.isArmed, isTrue);
      deadline.pass();
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
    });

    test('a rejoin lost with the socket is an outage, not an error', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      // The request is on its way when the socket closes under it.
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _failMixer(room.mixer);
      expect(deadline.isArmed, isTrue, reason: 'the deadline starts with the request, not with its answer');
      await _loseSession(h);
      h.signaling.failure = const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 1006, null);
      inFlight.complete();
      h.signaling.gate = null;
      await pumpEventQueue();
      h.signaling.failure = null;

      expect(h.errors.errors, isEmpty);
      expect(deadline.isArmed, isFalse, reason: 'a request that never got there brings no offer to wait for');
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining, reason: 'the next handshake asks again');
      expect(_quiet(h, room.a, 'a'), isTrue);
    });

    test('the session going takes the wait for its offer with it, deadline included', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(1));
      expect(deadline.isArmed, isTrue);

      // The request was taken, and then the socket dropped before the offer.
      await _loseSession(h);

      expect(deadline.isArmed, isFalse);

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining, reason: 'a dead session owes no offer');
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
      expect(_quiet(h, room.a, 'a'), isTrue);
    });

    test('a rejoin that could not be sent on a session that is up is ended by the deadline', () async {
      // Nothing will ask again - the session is there, so no handshake comes -
      // and nothing says so either: the deadline that started with the
      // request is what ends the wait.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.signaling.failure = StateError('the request could not be encoded');

      await _failMixer(room.mixer);
      h.signaling.failure = null;
      await pumpEventQueue();
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(deadline.isArmed, isTrue);

      deadline.pass();
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
    });

    test('an answer the lost session reports as sent does not put the host in the room', () async {
      // The request queue answers a request it could not send on a session
      // that went meanwhile as if it had been sent. That acknowledgement is
      // the lost session's: the room is not active, and the next session asks.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      h.signaling.gate = null;
      await _loseSession(h);

      inFlight.complete();
      await pumpEventQueue();

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining, reason: 'the answer never left');
      expect(deadline.isArmed, isFalse);

      h.signaling.connected = true;
      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(2));
      expect(deadline.isArmed, isTrue);
    });

    test('a rejoin that failed with the old session does not end the room on the new one', () async {
      // The old request's failure is handled when the next session is already
      // up. Judged by the connection of that moment it would read as "could
      // not be sent on a live session" and end the room.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _failMixer(room.mixer);
      h.signaling.gate = null;
      await _loseSession(h);
      h.signaling.connected = true;

      h.signaling.failure = const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 1006, null);
      inFlight.complete();
      await pumpEventQueue();
      h.signaling.failure = null;

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
      expect(h.notifications, isEmpty);
      expect(_quiet(h, room.a, 'a'), isTrue);

      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(2));
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
    });

    test('a refusal that comes back from the old session does not end the room on the new one', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _failMixer(room.mixer);
      h.signaling.gate = null;
      await _loseSession(h);
      h.signaling.connected = true;
      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'no_conference');
      inFlight.complete();
      await pumpEventQueue();
      h.signaling.failure = null;

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(_quiet(h, room.a, 'a'), isTrue);
    });

    test('an answer that went with the session keeps the room, and the next session asks again', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);

      // The new offer arrives and the answer is on its way when the socket drops.
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      final answering = h.peerFactory.created.last;
      await _loseSession(h);
      h.signaling.failure = const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 1006, null);
      inFlight.complete();
      h.signaling.gate = null;
      await pumpEventQueue();
      h.signaling.failure = null;

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining, reason: 'not a failure to join');
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
      expect(h.notifications, isEmpty);
      expect(_quiet(h, room.a, 'a'), isTrue);

      // The session comes back, with the room still standing.
      h.signaling.connected = true;
      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(2));
      expect(answering.closes, 1, reason: 'the connection made for the lost answer is let go of');
      expect(deadline.isArmed, isTrue);

      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.bloc.state.conference.phase == ConferencePhase.active);
      expect(h.bloc.state.conference.phase, ConferencePhase.active);
      expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1});
    });

    test('an answer overtaken by a new request does not put the host in the room', () async {
      // The answer is acknowledged, but by then the next session has been
      // asked and the server is moving the host onto another handle.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      final inFlight = Completer<void>();
      h.signaling.gate = inFlight;
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      h.signaling.gate = null;
      await _loseSession(h);
      h.signaling.connected = true;
      h.signaling.emitHandshake(_handshakeWithRoom());
      await pumpEventQueue();

      inFlight.complete();
      await pumpEventQueue();

      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(deadline.isArmed, isTrue, reason: 'the offer of the new request is still awaited');
      expect(_quiet(h, room.a, 'a'), isTrue);
    });

    test('a reset of the calls takes the wait with the room', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      expect(deadline.isArmed, isTrue);

      // The registration is lost: every call is completed and the room dropped.
      h.signaling.emit(UnregisteredEvent());
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(deadline.isArmed, isFalse);
      deadline.pass();
      await pumpEventQueue();
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty, reason: 'nothing is overdue');
    });

    test('an offer that arrives twice replaces the connection instead of reusing it', () async {
      // Two rejoins that both reached the server: it moves the host onto a
      // new handle for each, and the second offer is from the second handle.
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.bloc.state.conference.phase == ConferencePhase.active);
      final second = h.peerFactory.created.last;

      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.peerFactory.created.length == 3);

      expect(h.peerFactory.created, hasLength(3));
      expect(second.closes, 1);
      expect(h.peerFactory.created.last.remoteDescriptions, hasLength(1));
      expect(h.bloc.state.conference.phase, ConferencePhase.active);
      expect(h.notifications, isEmpty);
    });

    test('an offer that never follows the rejoin gives the calls back', () async {
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(deadline.isArmed, isTrue);

      deadline.pass();
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
      expect(h.notifications.single, isA<ConferenceEndedNotification>());
    });

    test('a rejoin the server never answered is given the deadline too', () async {
      // Whether it was taken is unknown, and the session may be up: with no
      // deadline nothing would end the wait.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.signaling.failure = const WebtritSignalingTransactionTimeoutException(1, 'tx');

      await _failMixer(room.mixer);
      h.signaling.failure = null;
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining);
      expect(deadline.isArmed, isTrue);
      deadline.pass();
      await _settle(h, () => !h.bloc.state.conference.isPresent);

      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
    });

    test('with the session down the room waits for the handshake instead of a deadline', () async {
      // The module itself would take the request and keep it for the next
      // session - where it would go out next to the one the handshake sends.
      // So a session that is down is not handed it at all.
      final deadline = ManualOfferDeadline();
      final h = _rejoinHarness(deadline: deadline);
      addTearDown(h.close);
      final room = await _roomUp(h);
      h.signaling.connected = false;

      await _failMixer(room.mixer);
      await pumpEventQueue();

      expect(deadline.isArmed, isFalse);
      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), isEmpty);
      expect(h.bloc.state.conference.phase, ConferencePhase.rejoining, reason: 'nothing was asked, nothing is overdue');
      expect(_quiet(h, room.a, 'a'), isTrue);
    });

    test('a server without the request ends the room as before', () async {
      final h = _harness();
      addTearDown(h.close);
      final room = await _roomUp(h);

      await _failMixer(room.mixer);

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), isEmpty);
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
      expect(h.notifications.single, isA<ConferenceEndedNotification>());
    });

    test('a connection that never reached the mixer is not asked for again', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final a = h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      await _merge(h, ['a', 'b']);
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

      await _failMixer(h.peerFactory.created.single);

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), isEmpty);
      expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, a, 'a'), isTrue);
    });

    test('a second connection that never comes up ends the room', () async {
      final h = _rejoinHarness();
      addTearDown(h.close);
      final room = await _roomUp(h);
      await _failMixer(room.mixer);
      await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
      await _settle(h, () => h.bloc.state.conference.phase == ConferencePhase.active);

      await _failMixer(h.peerFactory.created.last);

      expect(h.signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(1));
      expect(h.bloc.state.conference, const ConferenceState());
      expect(_restored(h, room.a, 'a'), isTrue);
    });
  });

  test('a room that never arrives gives the calls back on a deadline of our own', () async {
    // The legs are quiet from the acknowledgement. The server has a deadline
    // and announces it, but it announces it as an event, and a socket that
    // drops in between takes that word with it.
    final deadline = ManualOfferDeadline();
    final h = CallBlocHarness(
      capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
      offerDeadline: deadline,
    );
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    expect(_quiet(h, a, 'a'), isTrue);

    expect(deadline.isArmed, isTrue);
    deadline.pass();
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    expect(h.bloc.state.conference, const ConferenceState());
    expect(_restored(h, a, 'a'), isTrue, reason: 'the calls do not stay silent waiting for a room');
  });

  test('a participant this client has no call for does not become a leg', () async {
    // The server can still list a call this client has already let go - a
    // hangup it has not processed yet. A leg with nothing behind it shows a
    // nameless row with dead controls and puts a call id the OS does not
    // know into the group, which fails the grouping for the others too.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1), _participant('ghost', 2)]);

    expect(h.bloc.state.conference.legs, {'a': 0, 'b': 1});
    expect(h.callkeep.groups.single.callIds, ['a', 'b']);
    expect(h.bloc.state.conference.participants, hasLength(3), reason: 'the list stays the server\'s own');
  });

  test('a merge that never reached the server does not quiet the legs', () async {
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    h.signaling.connected = false;
    h.signaling.sendable = false;

    await _merge(h, ['a', 'b']);

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(a.fakeSenders.single.track, isNotNull, reason: 'the calls carry on as calls');
  });

  test('a room offered after the client gave it up is hung up', () async {
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);

    await _offerRoom(h, 7, [_participant('a', 0)]);

    expect(h.signaling.requests.single, isA<ConferenceHangupRequest>());
    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(h.peerFactory.created, isEmpty);
  });

  test('a terminal event for another room leaves this one alone', () async {
    // The server names the room its terminal events are about. One naming a
    // room this client is not in describes somebody else's end, and acting
    // on it would drop a live room and silence nothing back.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.signaling.emit(const ConferenceTerminatedEvent(room: 6));
    h.signaling.emit(const ConferenceFailedEvent(room: 6, reason: 'video_not_supported'));
    await pumpEventQueue();

    expect(h.bloc.state.conference.room, 7);
    expect(h.bloc.state.conference.phase, ConferencePhase.active);
    expect(h.notifications, isEmpty);
  });

  test('an answer that never left does not put the host in the room', () async {
    // A session that cannot carry the answer leaves the server waiting and
    // the legs silent. Reading it as a room would hide that for good: the
    // deadline is cancelled the moment the room counts as joined.
    final h = _harness();
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    h.signaling.sendable = false;

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(_restored(h, a, 'a'), isTrue, reason: 'the calls do not stay silent for a room nobody joined');
    expect(h.notifications.single, isA<ConferenceFailedNotification>());
  });

  test('the deadline gives the calls back while the answer is still in flight', () async {
    // Answering is a media round trip and then a request. Held inside the
    // mutation queue it would block the very deadline that exists to end
    // this wait, and the legs would stay silent for as long as it took.
    final deadline = ManualOfferDeadline();
    final h = CallBlocHarness(
      capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
      offerDeadline: deadline,
    );
    addTearDown(h.close);
    final a = h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    final stalled = Completer<void>();
    h.signaling.gate = stalled;

    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    deadline.pass();
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(_restored(h, a, 'a'), isTrue);

    // The answer arrives after the room was given up: it must not raise it.
    stalled.complete();
    h.signaling.gate = null;
    await _settle(h, () => false);
    expect(h.bloc.state.conference.isPresent, isFalse);
  });

  test('an answer for a room already given up does not join the next one', () async {
    // The state alone cannot tell: a room being assembled has no id yet, so
    // an answer naming the old room looks like it could be about this one.
    // What tells them apart is which attempt asked for it.
    //
    // The deadline is in the test's hands: it passes for the first room and
    // never for the second, which a clock on a busy machine could not promise.
    final deadline = ManualOfferDeadline();
    final h = CallBlocHarness(
      capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
      offerDeadline: deadline,
    );
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    final stalled = Completer<void>();
    h.signaling.gate = stalled;
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);
    deadline.pass();
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    // A second merge is under way when the first room's answer finally goes.
    h.signaling.gate = null;
    await _merge(h, ['a', 'b']);
    expect(h.bloc.state.conference.phase, ConferencePhase.assembling);
    expect(h.bloc.state.conference.room, isNull, reason: 'the offer for this one has not arrived');

    stalled.complete();
    await _settle(h, () => false);

    expect(h.bloc.state.conference.phase, ConferencePhase.assembling, reason: 'room 7 is not this room');
  });

  test('a participant is told when the room mutes them, and when it stops', () async {
    // The server tells a muted participant nothing, so their own client
    // would show a live microphone while nobody hears them.
    final h = _harness(peerMessages: true);
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    h.signaling.emit(
      ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0, muted: true), _participant('b', 1)]),
    );
    await pumpEventQueue();

    final told = h.signaling.requests.whereType<ConferenceMutePeerMessageRequest>().toList();
    expect(told.single.callId, 'a');
    expect(told.single.muted, isTrue);
    expect(told.single.line, 0, reason: 'the server names a leg by line');

    h.signaling.emit(ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0), _participant('b', 1)]));
    await pumpEventQueue();

    final again = h.signaling.requests.whereType<ConferenceMutePeerMessageRequest>().toList();
    expect(again.length, 2, reason: 'only the change is sent, not the whole list each time');
    expect(again.last.muted, isFalse);
  });

  test('a room that ends mutes nobody, and says so', () async {
    final h = _harness(peerMessages: true);
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0, muted: true), _participant('b', 1)]);
    expect(h.signaling.requests.whereType<ConferenceMutePeerMessageRequest>().single.muted, isTrue);

    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await _settle(h, () => !h.bloc.state.conference.isPresent);

    final told = h.signaling.requests.whereType<ConferenceMutePeerMessageRequest>().toList();
    expect(told.last.callId, 'a');
    expect(told.last.muted, isFalse);
  });

  test('a core that does not take peer messages is told nothing', () async {
    // An older core closes the signaling socket with 4600 on a request it
    // does not know: the hint is not worth the session the room is in.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0, muted: true), _participant('b', 1)]);

    expect(h.signaling.requests.whereType<ConferenceMutePeerMessageRequest>(), isEmpty);
  });

  test('what the other side says about a mute is recorded on that call alone', () async {
    // The receiving side has no room of its own to check this against: it is
    // a claim about this call, kept as one.
    final h = _harness();
    addTearDown(h.close);
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);

    h.signaling.emit(const ConferenceMutePeerMessageEvent(line: 0, callId: 'a', muted: true));
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('a')!.peerReportedConferenceMute, isTrue);
    expect(h.bloc.state.retrieveActiveCall('b')!.peerReportedConferenceMute, isNull);
    expect(h.bloc.state.conference, const ConferenceState(), reason: 'no room is invented from a claim');
  });

  test('closing the bloc with a room up returns the microphone', () async {
    final h = _harness();
    h.seedEstablishedCall('a', line: 0);
    h.seedEstablishedCall('b', line: 1);
    await _merge(h, ['a', 'b']);
    await _offerRoom(h, 7, [_participant('a', 0), _participant('b', 1)]);

    await h.close();

    expect(h.peerFactory.created.single.closes, 1);
    expect(h.media.released, contains(h.media.built.last));
  });
}

/// Holds the room's microphone request open, so something can arrive while the
/// room is still answering the mixer.
class _GatedMedia extends Fake implements UserMediaBuilder {
  _GatedMedia(this._gate);

  final Completer<void> _gate;
  final _inner = FakeUserMediaBuilder();

  bool pending = false;

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    pending = true;
    await _gate.future;
    pending = false;
    return _inner.build(video: video, frontCamera: frontCamera, allowAudioFallback: allowAudioFallback);
  }

  @override
  Future<void> release(MediaStream stream) => _inner.release(stream);
}
