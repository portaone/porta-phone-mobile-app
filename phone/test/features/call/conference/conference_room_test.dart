import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/conference/conference_room.dart';
import 'package:webtrit_phone/features/call/conference/conference_room_ports.dart';
import 'package:webtrit_phone/features/call/models/active_call.dart';
import 'package:webtrit_phone/features/call/models/call_audio.dart';
import 'package:webtrit_phone/features/call/models/call_transition.dart';
import 'package:webtrit_phone/features/call/models/conference_membership_plan.dart';
import 'package:webtrit_phone/features/call/models/conference_state.dart';
import 'package:webtrit_phone/features/call/models/invited_conference_video.dart';
import 'package:webtrit_phone/features/call/models/jsep_value.dart';
import 'package:webtrit_phone/features/call/models/processing_status.dart';
import 'package:webtrit_phone/features/call/services/call_signaling.dart';
import 'package:webtrit_phone/models/call_direction.dart';
import 'package:webtrit_phone/models/feature_access/call_config.dart';
import 'package:webtrit_phone/models/feature_access/encoding_config.dart';

import '../bloc/call_bloc_harness.dart';

/// The conference room with its owner stood in for: what it is given are
/// plain values and fakes. It imports the room's own files; the fakes come
/// from the bloc's harness, where every call test finds them. How the room behaves inside CallBloc, with real
/// calls around it, is in conference_flow_test.dart and its neighbours.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};

ActiveCall _call(String callId, int line) => ActiveCall(
  direction: CallDirection.outgoing,
  line: line,
  callId: callId,
  handle: const CallkeepHandle.number('100'),
  createdTime: DateTime(2026),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2026),
);

/// The owner's calls and state, as far as the room asks.
class _Calls implements ConferenceCalls {
  final Map<String, ActiveCall> byId = {};

  final List<({String callId, CallAudio audio})> audio = [];
  final List<String> restored = [];
  String? codec = 'opus';
  bool onAnotherCall = false;

  /// The calls the server is said to take off hold as they join.
  Set<String> serverUnheld = {};

  /// The mute changes the server's list is said to bring.
  Map<String, bool> muteChanges = {};

  @override
  ConferenceState conference = const ConferenceState();

  @override
  ActiveCall? call(String callId) => byId[callId];

  @override
  String? focusedCallId;

  @override
  bool get canMerge => byId.length >= 2;

  @override
  Map<String, int> mergeableLegs(Iterable<String> callIds) => {
    for (final callId in callIds)
      if (byId[callId]?.line case final line? when !conference.isLeg(callId)) callId: line,
  };

  @override
  ConferenceMembershipPlan membershipFrom(List<ConferenceParticipant> participants) => ConferenceMembershipPlan(
    legs: {for (final participant in participants) participant.callId: participant.line},
    adopted: [
      for (final participant in participants)
        if (!conference.isLeg(participant.callId)) participant.callId,
    ],
    vanished: [
      for (final callId in conference.legIds)
        if (!participants.any((participant) => participant.callId == callId)) callId,
    ],
    unheld: [
      for (final participant in participants)
        if (serverUnheld.contains(participant.callId)) participant.callId,
    ],
    muteChanges: muteChanges,
  );

  @override
  bool get hostIsOnAnotherCall => onAnotherCall;

  @override
  Future<bool> restoreAudio(String callId) async {
    restored.add(callId);
    return byId.containsKey(callId);
  }

  @override
  Future<bool> applyAudio(String callId, CallAudio wanted) async {
    audio.add((callId: callId, audio: wanted));
    return byId.containsKey(callId);
  }

  @override
  Future<String?> audioCodecInUse(String callId) async => codec;

  @override
  Iterable<ActiveCall> get all => byId.values;
}

