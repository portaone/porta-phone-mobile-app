// The conference room this client hosts: one object that owns the connection
// to the room's mixer, the wait for its offer, the codecs its legs are moved
// onto and the mute of its legs, and takes every step of the room's life.
// Used by CallBloc, which hands it the room's events and the user's requests.
//
// It knows nothing of the bloc. What it is given, at construction: the
// signalling, callkeep, the capabilities of the server, a sink for errors,
// and ConferenceCalls - what it reads of the calls around the room and asks
// of them. What it asks back: a ConferenceCommand for something only the
// owner can do to a call, a ConferenceStep for a continuation of its own
// that has to take its turn in the owner's queue, and a ConferenceNotice for
// something the user is to be told.
//
// It imports the files it uses, never a barrel of the call feature: one of
// those brings the bloc along.
// The room itself is the owner's state: read through ConferenceCalls and
// changed through the ConferenceWrite a step is called with, one write per
// change, so the owner applies each as one change of its own.
//
// The user's requests are imperatives: merge / addCall build the room and add
// to it, muteParticipant and setSelfMuted mute, end and forget end it, rejoin
// brings the host back in. What the server says arrives as on<What>: onOffer,
// onParticipants, onFailed, onTerminated, onRemoteCandidate, onSessionLost.
// The room's own continuations are private and come back through takeStep.
// planAudio settles what the room's connection carries; legNegotiation is
// what a call's own negotiation tells the move onto the conference codecs.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/models/enableble.dart';
import 'package:webtrit_phone/models/feature_access/call_config.dart';
import 'package:webtrit_phone/models/rtp_codec_profile.dart';

import '../models/active_call.dart';
import '../models/call_audio.dart';
import '../models/call_transition.dart';
import '../models/conference_membership_plan.dart';
import '../models/conference_request_result.dart';
import '../models/conference_state.dart';
import '../models/jsep_value.dart';
import '../models/processing_status.dart';
import '../services/call_signaling.dart';
import '../utils/peer_connection_factory.dart';
import '../utils/user_media_builder.dart';
import 'conference_peer_connection.dart';
import 'leg_mute_sync.dart';
import 'room_codecs.dart';
import 'room_offer_wait.dart';

final _logger = Logger('ConferenceRoom');

/// What the room reads of the calls around it, and what it asks of one call.
/// Implemented by the room's owner over its own state.
abstract interface class ConferenceCalls {
  /// The room as the owner's state has it now.
  ConferenceState get conference;

  /// The call [callId], while there is one.
  ActiveCall? call(String callId);

  /// The call the screen is about.
  String? get focusedCallId;

  /// Whether there are calls to make a room of now.
  bool get canMerge;

  /// The line of every call of [callIds] that can join a room.
  Map<String, int> mergeableLegs(Iterable<String> callIds);

  /// What the server's list of [participants] changes about the room's legs.
  ConferenceMembershipPlan membershipFrom(List<ConferenceParticipant> participants);

  /// Whether the host is on a live call outside the room, for which the room
  /// stands aside.
  bool get hostIsOnAnotherCall;

  /// Gives [callId] the audio an ordinary call carries, as the owner's rule
  /// has it; whether there was a call to give it to - nothing is done for
  /// one that is gone or going, nor for one the room released and nobody has
  /// resumed.
  Future<bool> restoreAudio(String callId);

  /// Gives [callId] the audio [wanted] of it; whether there was a call to
  /// give it to.
  Future<bool> applyAudio(String callId, CallAudio wanted);

  /// The audio codec [callId] sends now.
  Future<String?> audioCodecInUse(String callId);
}

/// One change of the owner's state the room asks for, applied as a whole.
class ConferenceUpdate {
  const ConferenceUpdate({
    this.conference,
    this.unheld = const {},
    this.transitions = const {},
    this.settleFocus = false,
  });

  /// The room as it is from now on; `null` leaves it as it was.
  final ConferenceState? conference;

  /// Calls the server took off hold as they joined.
  final Set<String> unheld;

  /// The transition each of these calls is in from now on; `null` for none.
  final Map<String, CallTransition?> transitions;

  /// Whether the focus a placed call was waiting for is settled with this.
  final bool settleFocus;
}

/// Applies a [ConferenceUpdate] to the owner's state.
typedef ConferenceWrite = void Function(ConferenceUpdate update);

/// Something only the owner can do to a call, asked for by the room.
sealed class ConferenceCommand {
  const ConferenceCommand();
}

/// Renegotiate [callId]: onto the conference codecs, or back off them.
final class RenegotiateLegCommand extends ConferenceCommand {
  const RenegotiateLegCommand(this.callId);

  /// The call to renegotiate.
  final String callId;
}

/// Put [callId] on hold again after its renegotiation.
final class RestoreLegHoldCommand extends ConferenceCommand {
  const RestoreLegHoldCommand(this.callId);

  /// The call to hold again.
  final String callId;
}

/// Hold [callId] or resume it, as the user's own control would.
final class SetLegHeldCommand extends ConferenceCommand {
  const SetLegHeldCommand(this.callId, this.held);

  /// The call to hold or resume.
  final String callId;

  /// Whether it is to be held.
  final bool held;
}

/// End [callId] for the reason the room was ended for.
final class EndLegCommand extends ConferenceCommand {
  const EndLegCommand(this.callId, this.endedBy);

  /// The call to end.
  final String callId;

  /// Who ended the room it was a leg of.
  final CallkeepEndedBy endedBy;
}

/// Ask for the merge of [callIds] again: they are on the conference codecs.
final class RetryMergeCommand extends ConferenceCommand {
  const RetryMergeCommand(this.callIds);

  /// The calls to merge.
  final List<String> callIds;
}

/// Ask to add [callId] to the room again: it is on the conference codecs.
final class RetryAddCommand extends ConferenceCommand {
  const RetryAddCommand(this.callId);

  /// The call to add.
  final String callId;
}

/// Something for the user to be told about the room; the owner words it.
sealed class ConferenceNotice {
  const ConferenceNotice();
}

/// The server refused to build the room or to add a call to it, for [reason].
final class RoomRefusedNotice extends ConferenceNotice {
  const RoomRefusedNotice(this.reason);

