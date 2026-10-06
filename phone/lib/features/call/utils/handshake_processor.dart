import 'package:logging/logging.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

final _logger = Logger('HandshakeProcessor');

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
/// event never comes and [ActiveCall.incomingOffer] stays null. The next handshake
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

/// Drop the conference the client still holds: the session the server
/// describes has none, or has a different one.
///
/// The room is gone whatever became of it - it ended while the socket was
/// down, or the server started a new one - and the calls that were in it are
/// ordinary calls again, so the client restores their audio and holds all but
/// the one in focus, exactly as it does for a `conference_terminated`.
/// Emitted after [HangupStaleConferenceAction], so a room that is both stale
/// on the server and held here is ended there before being dropped here.
final class ForgetConferenceAction extends HandshakeAction {
  const ForgetConferenceAction();
}

/// Take the server's account of the room the client is still connected to.
///
/// A room outlives a signaling drop: the media server keeps mixing while the
/// socket is down, so a client that comes back with its own connection to the
/// mixer intact simply carries on. What it cannot assume is the membership -
/// a leg may have hung up meanwhile - so the handshake's list is adopted the
/// same way a `conference_updated` is: it replaces the local one.
final class AdoptConferenceAction extends HandshakeAction {
  const AdoptConferenceAction({required this.room, required this.participants});

  final int room;
  final List<ConferenceParticipant> participants;
}

/// Processes a [StateHandshake] and returns the list of [HandshakeAction]s the
/// BLoC should execute.
///
/// The plan is a pure function of its inputs - the session's lines as the
/// signaling module knows them now, the BLoC's calls, and the callkeep
/// connections the BLoC read for it - and is computed in one synchronous
/// step. Nothing is awaited in here: the BLoC gathers the callkeep reads
/// first, then plans and executes in the same turn, so nothing can change
/// under the plan between deciding and acting on it. What arrives while the
/// reads are in flight reaches the plan as input (a freed line, a call in
/// [activeCalls]) instead of being overtaken by it.
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
///   ([ActiveCall.awaitsOffer]) and the log carries an [IncomingCallEvent] with
///   one -> [DeliverOfferAction], appended after the per-line actions.
///
/// **Loop C -orphaned local connections:**
/// - For each local Callkeep connection whose call ID is absent from the handshake
///   lines -> [EndLocalCallAction].
///
/// **The conference block** (`docs/conference_protocol.md`, section 7), ahead
/// of everything else, from the room the server reports ([conference]) and the
/// one the client holds ([localConference]):
/// - the same room on both sides -> [AdoptConferenceAction]: the room survived
///   the drop, only its membership is the server's to state;
/// - a room only the server has -> [HangupStaleConferenceAction]: it cannot be
///   rejoined, and left standing it refuses every later merge;
/// - a room only the client has -> [ForgetConferenceAction]: it is over, and
///   its legs are calls again;
/// - different rooms on the two sides -> both, in that order.
///
/// [ConferenceState.room] is the whole test of what the client holds: the id
/// arrives with the room's offer, which is what the client answers to connect
/// to the mixer. A merge that was still assembling when the socket dropped has
/// none, and the server sends one offer per room, so there is nothing to come
/// back to - it is dropped like any other room the server does not report.
///
/// When queued terminations exist in the repository, they are emitted first as
/// regular [HangupSignalingAction]/[DeclineSignalingAction] entries and
/// excluded from subsequent handshake-line processing. A record stays until
/// the server confirms the end; one for a call the session no longer carries
/// is dropped here instead of being sent.
///
/// If a terminal disconnected-state action is produced during line traversal,
/// the processor exits early to match the original `return` semantics, while
/// preserving any already-collected queued actions.
class HandshakeProcessor {
  HandshakeProcessor({required this.queuedTerminationRequestsRepository});

  final QueuedTerminationRequestsRepository queuedTerminationRequestsRepository;

