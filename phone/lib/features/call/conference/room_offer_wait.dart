import 'dart:async';

/// The wait for the mixer's offer, which is what lets the host into the room.
///
/// Two things have to be kept about that wait, and they change together, so
/// they are kept here rather than as loose fields of whoever drives the room:
///
/// - **which attempt is the current one.** Answering an offer takes a media
///   round trip and a request, and by the time either returns the room may
///   have been given up and another one asked for. Work started for an
///   earlier attempt asks [isCurrent] and stops.
/// - **when the wait is overdue.** The offer is an event, and events are not
///   replayed, so nothing but a deadline of this client's own ends a wait for
///   one that will not come.
///
/// It knows nothing of signaling or of the room's state; the owner tells it
/// what happened and is told when the deadline passes.
class RoomOfferWait {
  RoomOfferWait({required this.timeout, Timer Function(Duration, void Function())? createTimer})
    : _createTimer = createTimer ?? Timer.new;

  /// How long an offer that was asked for may take to arrive.
  final Duration timeout;

  /// Makes the deadline's timer; a test passes one it can let pass by hand.
  final Timer Function(Duration, void Function()) _createTimer;

  Timer? _deadline;
  int _attempt = 0;

  /// The attempt work started now belongs to.
  int get attempt => _attempt;

  /// Whether [attempt] is still the one in progress.
  bool isCurrent(int attempt) => attempt == _attempt;

  /// A new way into the room starts: whatever was in flight for the one
  /// before is void, and so is its deadline; work for the new one takes
  /// [attempt] from here on.
  void begin() {
    _deadline?.cancel();
    _attempt++;
  }

  /// Starts the deadline for the offer; [onOverdue] is called if it passes.
  void arm(void Function() onOverdue) {
    _deadline?.cancel();
    _deadline = _createTimer(timeout, onOverdue);
  }

  /// The offer was answered: the host is in the room.
  void offerAnswered() => _deadline?.cancel();

  /// The room is left: nothing is awaited, and anything still in flight for
  /// it is void.
  void end() {
    _deadline?.cancel();
    _attempt++;
  }

  /// Stops the deadline for good; for the owner's own disposal.
  void dispose() => _deadline?.cancel();
}
