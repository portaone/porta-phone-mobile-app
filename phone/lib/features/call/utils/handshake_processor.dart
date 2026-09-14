import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

/// Actions returned by [HandshakeProcessor.process] describing what the BLoC
/// should do after processing the signaling [StateHandshake].
sealed class HandshakeAction {
  const HandshakeAction();
}

/// Send a [HangupRequest] to the signaling server and stop processing.
///
/// Emitted in two cases:
/// 1. The Callkeep connection is [CallkeepConnectionState.stateDisconnected] and
///    the latest call event is neither [HangupEvent] nor [MissedCallEvent]
///    (i.e. the call was live when the connection dropped).
/// 2. The Callkeep connection is null (removed or iOS), the call is not tracked
///    in BLoC state, has no [AcceptedEvent] in its log, and the latest event is
///    not a terminal or incoming event — i.e. an orphaned outgoing call whose
///    [HangupRequest] was lost while the device was offline.
final class HangupSignalingAction extends HandshakeAction {
  const HangupSignalingAction({required this.line, required this.callId});

  final int? line;
  final String callId;
}

/// Send a [DeclineRequest] to the signaling server and stop processing.
///
/// Emitted when the Callkeep connection for the line is [CallkeepConnectionState.stateDisconnected]
/// and the latest call event is [IncomingCallEvent].
final class DeclineSignalingAction extends HandshakeAction {
  const DeclineSignalingAction({required this.line, required this.callId});

  final int? line;
  final String callId;
}

/// Re-negotiate WebRTC media for an already-accepted call after app restart.
///
/// Emitted when the call log contains an [AcceptedEvent] (anywhere in the list,
/// not necessarily the latest — re-INVITE puts [UpdatedEvent] on top), the call is
/// not server-terminated ([HangupEvent]/[MissedCallEvent] as the latest entry),
/// [AcceptedEvent.line] is non-null, and the call is not already tracked in BLoC state.
/// - [incomingCallEvent] is non-null for incoming calls (provides offer SDP and caller).
/// - [incomingCallEvent] is null for outgoing calls (callee is taken from [acceptedEvent]).
final class RestoreCallAction extends HandshakeAction {
  const RestoreCallAction({
    required this.line,
    required this.callId,
    required this.acceptedEvent,
    required this.acceptedTime,
    this.incomingCallEvent,
    this.mediaState,
  });

  final int line;
  final String callId;
  final AcceptedEvent acceptedEvent;
  final DateTime acceptedTime;
  final IncomingCallEvent? incomingCallEvent;

  /// The remote side's latest media state, when the log carries one: the
  /// caller may have turned the camera off while nobody here was listening.
  final MediaStatePeerMessageEvent? mediaState;
}

/// Deliver an unanswered [IncomingCallEvent] to the BLoC signaling handler.
///
/// Emitted when the line has not been terminated, has no [AcceptedEvent], the
/// earliest call log entry is an [IncomingCallEvent], and the call is not yet
/// tracked in BLoC state.
final class HandleIncomingCallAction extends HandshakeAction {
  const HandleIncomingCallAction({required this.event, this.mediaState});

  final IncomingCallEvent event;

  /// The remote side's latest media state after the offer, when the log
  /// carries one. A live call would have applied it as it came; a call
  /// restored from the log is answered as the caller left it - a video offer
  /// downgraded to audio is answered as audio.
  final MediaStatePeerMessageEvent? mediaState;
}

/// Hand the offer found in the log to a call the BLoC already tracks but
/// never received a live [IncomingCallEvent] for.
///
/// A push registers the call before the socket is up; the offer normally
/// follows as a live event, and when the socket was down at that moment the
/// event never comes and [LocalCall.hasOffer] stays false. The next handshake
/// carries the original [IncomingCallEvent] with the offer inside the call's
/// log, and the answer path cannot proceed without it. The BLoC treats this
/// exactly as [HandleIncomingCallAction]: the incoming handler stores the
/// offer in the existing call and reports it to callkeep a second time, which
/// answers `callIdAlreadyExists*` and is handled.
///
/// Emitted after the per-line actions and only when no
/// [HangupSignalingAction]/[DeclineSignalingAction] cut the plan short: the
/// BLoC stops at those, and an offer is of no use to a session being torn down.
final class DeliverOfferAction extends HandshakeAction {
  const DeliverOfferAction({required this.event, this.mediaState});