void main() {
  late _Calls calls;
  late FakeSignalingModule signaling;
  late FakeCallkeep callkeep;
  late List<ConferenceNotice> notifications;
  late List<ConferenceCommand> commands;
  late List<ConferenceStep> steps;
  late List<ConferenceUpdate> updates;
  late ManualOfferDeadline deadline;
  InvitedConferenceVideo? invited;
  late ConferenceRoom room;

  /// The owner's side of a write: the room's part of it lands in the state
  /// the room reads back.
  void write(ConferenceUpdate update) {
    updates.add(update);
    if (update.conference case final conference?) calls.conference = conference;
    for (final callId in update.unheld) {
      final call = calls.byId[callId];
      if (call != null) calls.byId[callId] = call.copyWith(held: false);
    }
    if (update.invitedVideo case (:final value)) invited = value;
    for (final entry in update.transitions.entries) {
      final call = calls.byId[entry.key];
      if (call != null) calls.byId[entry.key] = call.copyWith(transition: entry.value);
    }
  }

  /// The room under test; [video] where the server's rooms carry video.
  ConferenceRoom newRoom({bool video = false}) => ConferenceRoom(
    calls: calls,
    signaling: ModuleCallSignaling(signaling, events: const Stream.empty()),
    callkeep: callkeep,
    capabilities: CallCapabilitiesConfig(
      isConferenceEnabled: true,
      isConferenceRejoinEnabled: true,
      isPeerMessageEnabled: true,
      isConferenceVideoEnabled: video,
    ),
    onCommand: commands.add,
    onStep: steps.add,
    onNotice: notifications.add,
    onError: RecordingCallErrorReporter().handle,
    factory: FakePeerConnectionFactory(),
    userMediaBuilder: FakeUserMediaBuilder(),
    assemblyTimeout: const Duration(seconds: 30),
    offerDeadlineTimer: deadline.createTimer,
    audioCodecs: EncodingConfig.defaultConferenceAudioCodecs,
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    calls = _Calls()
      ..byId['a'] = _call('a', 0)
      ..byId['b'] = _call('b', 1);
    signaling = FakeSignalingModule();
    callkeep = FakeCallkeep();
    notifications = [];
    commands = [];
    steps = [];
    updates = [];
    deadline = ManualOfferDeadline();
    invited = null;
    room = newRoom();
  });

  tearDown(() async {
    room.dispose();
    await room.teardown();
  });

  Future<void> merged() async {
    await room.merge(['a', 'b'], write, source: 'test');
    await room.onOffer(
      room: 7,
      jsep: JsepValue(_offer),
      participants: const [
        ConferenceParticipant(line: 0, callId: 'a'),
        ConferenceParticipant(line: 1, callId: 'b'),
      ],
      write: write,
    );
    await pumpEventQueue();
  }

  test('a merge the server takes quiets the legs and records the room as assembling', () async {
    expect(await room.merge(['a', 'b'], write, source: 'test'), isTrue);

    expect(signaling.requests.whereType<MergeRequest>().single.lines, [0, 1]);
    expect(calls.audio.map((it) => it.callId), ['a', 'b']);
    expect(calls.audio.map((it) => it.audio), everyElement(const CallAudio.silent()));
    expect(calls.conference.phase, ConferencePhase.assembling);
    expect(calls.conference.legs, {'a': 0, 'b': 1});
  });

  test('a merge the server refuses changes nothing and says why', () async {
    signaling.failure = const SignalingErrorException(1, 0, 'conference_already_active');

    await room.merge(['a', 'b'], write, source: 'test');

    expect(calls.conference.isPresent, isFalse);
    expect(calls.audio, isEmpty);
    expect(
      notifications.single,
      isA<RoomRefusedNotice>().having((notice) => notice.reason, 'reason', 'conference_already_active'),
    );
  });

  test('the answer to the room\'s offer comes back as a step of the room, for the owner\'s queue', () async {
    await merged();

    expect(calls.conference.room, 7);
    expect(signaling.requests.whereType<ConferenceAnswerRequest>(), hasLength(1));
    final answered = steps.whereType<AnswerTakenStep>().single;
    expect(answered.room, 7);

    await room.takeStep(answered, write);
    expect(calls.conference.phase, ConferencePhase.active);
  });

  test('ending the room asks the owner to end every leg, and hangs the room up', () async {
    await merged();

    await room.end(CallkeepEndedBy.user, write);
    await pumpEventQueue();

    expect(commands.whereType<EndLegCommand>().map((command) => command.callId), ['a', 'b']);
    expect(signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(calls.conference.isPresent, isFalse);
    expect(callkeep.ungroups.single, ['a', 'b']);
  });

  test('a room the server ends hands the legs back: one carries on, the other is held', () async {
    await merged();
    calls.focusedCallId = 'b';

    await room.onTerminated(room: 7, write: write);

    expect(calls.conference.isPresent, isFalse);
    final holds = {for (final command in commands.whereType<SetLegHeldCommand>()) command.callId: command.held};
    expect(holds, {'a': true, 'b': false});
    expect(notifications.whereType<RoomEndedNotice>(), hasLength(1));
  });

  test('a mixer connection that fails after it carried the room asks the server for a way back', () async {
    await merged();
    final answered = steps.whereType<AnswerTakenStep>().single;
    await room.takeStep(answered, write);

    await room.takeStep(const MixerFailedStep(hadConnected: true), write);
    await pumpEventQueue();

    expect(calls.conference.phase, ConferencePhase.rejoining);
    expect(signaling.requests.whereType<ConferenceRejoinRequest>(), hasLength(1));
  });

  test('one that never came up gives the room up through the owner\'s queue', () async {
    await merged();

    await room.takeStep(const MixerFailedStep(hadConnected: false), write);

    expect(steps.whereType<RoomGivenUpStep>(), hasLength(1));
    expect(signaling.requests.whereType<ConferenceRejoinRequest>(), isEmpty);
  });

  group('the server\'s list drops a leg', () {
    const onlyA = [ConferenceParticipant(line: 0, callId: 'a')];

    test('with the host in the room: it is leaving, gets its audio back and is held', () async {
      await merged();
      updates.clear();

      await room.onParticipants(room: 7, participants: onlyA, write: write);

      expect(updates.first.transitions, {'b': CallTransition.leavingRoom});
      expect(updates.first.settleFocus, isTrue);
      expect(calls.conference.legs, {'a': 0});
      expect(calls.restored, ['b']);
      expect(commands.whereType<SetLegHeldCommand>().map((command) => (command.callId, command.held)), [('b', true)]);
    });

    test('with the host on a call outside the room: it is released silent, and held all the same', () async {
      await merged();
      calls.onAnotherCall = true;
      updates.clear();

      await room.onParticipants(room: 7, participants: onlyA, write: write);

      expect(updates.first.transitions, {'b': CallTransition.releasedFromRoom});
      expect(calls.restored, isEmpty);
      expect(commands.whereType<SetLegHeldCommand>().map((command) => (command.callId, command.held)), [('b', true)]);
    });
  });

  test('a room that ends with the host on another call hands every leg back held', () async {
    await merged();
    calls
      ..focusedCallId = 'b'
      ..onAnotherCall = true;

    await room.onTerminated(room: 7, write: write);

    final holds = {for (final command in commands.whereType<SetLegHeldCommand>()) command.callId: command.held};
    expect(holds, {'a': true, 'b': true});
  });

  test('a call added to the room is asked of the server by its line and quieted', () async {
    await merged();
    calls.byId['c'] = _call('c', 2);
    calls.audio.clear();

    expect(await room.addCall('c', write, source: 'test'), isTrue);

    expect(signaling.requests.whereType<ConferenceAddRequest>().single.line, 2);
    expect(calls.audio.single, (callId: 'c', audio: const CallAudio.silent()));
  });

  test('calls off the conference codecs are renegotiated first, and the merge is asked again after', () async {
    calls.codec = 'PCMA';

    expect(await room.merge(['a', 'b'], write, source: 'test'), isFalse);

    expect(signaling.requests.whereType<MergeRequest>(), isEmpty);
    expect(commands.whereType<RenegotiateLegCommand>().map((command) => command.callId), ['a', 'b']);
    expect(room.legNegotiation.moves('a'), isTrue);

    calls.codec = 'opus';
    for (final callId in ['a', 'b']) {
      room.legNegotiation
        ..offerSent(callId)
        ..acknowledged(callId)
        ..answerApplied(callId);
    }

    expect(commands.whereType<RetryMergeCommand>().single.callIds, ['a', 'b']);
  });

  test('the room standing aside is said to every leg, once', () async {
    await merged();
    signaling.requests.clear();

    room.planAudio(const CallAudio.silent(), calls.conference.legIds);
    room.planAudio(const CallAudio.silent(), calls.conference.legIds);
    await pumpEventQueue();

    expect(signaling.requests.whereType<ConferenceHostAwayPeerMessageRequest>(), hasLength(2));
  });

  test('a room whose offer never comes is given up through the owner\'s queue', () async {
    await room.merge(['a', 'b'], write, source: 'test');

    deadline.pass();

    expect(steps.whereType<RoomGivenUpStep>(), hasLength(1));
  });

  test('a deadline that passes after the owner closed is nobody\'s', () async {
    // The owner closes while the merge is on its way: its ack still arrives,
    // and arms a deadline the closed owner no longer cancels.
    signaling.gate = Completer<void>();
    final merging = room.merge(['a', 'b'], write, source: 'test');
    await pumpEventQueue();
    room.dispose();
    signaling.gate!.complete();
    await merging;
    expect(deadline.isArmed, isTrue);

    deadline.pass();

    expect(steps, isEmpty);
  });

  test('a room that is forgotten is gone from the state, and the server is not told', () async {
    await merged();
    signaling.requests.clear();

    await room.forget(write);

    expect(calls.conference.isPresent, isFalse);
    expect(signaling.requests, isEmpty);
    expect(commands, isEmpty);
  });

  test('a call the server lists as it joins is quieted, and taken off hold with the same change', () async {
    await merged();
    calls.byId['c'] = _call('c', 2).copyWith(held: true);
    calls
      ..audio.clear()
      ..serverUnheld = {'c'};
    updates.clear();

    await room.onParticipants(
      room: 7,
      participants: const [
        ConferenceParticipant(line: 0, callId: 'a'),
        ConferenceParticipant(line: 1, callId: 'b'),
        ConferenceParticipant(line: 2, callId: 'c'),
      ],
      write: write,
    );

    expect(updates.first.unheld, {'c'});
    expect(updates.first.settleFocus, isTrue);
    expect(calls.conference.legs, {'a': 0, 'b': 1, 'c': 2});
    expect(calls.call('c')!.held, isFalse);
    expect(calls.audio, [(callId: 'c', audio: const CallAudio.silent())]);
  });

  test('a participant the host mutes for the room hears so over a peer message, once', () async {
    await merged();
    signaling.requests.clear();
    calls.muteChanges = {'b': true};

    await room.onParticipants(
      room: 7,
      participants: const [
        ConferenceParticipant(line: 0, callId: 'a'),
        ConferenceParticipant(line: 1, callId: 'b', muted: true),
      ],
      write: write,
    );
    await pumpEventQueue();

    expect(signaling.requests.whereType<ConferenceMutePeerMessageRequest>().map((r) => r.callId), ['b']);
  });

  group('the room\'s video', () {
    setUp(() async {
      room.dispose();
      await room.teardown();
      room = newRoom(video: true);
    });

    test('the host asks for the room\'s video once the answer to the room is taken', () async {
      await merged();
      expect(signaling.requests.whereType<ConferenceVideoSubscribeRequest>(), isEmpty);

      await room.takeStep(steps.whereType<AnswerTakenStep>().single, write);
      await pumpEventQueue();

      expect(signaling.requests.whereType<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(signaling.requests.whereType<ConferenceVideoPublishRequest>(), isEmpty, reason: 'audio calls only');
    });

    test('a room refused its video says so in the state, and asks nothing more of it', () async {
      await merged();
      await room.takeStep(steps.whereType<AnswerTakenStep>().single, write);
      await pumpEventQueue();
      signaling.requests.clear();

      await room.takeStep(const VideoDisabledStep(), write);
      await room.video.setCamera(true);
      await pumpEventQueue();

      expect(calls.conference.videoDisabled, isTrue);
      expect(signaling.requests, isEmpty);
    });

    test('a camera the full room refuses is told to the host once, and not asked for again', () async {
      await merged();
      await room.takeStep(steps.whereType<AnswerTakenStep>().single, write);
      await room.video.setCamera(true);
      await pumpEventQueue();
      expect(signaling.requests.whereType<ConferenceVideoPublishRequest>(), hasLength(1));

      await room.video.onEvent(
        const ConferenceVideoFailedEvent(
          pc: ConferenceVideoPc.publisher,
          reason: 'Maximum number of active publishers (2) already reached',
          code: 432,
        ),
      );
      await pumpEventQueue();

      expect(notifications.whereType<RoomFullNotice>().map((notice) => notice.limit), [
        2,
      ], reason: 'the host learns why his camera is not in the room');
      expect(signaling.requests.whereType<ConferenceVideoPublishRequest>(), hasLength(1), reason: 'no retry');

      await room.video.setCamera(true);
      await pumpEventQueue();
      expect(
        signaling.requests.whereType<ConferenceVideoPublishRequest>(),
        hasLength(2),
        reason: 'the camera button tries again, as someone may have left',
      );
    });

    test('an invitation through a call joins the video, and is in the state at once', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();
      for (final step in steps.whereType<VideoFeedsChangedStep>().toList()) {
        await room.takeStep(step, write);
      }

      expect(signaling.requests.whereType<ConferenceVideoSubscribeRequest>(), hasLength(1));
      expect(invited?.line, 1);
    });

    Future<void> takeVideoSteps() async {
      for (final step in steps.whereType<VideoFeedsChangedStep>().toList()) {
        await room.takeStep(step, write);
      }
      steps.clear();
    }

    test('the end of the call an invitation came through ends the invitation', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();
      await takeVideoSteps();
      expect(invited?.line, 1);

      room.video.onCallsChanged([0], hostsRoom: false);
      await pumpEventQueue();
      await takeVideoSteps();

      expect(invited, isNull);
    });

    test('a call that stays keeps the invitation', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();
      await takeVideoSteps();

      room.video.onCallsChanged([0, 1], hostsRoom: false);
      await pumpEventQueue();

      expect(steps, isEmpty);
      expect(invited?.line, 1);
    });

    test('a merge of its own leaves an invitation first, on the way to the server', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();

      await room.merge(['a', 'b'], write, source: 'test');

      final sent = signaling.requests.map((request) => request.runtimeType).toList();
      expect(sent.indexOf(ConferenceVideoLeaveRequest), lessThan(sent.indexOf(MergeRequest)));
    });

    test('a merge that waits for the conference codecs keeps the invitation', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();
      await takeVideoSteps();
      calls.codec = 'PCMA';

      expect(await room.merge(['a', 'b'], write, source: 'test'), isFalse);
      await pumpEventQueue();
      await takeVideoSteps();

      expect(signaling.requests.whereType<MergeRequest>(), isEmpty);
      expect(signaling.requests.whereType<ConferenceVideoLeaveRequest>(), isEmpty);
      expect(invited?.line, 1);
    });

    test('a merge of calls that cannot be merged keeps the invitation', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 1));
      await pumpEventQueue();
      await takeVideoSteps();
      calls.byId.remove('b');

      await room.merge(['a', 'b'], write, source: 'test');
      await pumpEventQueue();
      await takeVideoSteps();

      expect(signaling.requests.whereType<ConferenceVideoLeaveRequest>(), isEmpty);
      expect(invited?.line, 1);
    });

    test('an invitation to a call that is not here is ignored', () async {
      await room.video.onEvent(const ConferenceVideoInviteEvent(room: 9, line: 5));
      await pumpEventQueue();

      expect(signaling.requests, isEmpty);
      expect(steps, isEmpty);
    });
  });
}