  /// Plans the actions for a handshake.
  ///
  /// [connections] is every local callkeep connection ([CallkeepConnections.getConnections])
  /// and [lineConnections] the connection callkeep reports for a line's
  /// latest call id ([CallkeepConnections.getConnection]), both read by the
  /// caller just before this.
  List<HandshakeAction> process({
    required List<Line?> lines,
    required Line? guestLine,
    required Iterable<ActiveCall> activeCalls,
    List<CallkeepConnection> connections = const [],
    Map<String, CallkeepConnection?> lineConnections = const {},
    ConferenceInfo? conference,
    ConferenceState localConference = const ConferenceState(),
  }) {
    final actions = <HandshakeAction>[..._conferenceActions(conference, localConference)];
    final activeCallIds = activeCalls.map((call) => call.callId).toSet();
    final callIdsAwaitingOffer = activeCalls.where((call) => call.awaitsOffer).map((call) => call.callId).toSet();
    // What is handed to a call the BLoC already holds. Kept apart from
    // [actions]: an early return below leaves them out, as an offer is of no
    // use to a session being torn down.
    final deliveries = <HandshakeAction>[];

    final queuedTerminationCallIds = _planQueuedTerminations(lines, guestLine, actions);

    final allLines = [
      ...lines,
      guestLine,
    ].whereType<Line>().where((line) => !queuedTerminationCallIds.contains(line.callId)).toList();

    for (final line in allLines) {
      final log = _LineLog(line);

      final teardown = _teardownAction(log, lineConnections, activeCallIds);
      if (teardown != null) return [...actions, teardown];

      final restore = _restoreAction(log, activeCallIds);
      if (restore != null) {
        _logger.info('process: call ${log.callId} is accepted on the server and not in the bloc, restoring it');
        actions.add(restore);
        continue;
      }
      var planned = false;

      // Unanswered incoming call: deliver the IncomingCallEvent to the BLoC so
      // it can set up the call state and surface the ringing UI.
      //
      // The earliest event (not the latest) identifies the call direction
      // because SIP UAs — notably iOS CallKit — append RingingEvent or
      // ProceedingEvent almost immediately after the call is placed. By the time
      // a WebSocket reconnect completes and a new StateHandshake arrives, the
      // server log already contains multiple entries (e.g. [RingingEvent,
      // IncomingCallEvent]). Using the latest entry would misidentify those calls.
      //
      // Guard rationale:
      // - not terminated          : skip calls the server already ended.
      // - not accepted            : accepted calls are handled by RestoreCallAction above.
      // - earliest is IncomingCallEvent: confirms the call is incoming, not outgoing.
      // - not in activeCallIds    : skip calls already tracked in BLoC state to avoid
      //   re-triggering the incoming-call flow for an already-ringing call.
      final earliest = log.earliest;
      if (!log.isTerminated &&
          log.accepted == null &&
          earliest is IncomingCallEvent &&
          !activeCallIds.contains(log.callId)) {
        _logger.info('process: call ${log.callId} is an unanswered incoming call not in the bloc, handing it over');
        actions.add(HandleIncomingCallAction(event: earliest, mediaState: log.mediaState));
        planned = true;
      }

      // A call the BLoC registered from a push and is still waiting to hear
      // the offer for: the newest log entry carrying one is the offer, and it
      // is delivered once per line.
      if (callIdsAwaitingOffer.contains(log.callId)) {
        final offer = log.offer;
        if (offer != null) {
          _logger.info('process: call ${log.callId} waits in the bloc for its offer, delivering it from the log');
          deliveries.add(DeliverOfferAction(event: offer, mediaState: log.mediaState));
          planned = true;
        }
      }

      if (!planned) {
        _logger.info(
          'process: call ${log.callId} needs nothing: inBloc=${activeCallIds.contains(log.callId)} '
          'terminated=${log.isTerminated} accepted=${log.accepted != null}',
        );
      }
    }

    actions.addAll(_orphanedConnectionActions(connections, allLines, activeCallIds));

    return [...actions, ...deliveries];
  }

  /// Adds to [actions] the terminations recorded while the server could not
  /// be told, and returns the ids of their calls: those lines are not planned
  /// as calls.
  Set<String> _planQueuedTerminations(List<Line?> lines, Line? guestLine, List<HandshakeAction> actions) {
    final callIds = <String>{};

    for (final request in queuedTerminationRequestsRepository.getAll.values) {
      // A recorded termination is an intent to end the call, kept until the
      // server confirms it: a hangup for the call, a refusal of the request,
      // or - decided here - a session that no longer carries the call, in
      // which case there is nothing left to end. A call ended natively before
      // its offer arrived was recorded without a line; the session shows
      // which line carries it now. The record is not consumed by the replay:
      // it goes with the request through the same lifecycle as an immediate
      // end, and until it is confirmed the line is not planned as a call.
      final isGuest = guestLine?.callId == request.callId;
      final index = lines.indexWhere((line) => line?.callId == request.callId);
      if (!isGuest && index < 0) {
        _logger.info(
          'process: queued ${request.type.name} of call ${request.callId} dropped, the session no longer carries the call',
        );
        queuedTerminationRequestsRepository.remove(request);
        continue;
      }
      _logger.info('process: replaying the queued ${request.type.name} of call ${request.callId}');
      final line = request.line ?? (isGuest ? null : index);
      switch (request.type) {
        case QueuedTerminationRequestType.hangup:
          actions.add(HangupSignalingAction(line: line, callId: request.callId));
        case QueuedTerminationRequestType.decline:
          actions.add(DeclineSignalingAction(line: line, callId: request.callId));
      }
      callIds.add(request.callId);
    }

    return callIds;
  }