  /// The server's reason, as it sent it.
  final String reason;
}

/// The room could not be built or joined, for [reason]; the calls are
/// ordinary calls again.
final class RoomFailedNotice extends ConferenceNotice {
  const RoomFailedNotice(this.reason);

  /// The server's reason, or this client's own name for what failed.
  final String reason;
}

/// The room ended while calls were still up; they go on as ordinary calls.
final class RoomEndedNotice extends ConferenceNotice {
  const RoomEndedNotice();
}

/// A continuation of the room's own that takes its turn in the owner's
/// queue: the owner hands it back to [ConferenceRoom.takeStep]. An owner that
/// is closing drops it, as it drops a [ConferenceCommand].
sealed class ConferenceStep {
  const ConferenceStep();
}

/// A candidate the mixer's connection gathered, to be sent to the server.
final class CandidateGatheredStep extends ConferenceStep {
  const CandidateGatheredStep(this.candidate);

  /// The candidate; `null` ends the gathering.
  final RTCIceCandidate? candidate;
}

/// The room is given up: it never finished being built, its audio could not
/// be applied, or there is no way back into it.
final class RoomGivenUpStep extends ConferenceStep {
  const RoomGivenUpStep();
}

/// The mixer's connection failed; the room asks for a way back or gives up.
final class MixerFailedStep extends ConferenceStep {
  const MixerFailedStep({required this.hadConnected});

  /// Whether the connection had carried the room before it failed.
  final bool hadConnected;
}

/// The answer to the room's offer reached the server: this client is in the room.
final class AnswerTakenStep extends ConferenceStep {
  const AnswerTakenStep({required this.room, required this.attempt});

  /// The room the answer was for.
  final int room;

  /// The attempt at the room's offer the answer belongs to.
  final int attempt;
}

/// The answer to the room's offer could not be made, or never got through.
final class AnswerFailedStep extends ConferenceStep {
  const AnswerFailedStep({required this.attempt, this.result});

  /// The attempt at the room's offer the answer belongs to.
  final int attempt;

  /// What became of the request; `null` when the answer could not be made.
  final ConferenceRequestResult? result;
}

/// What the session did with the rejoin.
final class RejoinRepliedStep extends ConferenceStep {
  const RejoinRepliedStep({required this.attempt, required this.result});

  /// The attempt the rejoin was asked in.
  final int attempt;

  /// What became of the request.
  final ConferenceRequestResult result;
}

/// The conference room this client hosts.
class ConferenceRoom {
  ConferenceRoom({
    required ConferenceCalls calls,
    required CallSignaling signaling,
    required Callkeep callkeep,
    required CallCapabilitiesConfig capabilities,
    required void Function(ConferenceCommand command) onCommand,
    required void Function(ConferenceStep step) onStep,
    required void Function(ConferenceNotice notice) onNotice,
    required void Function(Object error, StackTrace? stack, String context) onError,
    required PeerConnectionFactory factory,
    required UserMediaBuilder userMediaBuilder,
    required Duration assemblyTimeout,
    required Set<RTPCodec> audioCodecs,
    Timer Function(Duration, void Function())? offerDeadlineTimer,
    List<Enableble<RTPCodecProfile>>? Function()? audioProfiles,
    Timer Function(Duration, void Function())? codecMoveTimer,
  }) : _calls = calls,
       _signaling = signaling,
       _callkeep = callkeep,
       _capabilities = capabilities,
       _onCommand = onCommand,
       _onStep = onStep,
       _onNotice = onNotice,
       _onError = onError {
    _offerWait = RoomOfferWait(timeout: assemblyTimeout, createTimer: offerDeadlineTimer);
    _roomCodecs = RoomCodecs(
      onCommand: _executeRoomCodecsCommand,
      codecs: audioCodecs,
      preferred: audioProfiles,
      createTimer: codecMoveTimer,
    );
    _conferencePeerConnection = ConferencePeerConnection(
      factory: factory,
      userMediaBuilder: userMediaBuilder,
      onLocalCandidate: (candidate) => _onStep(CandidateGatheredStep(candidate)),
      onConnectionLost: () => _onStep(const RoomGivenUpStep()),
      onConnectionFailed: ({required hadConnected}) => _onStep(MixerFailedStep(hadConnected: hadConnected)),
    );
  }

  final ConferenceCalls _calls;
  final CallSignaling _signaling;
  final Callkeep _callkeep;
  final CallCapabilitiesConfig _capabilities;
  final void Function(ConferenceCommand command) _onCommand;
  final void Function(ConferenceStep step) _onStep;
  final void Function(ConferenceNotice notice) _onNotice;
  final void Function(Object error, StackTrace? stack, String context) _onError;

  /// The host's connection to the conference room's mixer; idle without a room.
  late final ConferencePeerConnection _conferencePeerConnection;

  /// The wait for the mixer's offer - after a merge, and after a rejoin: which
  /// attempt is current, whether this session was asked, and the deadline.
  late final RoomOfferWait _offerWait;

  /// Keeps the platform's mute for every leg in step with the room's, and
  /// tells this client's own echoes from a person pressing mute.
  late final LegMuteSync _legMutes = LegMuteSync(_callkeep);

  /// The conference codecs and the move of calls onto them; see [RoomCodecs].
  late final RoomCodecs _roomCodecs;

  /// Whether the owner is closing: a deadline that still fires then is
  /// nobody's.
  bool _disposed = false;

  /// Takes [step], one of the room's own continuations handed back by the
  /// owner's queue, as the method it names.
  Future<void> takeStep(ConferenceStep step, ConferenceWrite write) => switch (step) {
    CandidateGatheredStep(:final candidate) => _localCandidate(candidate),
    RoomGivenUpStep() => _connectionLost(write),
    MixerFailedStep(:final hadConnected) => _connectionFailed(hadConnected: hadConnected, write: write),
    AnswerTakenStep(:final room, :final attempt) => _answered(room: room, attempt: attempt, write: write),
    AnswerFailedStep(:final attempt, :final result) => _answerFailed(attempt: attempt, result: result, write: write),
    RejoinRepliedStep(:final attempt, :final result) => _rejoinReplied(attempt: attempt, result: result),
  };

