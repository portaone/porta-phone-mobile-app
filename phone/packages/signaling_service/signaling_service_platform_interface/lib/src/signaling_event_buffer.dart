import 'models/signaling_module_event.dart';
import 'package:signaling/signaling.dart';

import 'session_snapshot.dart';

/// What a late subscriber of a [SignalingModuleEvent] stream receives: the
/// session's lifecycle so far, and its state as it stands now.
///
/// The rules, shared by every replay boundary - the module that owns the
/// socket, the foreground-service hub, the module that proxies it in the app
/// isolate and the plugin that fronts them all - so that no two of them
/// disagree about the session:
/// - [SignalingConnecting] starts a new session: everything before it is gone;
/// - lifecycle events are kept in order and replayed as they came;
/// - the handshake is kept as a [SessionSnapshot], folded with every protocol
///   event that changes session state (registration, a call's events), and
///   replayed as the handshake the server would send now - a ringing call as a
///   line whose log carries the offer, an ended call gone;
/// - protocol events themselves are never replayed: what they changed is in
///   the snapshot, and the rest (ICE candidates, DTMF, a media state that a
///   live call already applied) is not actionable later.
///
/// Call [onEvent] for every emitted event, then [snapshot] to replay to a late
/// subscriber.
class SignalingEventBuffer {
  SignalingEventBuffer({int Function()? now}) : _now = now;

  final int Function()? _now;

  /// The lifecycle events in order; `null` marks where the handshake goes.
  final _lifecycle = <SignalingModuleEvent?>[];
  SessionSnapshot? _session;

  /// Whether a call is up on any line of the session, as the snapshot knows it.
  bool get hasActiveCalls => _session?.hasActiveCalls ?? false;

  /// The session as it stands now: the handshake it opened with, kept
  /// current by every event since - a hangup frees its line, a registration
  /// event updates the status. `null` before a handshake.
  StateHandshake? get sessionHandshake => _session?.toHandshake();

  /// Records [event] into the buffer according to the contract above.
  void onEvent(SignalingModuleEvent event) {
    switch (event) {
      case SignalingConnecting():
        clear();
        _lifecycle.add(event);
      case SignalingHandshakeReceived(:final handshake):
        // One slot per session: a further handshake, should a server ever send
        // one, replaces the state and is not replayed twice.
        if (_session == null) _lifecycle.add(null);
        _session = SessionSnapshot(handshake, now: _now);
      case SignalingProtocolEvent(:final event):
        _session?.apply(event);
      default:
        _lifecycle.add(event);
    }
  }

  /// A snapshot of what to replay to a new subscriber: the lifecycle events,
  /// with the handshake rendered from the session as it stands now.
  List<SignalingModuleEvent> get snapshot {
    final session = _session;
    return [
      for (final event in _lifecycle)
        if (event != null) event else if (session != null) SignalingHandshakeReceived(handshake: session.toHandshake()),
    ];
  }

  /// Clears the buffer and the session state.
  void clear() {
    _lifecycle.clear();
    _session = null;
  }
}