  final IncomingCallEvent event;

  /// The remote side's latest media state after the offer, when the log
  /// carries one - see [HandleIncomingCallAction.mediaState].
  final MediaStatePeerMessageEvent? mediaState;
}

/// Call [Callkeep.endCall] for a local connection that is no longer present in
/// the signaling state.
final class EndLocalCallAction extends HandshakeAction {
  const EndLocalCallAction({required this.callId});

  final String callId;
}

/// Send a [ConferenceHangupRequest]: the server reports a conference room on
/// this session that the client cannot rejoin.
///
/// The room lives on the media server and outlives a signaling drop, but the
/// client's own connection to it does not survive an app restart, and a room
/// is never rejoined - the server offers it once. Left standing it would keep
/// its participants in the mix with nobody hosting them, and refuse every
/// later merge as `conference_already_active` for the rest of the session.
/// Hanging the room up leaves the calls in it untouched; they are restored
/// like any other call. Emitted first, before the per-line actions, since the
/// BLoC stops after a [HangupSignalingAction] or [DeclineSignalingAction].
final class HangupStaleConferenceAction extends HandshakeAction {
  const HangupStaleConferenceAction({required this.room});

  final int room;
}

/// A call the BLoC already tracks, as much of it as the handshake plan needs.
///
/// The plan is decided against the local state without depending on it: the
/// BLoC describes its calls in these terms and executes what comes back.
final class LocalCall {
  const LocalCall({required this.callId, required this.status, required this.hasOffer});

  final String callId;
  final CallProcessingStatus status;

  /// Whether the call already holds its SDP offer.
  final bool hasOffer;

  /// A call registered from a push whose offer never arrived as a live event,
  /// whichever of the answer's steps it has reached meanwhile: the answer
  /// waits for the offer and times out without it.
  bool get awaitsOffer =>
      !hasOffer &&
      switch (status) {
        CallProcessingStatus.incomingFromPush ||
        CallProcessingStatus.incomingSubmittedAnswer ||
        CallProcessingStatus.incomingPerformingStarted => true,
        _ => false,
      };
}

/// Processes a [StateHandshake] and returns the list of [HandshakeAction]s the
/// BLoC should execute.
///
/// Separating the decision logic from execution (signaling calls, callkeep calls,
/// BLoC event dispatch) keeps this class free of side effects and makes it
/// straightforward to unit-test with only a mocked [CallkeepConnections].
///
/// The processor handles two loops from the original [CallBloc._handleHandshakeReceived]:
///
/// **Loop B -per-line decisions:**
/// - If the Callkeep connection is [CallkeepConnectionState.stateDisconnected] and
///   the latest event is [IncomingCallEvent] -> [DeclineSignalingAction].
/// - If the Callkeep connection is [CallkeepConnectionState.stateDisconnected] and
///   the latest event is not [HangupEvent]/[MissedCallEvent] -> [HangupSignalingAction].
/// - If the log contains an [AcceptedEvent] (non-terminated call, not yet in BLoC) -> [RestoreCallAction]
///   (covers both incoming and outgoing calls; [AcceptedEvent] may not be the newest entry after re-INVITE).
/// - If the earliest log is an unanswered [IncomingCallEvent] (not terminated, not accepted, not in BLoC) -> [HandleIncomingCallAction].
/// - If the line's call is in the BLoC but still waiting for its offer
///   ([LocalCall.awaitsOffer]) and the log carries an [IncomingCallEvent] with
///   one -> [DeliverOfferAction], appended after the per-line actions.
///
/// **Loop C -orphaned local connections:**
/// - For each local Callkeep connection whose call ID is absent from the handshake
///   lines -> [EndLocalCallAction].
///
/// **The conference block:**
/// - A [conference] the server reports is one the client cannot rejoin, so it
///   -> [HangupStaleConferenceAction], ahead of everything else. The client keeps
///   no conference of its own yet; once it does, a room it still holds is
///   adopted or forgotten instead (`docs/conference_protocol.md`, section 7).
///
/// When queued terminations exist in the repository, they are emitted first as
/// regular [HangupSignalingAction]/[DeclineSignalingAction] entries, removed
/// from the repository immediately, and excluded from subsequent handshake-line
/// processing.
///
/// If a terminal disconnected-state action is produced during line traversal,
/// the processor exits early to match the original `return` semantics, while
/// preserving any already-collected queued actions.
class HandshakeProcessor {
  HandshakeProcessor({required this.callkeepConnections, required this.queuedTerminationRequestsRepository});