  /// What a call's own negotiation tells the room, for the calls being moved
  /// onto the conference codecs and back; the move itself stays the room's.
  LegNegotiation get legNegotiation => _roomCodecs;

  /// The signalling session went: the next one's handshake reads it.
  void onSessionLost() => _offerWait.sessionLost();

  /// Whether a mute the platform reports for [callId] is this client's own
  /// command coming home rather than a person pressing mute.
  bool consumeMuteEcho(String callId, bool muted) => _legMutes.consume(callId, muted);

  /// Forgets a room without telling the server, when every call is reset:
  /// the wait for its offer ends, the mixer's connection is closed and the
  /// room is gone from the state. The legs are not handed back - they are
  /// ended by whoever resets them.
  Future<void> forget(ConferenceWrite write) async {
    _offerWait.end();
    await _conferencePeerConnection.teardown();
    write(const ConferenceUpdate(conference: ConferenceState()));
  }

  /// Closes the mixer's connection.
  Future<void> teardown() => _conferencePeerConnection.teardown();

  /// Stops the timers; the mixer's connection is closed by [teardown].
  void dispose() {
    _disposed = true;
    _offerWait.dispose();
    _roomCodecs.dispose();
  }

  /// The room gives its audio up while a call outside it stands, and takes it
  /// back afterwards; the rule itself is `CallState.roomAudio`. It is planned
  /// here, off the state, rather than commanded from the paths that accept and
  /// end calls: a call is marked accepted in four of them, the handshake
  /// restore after a reconnect included, and one that forgot to command it
  /// would leave the room carrying a private conversation.
  ///
  /// Applied here, at the change, and not queued as a mutation: the global
  /// queue can be waiting on an unrelated server round trip - a participant's
  /// mute, an add - and a mute or a park that waited behind it would leave the
  /// host's microphone in the room for exactly that long. The connection
  /// serialises its own work, and a later intent overtakes an earlier one there.
  void planAudio(CallAudio wanted, Iterable<String> legIds) {
    if (wanted == _conferencePeerConnection.audio) return;
    // Whether the room stands aside is the half of it the legs are told about;
    // the host's own mute is theirs to hear from the server's list.
    final parkingChanged = _conferencePeerConnection.isParked != !wanted.audible;
    _logger.info('_planConferenceAudio: wanted=$wanted');
    unawaited(
      _conferencePeerConnection.apply(wanted).catchError((Object error) {
        // Only logged, and that is all there is to do here: applying is the
        // connection's own business, and one that cannot be applied gives the
        // room up through [ConferencePeerConnection.onConnectionLost] - which
        // arrives as a conferenceLost event and hands the legs back. Nothing is
        // planned again from here: what is wanted is already what [audio] says.
        _logger.warning('_planConferenceAudio: applying $wanted failed', error);
      }),
    );
    if (parkingChanged) _tellLegsTheRoomIsParked(legIds, !wanted.audible);
  }

  /// Restricts [description] to the conference codecs for a call in or on
  /// its way into the room (see [RoomCodecs.restrict]).
  void restrictToConferenceCodecs(String callId, RTCSessionDescription description, {required bool joining}) {
    final sdp = description.sdp;
    if (sdp == null) return;
    final restricted = _roomCodecs.restrict(callId, sdp, inRoom: joining || _calls.conference.isLeg(callId));
    if (restricted != null) description.sdp = restricted;
  }

  void _executeRoomCodecsCommand(RoomCodecsCommand command) {
    switch (command) {
      case RenegotiateForRoom(:final callId):
        _onCommand(RenegotiateLegCommand(callId));
      case TakeBackForRoom(:final callId):
        _onCommand(RenegotiateLegCommand(callId));
      case HoldAgain(:final callId):
        // A call the person resumed meanwhile is left alone.
        if (_calls.call(callId)?.held ?? false) {
          _onCommand(RestoreLegHoldCommand(callId));
        }
      case AskAgain(:final request):
        request();
    }
  }

  /// Whether [callIds] can go into a room now (see [RoomCodecs.check]); a
  /// call still off the codecs after a move is said here.
  Future<RoomCodecsCheck> _roomCodecsFor(
    Iterable<String> callIds, {
    required void Function() request,
    required String source,
  }) async {
    final calls = <String, ({String? codec, bool held})>{};
    for (final callId in callIds) {
      if (_calls.conference.isLeg(callId)) continue;
      calls[callId] = (codec: await _calls.audioCodecInUse(callId), held: _calls.call(callId)?.held ?? false);
    }
    final check = _roomCodecs.check(calls, request: request);
    if (check != RoomCodecsCheck.ready) _logger.info('$source: conference codecs ${check.name}');
    if (check == RoomCodecsCheck.off) {
      _onNotice(RoomFailedNotice(_roomCodecs.offReason(calls.keys)));
    }
    return check;
  }

  // conference
  //
  // The room is the server's: the host asks for it with `merge`, the server
  // wires the legs and hands over the mixer's offer, and every change of
  // membership arrives as its participant list. What the client owns is the
  // record of which calls it put in (_calls.conference.legs) - the legs are
  // quiet from the merge's ack, and that record is what a failure undoes.
  // The wire format and the obligations followed here are in
  // packages/signaling/docs/conference_protocol.md.

  /// Asks the server to merge [callIds] into a room; [source] names whoever
  /// asked, in the log and on the request.
  ///
  /// Returns false when the merge waits for calls being moved onto the
  /// conference codecs; [request] - by default this merge again - is asked
  /// once they are.
  Future<bool> merge(
    List<String> callIds,
    ConferenceWrite write, {
    required String source,
    void Function()? request,
  }) async {
    var settles = true;
    var roomTook = false;
    try {
      if (!_calls.canMerge) {
        _logger.warning('$source: nothing to merge now, ignoring');
        return true;
      }
      final legs = _calls.mergeableLegs(callIds);
      if (legs.length < 2) {
        _logger.warning('$source: fewer than two mergeable calls in $callIds, ignoring');
        return true;
      }
      final codecs = await _roomCodecsFor(
        legs.keys,
        request: request ?? () => _onCommand(RetryMergeCommand(callIds)),
        source: source,
      );
      if (codecs != RoomCodecsCheck.ready) {
        settles = codecs == RoomCodecsCheck.off;
        return settles;
      }
      final taken = await _executeConferenceRequest(
        MergeRequest(transaction: WebtritSignalingClient.generateTransactionId(), lines: legs.values.toList()),
        source: source,
        notifyRefusal: true,
      );
      if (!taken) return true;
      roomTook = true;
      // From the ack on the legs are the server's: quiet now, not at the offer,
      // so that a failure between the two undoes exactly what was recorded.
      legs.removeWhere((callId, _) => _calls.call(callId) == null);
      await _quietLegs(legs.keys, write);
      if (_calls.conference.isPresent) {
        _logger.warning('$source: a room appeared while this merge was being acknowledged');
        return true;
      }
      _offerWait.begin();
      write(
        ConferenceUpdate(
          conference: ConferenceState(phase: ConferencePhase.assembling, legs: legs),
        ),
      );
      _armConferenceAssembly();
      return true;
    } finally {
      if (settles) _roomCodecs.settled(callIds, roomTook: roomTook);
    }
  }