  /// The action that ends the plan at this line, if the line calls for one:
  /// the session is being torn down, and nothing planned after it is of use.
  HandshakeAction? _teardownAction(
    _LineLog log,
    Map<String, CallkeepConnection?> lineConnections,
    Set<String> activeCallIds,
  ) {
    final latest = log.latest;
    if (latest == null) return null;
    final connection = lineConnections[latest.callId];

    if (connection?.state == CallkeepConnectionState.stateDisconnected) {
      if (latest is IncomingCallEvent) {
        _logger.warning(
          'process: call ${latest.callId} is disconnected in callkeep and still rings on the server, declining it; '
          'the plan ends here',
        );
        return DeclineSignalingAction(line: latest.line, callId: latest.callId);
      } else if (!log.isTerminated) {
        _logger.warning(
          'process: call ${latest.callId} is disconnected in callkeep and still up on the server, hanging it up; '
          'the plan ends here',
        );
        return HangupSignalingAction(line: latest.line, callId: latest.callId);
      }
    } else if (connection == null &&
        !activeCallIds.contains(log.callId) &&
        log.earliest is! IncomingCallEvent &&
        !log.isTerminated &&
        log.accepted == null) {
      // Orphaned outgoing call: the server still has the call but both
      // CallKeep and BLoC have no record of it. This happens when the user
      // hangs up while offline — performEndCall removed the local state but
      // the HangupRequest never reached the server.
      //
      // The earliest event (not the latest) is used to identify the call
      // direction: after a ProceedingEvent or RingingEvent the latest entry
      // is no longer IncomingCallEvent, so using the latest here would
      // incorrectly trigger HangupSignalingAction for unanswered incoming calls.
      //
      // No accepted entry ensures we never hang up a call that should be
      // restored (app-restart case where connection is null but the call was
      // previously accepted).
      //
      // On iOS getConnection() always returns null, so activeCallIds is the
      // decisive guard: calls that are still active in BLoC are not affected.
      _logger.warning(
        'process: call ${latest.callId} is up on the server while neither callkeep nor the bloc has it, hanging it up; '
        'the plan ends here',
      );
      return HangupSignalingAction(line: latest.line, callId: latest.callId);
    }
    return null;
  }

  /// A call the server holds as answered and the BLoC does not have.
  RestoreCallAction? _restoreAction(_LineLog log, Set<String> activeCallIds) {
    final accepted = log.accepted;
    if (log.isTerminated || accepted == null || activeCallIds.contains(log.callId)) return null;
    final acceptedEvent = accepted.callEvent as AcceptedEvent;
    final line = acceptedEvent.line;
    if (line == null) return null;

    final earliest = log.earliest;
    return RestoreCallAction(
      line: line,
      callId: log.callId,
      acceptedEvent: acceptedEvent,
      acceptedTime: DateTime.fromMillisecondsSinceEpoch(accepted.timestamp),
      incomingCallEvent: earliest is IncomingCallEvent ? earliest : null,
      mediaState: log.mediaState,
    );
  }

  /// A local Callkeep connection whose call neither the session nor the BLoC
  /// has is ended.
  List<HandshakeAction> _orphanedConnectionActions(
    List<CallkeepConnection> connections,
    List<Line> allLines,
    Set<String> activeCallIds,
  ) {
    final lineCallIds = allLines.map((line) => line.callId).toSet();
    final actions = <HandshakeAction>[];
    for (final connection in connections) {
      if (!lineCallIds.contains(connection.callId) && !activeCallIds.contains(connection.callId)) {
        _logger.info(
          'process: callkeep connection ${connection.callId} is in neither the session nor the bloc, ending it',
        );
        actions.add(EndLocalCallAction(callId: connection.callId));
      }
    }
    return actions;
  }

  /// What the two accounts of the room come to. Nothing when neither side has
  /// one, which is every handshake of a session that never conferenced.
  List<HandshakeAction> _conferenceActions(ConferenceInfo? conference, ConferenceState localConference) {
    if (conference != null && conference.room == localConference.room) {
      _logger.info('process: conference room ${conference.room} stands on both sides, keeping it');
      return [AdoptConferenceAction(room: conference.room, participants: conference.participants)];
    }
    if (conference != null) {
      _logger.info('process: conference room ${conference.room} is only on the server, hanging it up');
    }
    if (localConference.isPresent) {
      _logger.info('process: the conference the client holds is not on the server, forgetting it');
    }
    return [
      if (conference != null) HangupStaleConferenceAction(room: conference.room),
      if (localConference.isPresent) const ForgetConferenceAction(),
    ];
  }
}

/// What the plan reads from the log of one line. The log is newest first;
/// each fact is worked out once, when first asked for.
class _LineLog {
  _LineLog(Line line) : callId = line.callId, _events = line.callLogs.whereType<CallEventLog>().toList();

  final String callId;
  final List<CallEventLog> _events;

  late final latest = _events.firstOrNull?.callEvent;
  late final earliest = _events.lastOrNull?.callEvent;

  /// AcceptedEvent may not be the latest entry after a re-INVITE or transfer,
  /// so the whole log is searched rather than its newest entry.
  late final accepted = _events.where((log) => log.callEvent is AcceptedEvent).firstOrNull;

  /// The remote side's media state that stands: the newest one.
  late final mediaState = _events.map((log) => log.callEvent).whereType<MediaStatePeerMessageEvent>().firstOrNull;

  /// The server has ended the call: its latest event is a final hangup or a
  /// missed call.
  late final bool isTerminated = latest is HangupEvent || latest is MissedCallEvent;

  /// The newest entry that carries the caller's offer.
  late final offer = _events
      .map((log) => log.callEvent)
      .whereType<IncomingCallEvent>()
      .where((event) => event.jsep != null)
      .firstOrNull;
}
