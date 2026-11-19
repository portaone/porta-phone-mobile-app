part of 'call_bloc.dart';

// The conference mutations as steps of the room: which method of
// ConferenceRoom takes each event of the queue, and with what of the event.
// Used by CallBloc's mutation dispatch, one line for the whole family.
// Only the translation lives here; what a step does is ConferenceRoom's, and
// how a write lands in the state is CallBloc._conferenceWrite.
extension _ConferenceMutationMapping on _ConferenceMutationEvent {
  /// Hands this event to the step of [room] it stands for; [write] applies
  /// what the step changes.
  Future<void> applyTo(ConferenceRoom room, ConferenceWrite write) {
    final event = this;
    return switch (event) {
      _CallMutationEventControlMerge() => room.merge(event.callIds, write, source: '__onMutationControlMerge'),
      _CallMutationEventControlConferenceAdd() => room.addCall(
        event.callId,
        write,
        source: '__onMutationControlConferenceAdd',
      ),
      _CallMutationEventControlConferenceMute() => room.muteParticipant(event.callId, event.muted),
      _CallMutationEventControlConferenceSelfMute() => room.setSelfMuted(event.muted, write),
      _CallMutationEventControlConferenceEnd() => room.end(event.endedBy, write),
      _CallMutationEventConferenceOffer() => room.onOffer(
        room: event.room,
        jsep: event.jsep,
        participants: event.participants,
        write: write,
      ),
      _CallMutationEventConferenceRemoteCandidate() => room.onRemoteCandidate(event.candidate),
      _CallMutationEventConferenceUpdated() => room.onParticipants(
        room: event.room,
        participants: event.participants,
        write: write,
      ),
      _CallMutationEventConferenceFailed() => room.onFailed(
        room: event.room,
        reason: event.reason,
        detail: event.detail,
        write: write,
      ),
      _CallMutationEventConferenceTerminated() => room.onTerminated(room: event.room, write: write),
      _CallMutationEventConferenceRejoin() => room.rejoin(),
      _CallMutationEventConferenceStep(:final step) => room.takeStep(step, write),
    };
  }
}
