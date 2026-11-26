// What the conference room and its owner say to each other: what the room
// reads of the calls around it (ConferenceCalls), how it changes the owner's
// state (ConferenceUpdate through a ConferenceWrite), and what it raises -
// a ConferenceCommand for something only the owner can do to a call, a
// ConferenceStep for a continuation that takes its turn in the owner's queue,
// a ConferenceNotice for something the user is to be told.
// Used by ConferenceRoom and the parts of it that raise the same (RoomVideo),
// and by the room's owner, CallBloc. Types only: what each means is done by
// the room and its owner.
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import '../models/active_call.dart';
import '../models/call_audio.dart';
import '../models/call_transition.dart';
import '../models/conference_membership_plan.dart';
import '../models/conference_request_result.dart';
import '../models/conference_state.dart';
import '../models/invited_conference_video.dart';
import 'conference_video_session.dart';

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

  /// Every call there is, in the room or not.
  Iterable<ActiveCall> get all;
}

/// One change of the owner's state the room asks for, applied as a whole.
class ConferenceUpdate {
  const ConferenceUpdate({
    this.conference,
    this.unheld = const {},
    this.transitions = const {},
    this.settleFocus = false,
    this.frontCamera = const {},
    this.invitedVideo,
  });

  /// The room as it is from now on; `null` leaves it as it was.
  final ConferenceState? conference;

  /// Calls the server took off hold as they joined.
  final Set<String> unheld;

  /// The transition each of these calls is in from now on; `null` for none.
  final Map<String, CallTransition?> transitions;

  /// Whether the focus a placed call was waiting for is settled with this.
  final bool settleFocus;

  /// The camera each of these calls shows now: the front one when `true`.
  final Map<String, bool> frontCamera;

  /// The video of somebody else's room this client was invited to, as it is
  /// from now on: `(value: null)` ends it; `null` leaves it as it was.
  final ({InvitedConferenceVideo? value})? invitedVideo;
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

/// Turn the camera of [callId] on or off: the room's camera is shared with
/// the calls that send video.
final class SetLegCameraCommand extends ConferenceCommand {
  const SetLegCameraCommand(this.callId, this.enabled);

  /// The call whose camera changes.
  final String callId;

  /// Whether its camera is to be on.
  final bool enabled;
}

/// Retry the merge of [callIds]: they are on the conference codecs.
final class RetryMergeCommand extends ConferenceCommand {
  const RetryMergeCommand(this.callIds);

  /// The calls to merge.
  final List<String> callIds;
}

/// Retry adding [callId] to the room: it is on the conference codecs.
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

/// The camera could not be opened for the room's video: no permission, or
/// another app holds it.
final class CameraUnavailableNotice extends ConferenceNotice {
  const CameraUnavailableNotice();
}

/// The room ended while calls were still up; they go on as ordinary calls.
final class RoomEndedNotice extends ConferenceNotice {
  const RoomEndedNotice();
}

/// The room would not take this client's shared screen, or let it go for
/// good: the share has nowhere to go and is to be stopped.
final class ScreenShareLostNotice extends ConferenceNotice {
  const ScreenShareLostNotice();
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

/// The cameras and screens the room's video sends changed, or its presenter.
final class VideoFeedsChangedStep extends ConferenceStep {
  const VideoFeedsChangedStep(this.feeds, {this.presenter});

  /// Every feed the video session receives now.
  final List<ConferenceVideoFeed> feeds;

  /// Whoever shares a screen, as the room says; `null` while nobody does.
  final int? presenter;
}

/// The participant the room shows as speaking changed: the room's word for
/// whoever started talking last, held against flicker (`SpeakerHold`).
final class SpeakerChangedStep extends ConferenceStep {
  const SpeakerChangedStep(this.speaker);

  /// The speaker's feed; `null` while nobody has spoken or the video is left.
  final int? speaker;
}

/// The server refused the room's video with `video_disabled`.
final class VideoDisabledStep extends ConferenceStep {
  const VideoDisabledStep();
}

/// The room's camera was switched: [frontCamera] is in use on [trackId] now.
final class CameraSwitchedStep extends ConferenceStep {
  const CameraSwitchedStep({required this.frontCamera, required this.trackId});

  /// Whether the front camera is in use now.
  final bool frontCamera;

  /// The camera's track, shared with the calls that send it.
  final String trackId;
}

/// What the session did with the rejoin.
final class RejoinRepliedStep extends ConferenceStep {
  const RejoinRepliedStep({required this.attempt, required this.result});

  /// The attempt the rejoin was asked in.
  final int attempt;

  /// What became of the request.
  final ConferenceRequestResult result;
}
