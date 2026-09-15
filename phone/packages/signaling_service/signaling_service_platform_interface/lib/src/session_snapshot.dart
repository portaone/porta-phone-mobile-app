import 'package:signaling/signaling.dart';

/// The signaling session as it stands now, kept as state rather than as the
/// events that produced it.
///
/// A subscriber that attaches to the hub after the session started needs the
/// session's current state, not its history: which calls are up and how far
/// each got, whether the account is registered, what the server said at the
/// handshake. The server describes exactly that in a [StateHandshake], so the
/// snapshot starts from the one the session opened with and keeps it current
/// as the session's events arrive, and [toHandshake] renders it again for
/// whoever asks. The subscriber then takes the same path it takes after a
/// reconnect, where the server itself sends a handshake describing calls that
/// are already up.
///
/// What is kept current:
/// - the registration status, from the registration events (the handshake
///   always says unregistered, since SIP REGISTER has not completed yet);
/// - the lines: a call's events are prepended to its line's log, newest first
///   as the server orders them, a new call opens its line, and a hangup or a
///   missed call frees it - the line keeps its position, since the position is
///   the line's number. A call without a line number is the guest call and
///   lives in the guest slot, which counts as a line for every purpose here;
/// - the conference block: the room a `conference_offer` announced, with the
///   participants the last list carried, until the room ends. A room that came
///   and went while nobody was subscribed leaves nothing behind, and one that
///   is still up is described to the late subscriber exactly as the server
///   describes it after a reconnect.
///
/// What is not: presence and dialog snapshots, the keepalive interval and the
/// timestamp stay as the handshake reported them.
class SessionSnapshot {
  SessionSnapshot(StateHandshake handshake, {int Function()? now})
    : _base = handshake,
      _registration = handshake.registration,
      _lines = List<Line?>.of(handshake.lines),
      _guestLine = handshake.guestLine,
      _conference = handshake.conference,
      _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final StateHandshake _base;
  final int Function() _now;
  Registration _registration;
  final List<Line?> _lines;
  Line? _guestLine;
  ConferenceInfo? _conference;

  /// Whether a call is up on any line, the guest line included. A line the
  /// handshake reported counts even before an event of its call arrives.
  bool get hasActiveCalls => _guestLine != null || _lines.any((line) => line != null);

  /// The session as a [StateHandshake] the server could have sent now.
  StateHandshake toHandshake() => StateHandshake(
    keepaliveInterval: _base.keepaliveInterval,
    timestamp: _base.timestamp,
    registration: _registration,
    lines: List<Line?>.unmodifiable(_lines),
    presenceInfos: _base.presenceInfos,
    dialogInfos: _base.dialogInfos,
    guestLine: _guestLine,
    conference: _conference,
  );

  /// Folds [event] into the snapshot. Events that carry no session state are
  /// left alone.
  void apply(Event event) {
    switch (event) {
      case RegisteringEvent():
        _registration = const Registration(status: RegistrationStatus.registering);
      case RegisteredEvent():
        _registration = const Registration(status: RegistrationStatus.registered);
      case RegistrationFailedEvent(:final code, :final reason):
        _registration = Registration(status: RegistrationStatus.registration_failed, code: code, reason: reason);
      case UnregisteringEvent():
        _registration = const Registration(status: RegistrationStatus.unregistering);
      case UnregisteredEvent():
        _registration = const Registration(status: RegistrationStatus.unregistered);
      case ConferenceOfferEvent(:final room, :final participants):
        _conference = ConferenceInfo(room: room, participants: participants);
      case ConferenceUpdatedEvent(:final room, :final participants):
        _conference = ConferenceInfo(room: room, participants: participants);
      case ConferenceTerminatedEvent():
      case ConferenceFailedEvent():
        // Both are terminal for the room; nothing about it follows.
        _conference = null;
      case CallEvent():
        _applyCallEvent(event);
      default:
        break;
    }
  }

  void _applyCallEvent(CallEvent event) {
    final ended = event is HangupEvent || event is MissedCallEvent;
    final index = _lines.indexWhere((line) => line?.callId == event.callId);
    if (index >= 0) {
      _lines[index] = ended ? null : _lines[index]!._prepending(_log(event));
      return;
    }
    if (_guestLine?.callId == event.callId) {
      _guestLine = ended ? null : _guestLine!._prepending(_log(event));
      return;
    }
    if (ended) return;
    // A call the handshake did not know: an incoming call, or one placed by
    // another subscriber. Its line number is where the server will report it;
    // no number means the guest line.
    final line = event.line;
    if (line == null) {
      _guestLine = Line(callId: event.callId, callLogs: [_log(event)]);
      return;
    }
    while (_lines.length <= line) {
      _lines.add(null);
    }
    _lines[line] = Line(callId: event.callId, callLogs: [_log(event)]);
  }

  CallEventLog _log(CallEvent event) => CallEventLog(timestamp: _now(), callEvent: event);
}

extension on Line {
  Line _prepending(CallEventLog log) => Line(callId: callId, callLogs: [log, ...callLogs]);
}