  /// Asks the server to add [callId] to the room; [source] names whoever
  /// asked, in the log and on the request.
  ///
  /// Returns false when the add waits for the call being moved onto the
  /// conference codecs; [request] - by default this add again - is asked once
  /// it is.
  Future<bool> addCall(String callId, ConferenceWrite write, {required String source, void Function()? request}) async {
    var settles = true;
    var roomTook = false;
    try {
      final line = _calls.mergeableLegs([callId])[callId];
      if (!_calls.conference.isPresent || line == null) {
        _logger.warning('$source: $callId cannot join now, ignoring');
        return true;
      }
      final codecs = await _roomCodecsFor(
        [callId],
        request: request ?? () => _onCommand(RetryAddCommand(callId)),
        source: source,
      );
      if (codecs != RoomCodecsCheck.ready) {
        settles = codecs == RoomCodecsCheck.off;
        return settles;
      }
      final taken = await _executeConferenceRequest(
        ConferenceAddRequest(transaction: WebtritSignalingClient.generateTransactionId(), line: line),
        source: source,
        notifyRefusal: true,
      );
      if (!taken) return true;
      roomTook = true;
      if (!_calls.conference.isPresent || _calls.call(callId) == null) return true;
      await _quietLegs([callId], write);
      if (!_calls.conference.isPresent) return true;
      write(
        ConferenceUpdate(
          conference: _calls.conference.copyWith(legs: {..._calls.conference.legs, callId: line}),
          settleFocus: true,
        ),
      );
      // After the room has been found to be still there, and after the call is
      // one of its legs: told any earlier, a call whose room fell away while it
      // was being quieted would be left saying the host had stepped out of a room
      // it never joined, with nothing to ever correct it.
      if (_conferencePeerConnection.isParked) _tellLegsTheRoomIsParked([callId], true);
      return true;
    } finally {
      if (settles) _roomCodecs.settled([callId], roomTook: roomTook);
    }
  }