  final CallkeepConnections callkeepConnections;
  final QueuedTerminationRequestsRepository queuedTerminationRequestsRepository;

  Future<List<HandshakeAction>> process({
    required List<Line?> lines,
    required Line? guestLine,
    required Iterable<LocalCall> localCalls,
    ConferenceInfo? conference,
  }) async {
    final actions = <HandshakeAction>[if (conference != null) HangupStaleConferenceAction(room: conference.room)];
    final activeCallIds = localCalls.map((call) => call.callId).toSet();
    final callIdsAwaitingOffer = localCalls.where((call) => call.awaitsOffer).map((call) => call.callId).toSet();
    // Kept apart from [actions]: an early return above leaves them out, as an
    // offer is of no use to a session being torn down.
    final offerActions = <DeliverOfferAction>[];

    /// Prepare termination queue actions
    final queuedTerminationCallIds = <String>{};
    final queuedTerminationRequests = queuedTerminationRequestsRepository.getAll;

    for (final request in queuedTerminationRequests.values) {
      switch (request.type) {
        case QueuedTerminationRequestType.hangup:
          actions.add(HangupSignalingAction(line: request.line, callId: request.callId));
        case QueuedTerminationRequestType.decline:
          actions.add(DeclineSignalingAction(line: request.line, callId: request.callId));
      }
      queuedTerminationRequestsRepository.remove(request);
      queuedTerminationCallIds.add(request.callId);
    }

    /// Prepare callkeep connections actions
    final allLines = [
      ...lines,
      guestLine,
    ].whereType<Line>().where((line) => !queuedTerminationCallIds.contains(line.callId)).toList();
    final localConnections = await callkeepConnections.getConnections();

    for (final activeLine in allLines) {
      // callLogs is newest-first: firstOrNull = latest, lastOrNull = earliest.
      // Materialise once and reuse for both the connection guards below and the
      // restoration logic further down to avoid redundant traversals.
      final callEventLogEntries = activeLine.callLogs.whereType<CallEventLog>().toList();
      final callEvent = callEventLogEntries.firstOrNull?.callEvent; // latest event
      final earliestCallEvent = callEventLogEntries.lastOrNull?.callEvent;

      // AcceptedEvent may not be the latest entry after a re-INVITE or transfer -
      // search the full log list rather than checking only the newest entry.
      final acceptedLogEntry = callEventLogEntries.where((log) => log.callEvent is AcceptedEvent).firstOrNull;
      // Newest first, so the first media state found is the one that stands.
      final mediaState = callEventLogEntries
          .map((log) => log.callEvent)
          .whereType<MediaStatePeerMessageEvent>()
          .firstOrNull;

      CallkeepConnection? connection;
      if (callEvent != null) {
        connection = await callkeepConnections.getConnection(callEvent.callId);

        if (connection?.state == CallkeepConnectionState.stateDisconnected) {
          if (callEvent is IncomingCallEvent) {
            return [...actions, DeclineSignalingAction(line: callEvent.line, callId: callEvent.callId)];
          } else if (callEvent is! HangupEvent && callEvent is! MissedCallEvent) {
            return [...actions, HangupSignalingAction(line: callEvent.line, callId: callEvent.callId)];
          }
        } else if (connection == null &&
            !activeCallIds.contains(activeLine.callId) &&
            earliestCallEvent is! IncomingCallEvent &&
            callEvent is! HangupEvent &&
            callEvent is! MissedCallEvent &&
            acceptedLogEntry == null) {
          // Orphaned outgoing call: the server still has the call but both
          // CallKeep and BLoC have no record of it. This happens when the user
          // hangs up while offline — performEndCall removed the local state but
          // the HangupRequest never reached the server.
          //
          // earliestCallEvent (not callEvent/latest) is used to identify the
          // call direction: after a ProceedingEvent or RingingEvent the latest
          // entry is no longer IncomingCallEvent, so using callEvent here would
          // incorrectly trigger HangupSignalingAction for unanswered incoming calls.
          //
          // acceptedLogEntry == null ensures we never hang up a call that should
          // be restored (app-restart case where connection is null but the call
          // was previously accepted).
          //
          // On iOS getConnection() always returns null, so activeCallIds is the
          // decisive guard: calls that are still active in BLoC are not affected.
          return [...actions, HangupSignalingAction(line: callEvent.line, callId: callEvent.callId)];
        }
      }

      // A call is server-terminated when the latest event is a final hangup or missed.
      final isTerminated = callEvent is HangupEvent || callEvent is MissedCallEvent;

      if (!isTerminated &&
          acceptedLogEntry != null &&
          (acceptedLogEntry.callEvent as AcceptedEvent).line != null &&
          !activeCallIds.contains(activeLine.callId)) {
        final acceptedEvent = acceptedLogEntry.callEvent as AcceptedEvent;
        actions.add(
          RestoreCallAction(
            line: acceptedEvent.line!,
            callId: activeLine.callId,
            acceptedEvent: acceptedEvent,
            acceptedTime: DateTime.fromMillisecondsSinceEpoch(acceptedLogEntry.timestamp),
            incomingCallEvent: earliestCallEvent is IncomingCallEvent ? earliestCallEvent : null,
            mediaState: mediaState,
          ),
        );
        continue;
      }

      // Unanswered incoming call: deliver the IncomingCallEvent to the BLoC so
      // it can set up the call state and surface the ringing UI.
      //
      // earliestCallEvent (not callEvent/latest) identifies the call direction
      // because SIP UAs — notably iOS CallKit — append RingingEvent or
      // ProceedingEvent almost immediately after the call is placed. By the time
      // a WebSocket reconnect completes and a new StateHandshake arrives, the
      // server log already contains multiple entries (e.g. [RingingEvent,
      // IncomingCallEvent]). Using the latest entry would misidentify those calls.
      //
      // Guard rationale:
      // - !isTerminated           : skip calls the server already ended.
      // - acceptedLogEntry == null: accepted calls are handled by RestoreCallAction above.
      // - earliestCallEvent is IncomingCallEvent: confirms the call is incoming, not outgoing.
      // - !activeCallIds.contains : skip calls already tracked in BLoC state to avoid
      //   re-triggering the incoming-call flow for an already-ringing call.
      if (!isTerminated &&
          acceptedLogEntry == null &&
          earliestCallEvent is IncomingCallEvent &&
          !activeCallIds.contains(activeLine.callId)) {
        actions.add(HandleIncomingCallAction(event: earliestCallEvent, mediaState: mediaState));
      }

      // A call the BLoC registered from a push and is still waiting to hear
      // the offer for: the newest log entry carrying one is the offer, and it
      // is delivered once per line.
      if (callIdsAwaitingOffer.contains(activeLine.callId)) {
        final offerEvent = callEventLogEntries
            .map((log) => log.callEvent)
            .whereType<IncomingCallEvent>()
            .where((event) => event.jsep != null)
            .firstOrNull;
        if (offerEvent != null) {
          offerActions.add(DeliverOfferAction(event: offerEvent, mediaState: mediaState));
        }
      }
    }

    final lineCallIds = allLines.map((l) => l.callId).toSet();
    for (final connection in localConnections) {
      if (!lineCallIds.contains(connection.callId) && !activeCallIds.contains(connection.callId)) {
        actions.add(EndLocalCallAction(callId: connection.callId));
      }
    }

    return [...actions, ...offerActions];
  }
}