  /// A room-wide mute of one participant. Accepted by the server only once
  /// it has listed the participant; the outcome comes back as the next list,
  /// nothing is guessed here.
  Future<void> muteParticipant(String callId, bool muted) async {
    final participant = _calls.conference.participants.firstWhereOrNull((p) => p.callId == callId);
    if (participant == null) {
      _logger.warning('__onMutationControlConferenceMute: $callId is not a listed participant, ignoring');
      return;
    }
    await _executeConferenceRequest(
      ConferenceMuteRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: participant.line,
        muted: muted,
      ),
      source: '__onMutationControlConferenceMute',
    );
  }

  /// Mutes the host towards the room, from whichever control asked.
  ///
  /// The room's microphone and what the screen says about it are one thing,
  /// so they are set in one place: a mute the operating system reports for a
  /// leg and the room's own control must not be able to disagree.
  Future<void> setSelfMuted(bool muted, ConferenceWrite write) async {
    if (!_calls.conference.isPresent) return;
    // The mute is recorded and the room's connection follows from the state,
    // the same way its parking does: two reasons, one intent, one planner.
    write(ConferenceUpdate(conference: _calls.conference.copyWith(selfMuted: muted)));
    await _legMutes.apply(_calls.conference.legIds, muted);
  }

  /// The host ends the conference, and with it every leg: a room is not
  /// unwound into separate calls. The room is dropped here rather than at
  /// the server's confirmation, so the legs end as ordinary calls and the
  /// confirmation, when it comes, finds nothing to bring back.
  Future<void> end(CallkeepEndedBy endedBy, ConferenceWrite write) async {
    if (!_calls.conference.isPresent) return;
    final legIds = _calls.conference.legIds.toList();
    await _leaveRoom(write, restoreLegs: false);
    _hangUpRoom('__onMutationControlConferenceEnd');
    for (final callId in legIds) {
      _onCommand(EndLegCommand(callId, endedBy));
    }
  }

  /// The mixer's offer: the room is built. The list it carries is the
  /// membership - a leg the server could not mix is not in it - and the
  /// answer is what makes the host part of the room.
  Future<void> onOffer({
    required int room,
    required JsepValue jsep,
    required List<ConferenceParticipant> participants,
    required ConferenceWrite write,
  }) async {
    if (!_calls.conference.isPresent) {
      // Nothing here wants it any more: the room was given up while the
      // server was still building it. Never refused, and it ends the room.
      _logger.warning('__onMutationConferenceOffer: no room here for $room, hanging it up');
      _hangUpRoom('__onMutationConferenceOffer');
      return;
    }
    // Recorded before anything is awaited: the handshake handler runs outside
    // every queue and decides what this client holds by the room id in the
    // state, so a handshake arriving while a participant is being taken off
    // hold - a native round trip - would hang up the room being joined.
    write(ConferenceUpdate(conference: _calls.conference.copyWith(room: room)));
    await _adoptParticipants(participants, write);
    // Answering is a media round trip and then a request, and neither may
    // hold the mutation queue: while it does, the deadline that gives the
    // calls back cannot run, and neither can the host's own End - the legs
    // would stay silent for as long as the answer takes.
    unawaited(_answerRoom(room, jsep, _offerWait.attempt));
  }

  /// Builds the connection to the mixer and sends the answer, off the queue.
  ///
  /// Every step is checked against the attempt it was started for: a room
  /// given up while this was in flight must not be raised from the dead by
  /// its own answer arriving late.
  Future<void> _answerRoom(int room, JsepValue jsep, int attempt) async {
    try {
      final answer = await _conferencePeerConnection.answer(room: room, offer: jsep.toDescription());
      if (!_offerWait.isCurrent(attempt)) return;
      final result = await _sendConferenceRequest(
        ConferenceAnswerRequest(transaction: WebtritSignalingClient.generateTransactionId(), jsep: answer.toMap()),
        source: '_answerRoom',
      );
      _onStep(
        result.outcome == ConferenceRequestOutcome.taken
            ? AnswerTakenStep(room: room, attempt: attempt)
            : AnswerFailedStep(attempt: attempt, result: result),
      );
    } catch (error, stackTrace) {
      _onError(error, stackTrace, '_answerRoom error');
      _onStep(AnswerFailedStep(attempt: attempt));
    }
  }

  /// The answer reached the server: the host is in the room. An answer for
  /// an attempt that is no longer the current one is nobody's: the room was
  /// given up meanwhile, or the host is on his way in over another offer.
  Future<void> _answered({required int room, required int attempt, required ConferenceWrite write}) async {
    if (!_offerWait.isCurrent(attempt)) return;
    if (!_calls.conference.concerns(room) || !_calls.conference.isPresent) {
      _logger.warning('__onMutationConferenceAnswered: $room is not the room here');
      return;
    }
    _offerWait.offerAnswered();
    write(ConferenceUpdate(conference: _calls.conference.copyWith(phase: ConferencePhase.active)));
  }

  /// Without a way into the room the host would hear nothing of it: give it
  /// up and bring the legs back.
  ///
  /// Not when the host is on his way back and the answer merely did not get
  /// through: the room stands on the server. Either the session is going -
  /// then its loss voids this attempt and the next one asks again - or it is
  /// up, and the deadline that has run since the rejoin was asked ends the
  /// wait. Which of the two it is cannot be read off the connection now: by
  /// the time this is handled it may be another session's.
  Future<void> _answerFailed({
    required int attempt,
    required ConferenceWrite write,
    ConferenceRequestResult? result,
  }) async {
    if (!_offerWait.isCurrent(attempt) || !_calls.conference.isPresent) return;
    final undelivered =
        result?.outcome == ConferenceRequestOutcome.notSent || result?.outcome == ConferenceRequestOutcome.unanswered;
    if (_calls.conference.phase == ConferencePhase.rejoining && undelivered) {
      _logger.info('__onMutationConferenceAnswerFailed: the answer did not get through, the rejoin is not over');
      return;
    }
    _hangUpRoom('__onMutationConferenceAnswerFailed');
    await _leaveRoom(write, restoreLegs: true);
    _onNotice(const RoomFailedNotice('answer_failed'));
  }

  /// A candidate of the mixer's connection, from the server.
  Future<void> onRemoteCandidate(RTCIceCandidate? candidate) async {
    if (!_calls.conference.isPresent) return;
    // Not awaited: the connection feeds candidates in turn with its own work,
    // so one that arrives while the room's answer is still being prepared waits
    // behind it there - and waiting for it here would hold the mutation queue
    // for as long, with the room's End and its assembly deadline behind it.
    // Nothing is lost by not waiting: the candidate is queued there at once,
    // ahead of anything the room is asked to do later - a teardown included,
    // which clears it - and a failure is still reported.
    unawaited(
      _conferencePeerConnection.addRemoteCandidate(candidate).catchError((Object error, StackTrace stackTrace) {
        _onError(error, stackTrace, '__onMutationConferenceRemoteCandidate error');
      }),
    );
  }

  /// A candidate the mixer's connection gathered, sent to the server once
  /// the connection is up.
  Future<void> _localCandidate(RTCIceCandidate? candidate) async {
    if (!_calls.conference.isPresent || !_conferencePeerConnection.isUp) return;
    await _executeConferenceRequest(
      ConferenceIceTrickleRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        candidate: candidate?.toMap(),
      ),
      source: '__onMutationConferenceLocalCandidate',
    );
  }

  /// The server's list of the room's participants changed.
  Future<void> onParticipants({
    required int room,
    required List<ConferenceParticipant> participants,
    required ConferenceWrite write,
  }) async {
    if (!_calls.conference.isPresent) return;
    if (room != _calls.conference.room) {
      // Section 5.1: a list for another room describes another room. A late
      // one from a room already left would otherwise replace this room's
      // membership and put its legs on hold.
      _logger.warning('__onMutationConferenceUpdated: room $room is not the room here (${_calls.conference.room})');
      return;
    }
    await _adoptParticipants(participants, write);
  }

  /// The room could not be built - a leg turned out to be a video call.
  /// Terminal: nothing else about this room follows.
  Future<void> onFailed({required String reason, required ConferenceWrite write, int? room, String? detail}) async {
    if (!_calls.conference.isPresent) return;
    if (!_calls.conference.concerns(room)) {
      _logger.warning('__onMutationConferenceFailed: room $room is not the room here');
      return;
    }
    _logger.warning('__onMutationConferenceFailed: $reason ${detail ?? ''}');
    await _leaveRoom(write, restoreLegs: true);
    _onNotice(RoomFailedNotice(reason));
  }

  /// The room is over, for whichever of its reasons: the host's own hangup
  /// has already dropped it here and finds nothing; the rest leave the
  /// calls that are still up as ordinary calls, all active at once on the
  /// server, so all but the focused one go on hold. After a lost mixer the
  /// legs have no media and their hangups follow; they are left alone.
  Future<void> onTerminated({required ConferenceWrite write, int? room}) async {
    if (!_calls.conference.isPresent) return;
    if (!_calls.conference.concerns(room)) {
      _logger.warning('__onMutationConferenceTerminated: room $room is not the room here');
      return;
    }
    final restored = await _leaveRoom(write, restoreLegs: true);
    if (restored.isNotEmpty) _onNotice(const RoomEndedNotice());
  }

  /// The room is given up without the server saying it is over: it never
  /// finished being built, its audio could not be applied, or there is no way
  /// back into it. The calls in it are still calls, so they are handed back
  /// the way a termination hands them back, and the room is ended on the
  /// server too in case it still stands.
  Future<void> _connectionLost(ConferenceWrite write) async {
    if (!_calls.conference.isPresent) return;
    _logger.warning('__onMutationConferenceLost: giving up conference room ${_calls.conference.room}');
    _hangUpRoom('__onMutationConferenceLost');
    await _leaveRoom(write, restoreLegs: true);
    _onNotice(const RoomEndedNotice());
  }

  /// The connection to the mixer failed while the room stands on the server.
  ///
  /// It cannot be restarted the way a call's is - the mixer made the offer and
  /// refuses one from the client - but the server hands out a new offer for
  /// the same room on request, and the legs go on being mixed meanwhile. So
  /// the dead connection is closed and the room is kept: same legs, same
  /// list, same mute, and nothing for the user to do again.
  ///
  /// Only a connection that had carried the room is replaced. One that never
  /// came up did not lose a path it had, and asking for another would go
  /// round for as long as media cannot get through; that room is given up,
  /// as is any room on a server without the request.
  Future<void> _connectionFailed({required bool hadConnected, required ConferenceWrite write}) async {
    if (!_calls.conference.isPresent) return;
    final canRejoin =
        _capabilities.isConferenceRejoinEnabled && hadConnected && _calls.conference.phase == ConferencePhase.active;
    if (!canRejoin) {
      _logger.warning(
        '__onMutationConferenceConnectionFailed: no way back into room ${_calls.conference.room} '
        '(rejoin=${_capabilities.isConferenceRejoinEnabled}, hadConnected=$hadConnected, '
        'phase=${_calls.conference.phase})',
      );
      _onStep(const RoomGivenUpStep());
      return;
    }
    _logger.info('__onMutationConferenceConnectionFailed: rejoining conference room ${_calls.conference.room}');
    // Whatever was in flight for the dead connection is not wanted any more.
    _offerWait.beginRejoin();
    write(ConferenceUpdate(conference: _calls.conference.copyWith(phase: ConferencePhase.rejoining)));
    // Not waited on, like every other close of it: the connection serialises
    // its own work, and the offer that follows is answered behind this.
    unawaited(_conferencePeerConnection.release());
    _askForRejoin();
  }

  /// The handshake found the room standing while the host is still on his way
  /// back into it. A session that has already been asked is left to answer;
  /// otherwise the request never left, or it - or the offer it was to bring -
  /// went with the session before this one, and so did any answer still in
  /// flight, which must not be taken for a failure to join.
  Future<void> rejoin() async {
    if (_calls.conference.phase != ConferencePhase.rejoining || _offerWait.rejoinAsked) return;
    _offerWait.beginRejoin();
    // A connection opened for an offer of the session before is of no use
    // either: the new offer comes from a new handle.
    unawaited(_conferencePeerConnection.release());
    _askForRejoin();
  }

  /// Asks the session for the room's offer again - once per session, and only
  /// a session that is up.
  ///
  /// A session that is down is not handed the request at all: the signaling
  /// module would keep it and send it on reconnect, next to the one the
  /// handshake sends, and the server moves the host onto a new handle for
  /// each. Nothing is decided then and no deadline runs; the handshake that
  /// brings the session back says whether the room still stands, and asks.
  void _askForRejoin() {
    if (_offerWait.rejoinAsked) return;
    if (!_signaling.isConnected) {
      _logger.info('_askForRejoin: the session is down, the handshake will ask');
      return;
    }
    _offerWait.markRejoinAsked();
    // From the request, not from its acknowledgement: a server that is up and
    // says nothing would otherwise keep the host waiting for as long as the
    // request is retried before any deadline started.
    _armConferenceAssembly();
    unawaited(_requestRejoin(_offerWait.attempt));
  }

  /// Sends the rejoin, off the queue: the request is a round trip, and the
  /// host's own End must not wait behind it. What became of it comes back as
  /// an event, like the answer to the room's offer does.
  Future<void> _requestRejoin(int attempt) async {
    final result = await _sendConferenceRequest(
      ConferenceRejoinRequest(transaction: WebtritSignalingClient.generateTransactionId()),
      source: '_requestRejoin',
    );
    _onStep(RejoinRepliedStep(attempt: attempt, result: result));
  }

  /// What the session did with the rejoin.
  ///
  /// Only a refusal decides anything here. Refused because an offer is
  /// already pending - the answer to having asked twice - it is waited for;
  /// refused for any other reason, there is no room to come back to and it is
  /// given up.
  ///
  /// Everything else leaves the wait as it is, under the deadline that has
  /// run since the request: taken, the offer is on its way; unanswered, it
  /// may have been taken all the same; not delivered, either the session is
  /// going, and its loss voids this attempt, or it is up and the deadline
  /// ends the wait. A reply of a session that is already gone never gets
  /// here: its attempt is not the current one.
  Future<void> _rejoinReplied({required int attempt, required ConferenceRequestResult result}) async {
    if (!_offerWait.isCurrent(attempt) || _calls.conference.phase != ConferencePhase.rejoining) return;
    if (result.outcome != ConferenceRequestOutcome.refused) return;
    final offerPending =
        ConferenceRefusalReason.fromReason(result.reason ?? '') == ConferenceRefusalReason.conferenceNotEstablished;
    if (offerPending) return;
    _offerWait.rejoinRefused();
    _onStep(const RoomGivenUpStep());
  }

  /// Gives the wait for the room's offer a deadline of this client's own.
  ///
  /// After a merge the legs go quiet at the acknowledgement and stay quiet
  /// until the room's offer arrives. The server has a deadline of its own and
  /// announces it, but it announces it as an event, and events are not
  /// replayed - so a socket that drops in between takes that word with it and
  /// would leave both calls silent in both directions until it comes back.
  /// After a rejoin the server took, the host is out of the room until the
  /// offer arrives, and the server has no deadline for that one at all.
  void _armConferenceAssembly() => _offerWait.arm(_onRoomOfferOverdue);

  void _onRoomOfferOverdue() {
    if (!_calls.conference.awaitsOffer || _disposed) return;
    _logger.warning('the conference room never arrived, giving the calls back');
    _onStep(const RoomGivenUpStep());
  }

  /// Ends the room on the server. Sent and not waited on: this client has
  /// already let the room go by the time it asks.
  void _hangUpRoom(String source) {
    unawaited(
      _executeConferenceRequest(
        ConferenceHangupRequest(transaction: WebtritSignalingClient.generateTransactionId()),
        source: source,
      ),
    );
  }

  /// Sends a conference request and says whether the server took it. A
  /// refusal is the server's answer and, when [notifyRefusal], the host's to
  /// see; a transport failure is a request that never got there.
  Future<bool> _executeConferenceRequest(Request request, {required String source, bool notifyRefusal = false}) async {
    final result = await _sendConferenceRequest(request, source: source);
    if (result.outcome == ConferenceRequestOutcome.refused && notifyRefusal) {
      _onNotice(RoomRefusedNotice(result.reason ?? ''));
    }
    return result.outcome == ConferenceRequestOutcome.taken;
  }

  /// Sends a conference request and says what became of it.
  Future<ConferenceRequestResult> _sendConferenceRequest(Request request, {required String source}) async {
    try {
      // A module with nowhere to send answers with nothing at all, and an
      // awaited null completes like an acknowledgement would. Quieting the
      // legs for a room the server was never asked for would leave two live
      // calls silent in both directions.
      final pending = _signaling.execute(request);
      if (pending == null) {
        _logger.warning('$source: not sent, the session is not connected');
        return const ConferenceRequestResult.notSent();
      }
      await pending;
      return const ConferenceRequestResult.taken();
    } on SignalingErrorException catch (e) {
      _logger.warning('$source: refused by the server: ${e.reason}');
      return ConferenceRequestResult.refused(e.reason);
    } on NotConnectedException {
      _logger.warning('$source: not connected');
      return const ConferenceRequestResult.notSent();
    } on SignalingTransactionTerminateByDisconnectException {
      // The socket closed under the request: what an outage looks like, not
      // an error to report.
      _logger.warning('$source: the session went before an answer');
      return const ConferenceRequestResult.notSent();
    } on SignalingTransactionTimeoutException {
      _logger.warning('$source: transaction timeout');
      return const ConferenceRequestResult.unanswered();
    } catch (e, stackTrace) {
      _onError(e, stackTrace, '$source error');
      return const ConferenceRequestResult.notSent();
    }
  }

  /// Silences a leg both ways for the room: the microphone leaves the leg's
  /// own connection and the far end's audio stops playing.
  Future<void> _quietLegs(Iterable<String> callIds, ConferenceWrite write) async {
    for (final callId in callIds) {
      // A rejoined leg is isolated by the room's own membership again, so the
      // resume it was waiting for is nothing to it any more.
      if (_calls.call(callId)?.transition == CallTransition.releasedFromRoom) {
        write(ConferenceUpdate(transitions: {callId: null}));
      }
      await _calls.applyAudio(callId, const CallAudio.silent());
    }
    // A call joining a room the host has already muted starts out of step
    // with it; see [LegMuteSync].
    if (_calls.conference.selfMuted) await _legMutes.apply(callIds, true);
  }

  /// Takes the server's list as the room's membership. A leg not in it that
  /// is still up is an ordinary call again: audio back and on hold, since
  /// the room is what the host hears. A listed call is off hold on the
  /// server's side - it un-holds a leg as it joins, with no event - so the
  /// local flag follows; the operating system is told the group instead, and
  /// takes the legs as active from that. A vanished leg is held only after
  /// the membership is re-declared, which is what lets it leave the group.
  Future<void> _adoptParticipants(List<ConferenceParticipant> participants, ConferenceWrite write) async {
    final plan = _calls.membershipFrom(participants);
    // A leg dropped while the host is on a call outside the room must not get
    // his microphone back on the way out: the room stood aside for that call,
    // and a hold that is still unanswered - or refused - would hand the leg the
    // private conversation. It stays silent until a resume the server took,
    // the same way a leg a lost room hands back does.
    final hostAway = _calls.hostIsOnAnotherCall;
    write(
      ConferenceUpdate(
        unheld: plan.unheld.toSet(),
        // A leg the server dropped is on its way to being an ordinary held
        // call, and the hold can only be asked for once the group has been
        // re-declared below. Marked rather than held: `held` means a hold
        // the server took, and claiming one it has not would show the user
        // a call on hold that is in fact live - with the room, seeing a
        // held call, carrying his microphone into it.
        transitions: {
          for (final callId in plan.vanished)
            callId: hostAway ? CallTransition.releasedFromRoom : CallTransition.leavingRoom,
        },
        conference: _calls.conference.copyWith(legs: plan.legs, participants: participants),
        settleFocus: true,
      ),
    );
    // From here the order is the rule. The group is declared before any hold,
    // because a hold on a member is refused and a leg can only leave a group
    // that has been re-declared without it.
    await _quietLegs(plan.adopted, write);
    _tellLegsTheirRoomMute(plan.muteChanges);
    if (_conferencePeerConnection.isParked) {
      if (plan.adopted.isNotEmpty) _tellLegsTheRoomIsParked(plan.adopted, true);
      // A leg the room drops while it stands aside carries on as an ordinary
      // call, and the later unpark goes only to the legs the room still has -
      // so this is its only chance to hear that the host is back. The same hole
      // the room ending closes for the legs it releases.
      if (plan.vanished.isNotEmpty) _tellLegsTheRoomIsParked(plan.vanished, false);
    }
    // The group is the first thing the operating system is told about these
    // calls, and the hold the server took them off is not published at all.
    // CallKit does not keep two ungrouped calls active at once - it ends one -
    // and legs of a room are exactly that the moment the server un-holds them.
    // A member of a group is active by virtue of the group, so there is
    // nothing left for a hold change to say, and the plugin refuses one on a
    // member anyway.
    await _groupLegs();
    for (final callId in plan.vanished) {
      if (hostAway) {
        // Held all the same, and heard again only at an acknowledged resume.
        final call = _calls.call(callId);
        if (call == null || call.wasHungUp || call.processingStatus == CallProcessingStatus.disconnecting) continue;
        _onCommand(SetLegHeldCommand(callId, true));
      } else if (await _calls.restoreAudio(callId)) {
        _onCommand(SetLegHeldCommand(callId, true));
      }
    }
  }

  /// Tells each leg whether the host has muted it for the room, when that
  /// changes.
  ///
  /// The server says nothing to a muted participant - every conference
  /// message goes to the host's session - so their client would show a live
  /// microphone while nobody hears them. This is the host saying so over the
  /// one channel the two of them share. Best effort by nature: it is not
  /// replayed, and a participant that was away for it learns nothing, which
  /// is why the authority stays with the server's list here.
  void _tellLegsTheirRoomMute(Map<String, bool> mutedByCallId) {
    // An older core closes the signaling socket with 4600 on a request it
    // does not know, so a hint nobody can carry must not be attempted: it
    // would cost the session the room is in.
    if (!_capabilities.isPeerMessageEnabled) return;
    for (final entry in mutedByCallId.entries) {
      final line = _calls.conference.legs[entry.key] ?? _calls.call(entry.key)?.line;
      if (line == null) continue;
      // Sent, not waited on, and each is independent: this is a hint, and
      // holding the queue on a round trip per participant would delay the
      // room's own work behind it.
      _signaling
          .execute(
            ConferenceMutePeerMessageRequest(
              transaction: WebtritSignalingClient.generateTransactionId(),
              line: line,
              callId: entry.key,
              muted: entry.value,
            ),
          )
          ?.catchError((Object e) => _logger.info('_tellLegsTheirRoomMute: $e'));
    }
  }

  /// Tells [callIds] that the host has stepped aside from the room, or come
  /// back.
  ///
  /// Cosmetic, and best effort on the same terms as [_tellLegsTheirRoomMute]:
  /// nothing on the far side can check it and nothing functional hangs on it.
  /// Sent when the parking changes, to a leg as it joins, and as `false` when
  /// the room ends - a leg that carries on as an ordinary call must not be left
  /// showing a host who stepped away from a room that no longer exists. A
  /// participant whose socket was down for it learns nothing until the next
  /// change; there is no way to notice that from here, and a heartbeat for a
  /// caption is not worth the traffic.
  void _tellLegsTheRoomIsParked(Iterable<String> callIds, bool away) {
    // An older core closes the signaling socket with 4600 on a request it does
    // not know; the same reason as in [_tellLegsTheirRoomMute].
    if (!_capabilities.isPeerMessageEnabled) return;
    for (final callId in callIds) {
      final line = _calls.conference.legs[callId] ?? _calls.call(callId)?.line;
      if (line == null) continue;
      _signaling
          .execute(
            ConferenceHostAwayPeerMessageRequest(
              transaction: WebtritSignalingClient.generateTransactionId(),
              line: line,
              callId: callId,
              away: away,
            ),
          )
          ?.catchError((Object e) => _logger.info('_tellLegsTheRoomIsParked: $e'));
    }
  }

  /// Tells the OS the legs are one grouped call. A platform that cannot
  /// group answers with an error that is not the app's; it is logged.
  Future<void> _groupLegs() async {
    final conference = _calls.conference;
    final room = conference.room;
    if (room == null || conference.legs.isEmpty) return;
    final error = await _callkeep.setCallGroup('room-$room', conference.legIds.toList());
    if (error != null) _logger.warning('_groupLegs: setCallGroup error: $error');
  }

  /// Drops the room: its connection, the OS grouping and the state. With
  /// [restoreLegs] the legs still up become ordinary calls again - audio
  /// back on each, and all but the focused one on hold. During an outside
  /// call every former leg stays locally silent and is asked to hold instead.
  /// Returns the ids of the surviving legs.
  Future<List<String>> _leaveRoom(ConferenceWrite write, {required bool restoreLegs}) async {
    _offerWait.end();
    _legMutes.forgetAll();
    final legIds = _calls.conference.legIds.toList();
    final focused = _calls.focusedCallId;
    // A room that is over mutes nobody: told before the state is cleared,
    // while the list that says who was muted is still here.
    final wereMuted = {
      for (final callId in legIds)
        if (_calls.conference.participantMuted(callId)) callId: false,
    };
    // Same reason, for the room standing aside: a leg that carries on as an
    // ordinary call would otherwise keep showing a host away from a room that
    // is gone. Read before the teardown forgets it.
    final wasParked = _conferencePeerConnection.isParked;
    // Not waited on: the mixer's connection serialises its own work, so a
    // teardown asked for while it is still opening runs after that and
    // closes it - but waiting here would hold the queue for exactly as long
    // as the operation this teardown exists to cut short. Giving the legs
    // their audio back touches their own connections, not this one.
    unawaited(_conferencePeerConnection.teardown());
    if (legIds.isNotEmpty) {
      final error = await _callkeep.unsetCallGroup(legIds);
      if (error != null) _logger.warning('_leaveRoom: unsetCallGroup error: $error');
    }
    _tellLegsTheirRoomMute(wereMuted);
    if (wasParked) _tellLegsTheRoomIsParked(legIds, false);
    final keepLegsParked = _calls.hostIsOnAnotherCall;
    write(const ConferenceUpdate(conference: ConferenceState()));
    if (!restoreLegs) return const [];
    final restored = <String>[];
    for (final callId in legIds) {
      if (keepLegsParked) {
        final call = _calls.call(callId);
        if (call == null || call.wasHungUp || call.processingStatus == CallProcessingStatus.disconnecting) continue;
        // Keep the room's existing isolation until an explicit resume succeeds;
        // neither requesting nor confirming hold needs the microphone restored.
        write(ConferenceUpdate(transitions: {callId: CallTransition.releasedFromRoom}));
        restored.add(callId);
      } else if (await _calls.restoreAudio(callId)) {
        restored.add(callId);
      }
    }
    if (restored.isEmpty) return restored;
    // One of them carries on, the rest go on hold. Which one is the focused
    // call when that is one of these, and otherwise the first: the calls
    // leave the room all active on the server, so a client that only ever
    // added holds would leave every one of them held and the user in
    // silence. A leg merged while it was held is resumed the same way.
    final live = keepLegsParked ? null : (restored.contains(focused) ? focused! : restored.first);
    for (final callId in restored) {
      _onCommand(SetLegHeldCommand(callId, callId != live));
    }
    return restored;
  }
}
