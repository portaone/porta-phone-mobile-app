import 'dart:async';

/// The wait for the mixer's offer, which is what lets the host into the room:
/// the first one after a merge, and another after every rejoin.
///
/// Three things have to be kept about that wait, and they change together, so
/// they are kept here rather than as loose fields of whoever drives the room:
///
/// - **which attempt is the current one.** Answering an offer takes a media
///   round trip and a request, and by the time either returns the room may
///   have been given up, or the host may be on his way into it over another
///   connection - or over another signaling session. Work started for an
///   earlier attempt asks [isCurrent] and stops, and what comes back from it
///   is dropped the same way.
/// - **whether this signaling session has already been asked for a rejoin.**
///   One request per session: asked twice, the server moves the host onto a
///   new handle each time, and the offer already on its way is from one that
///   is gone.
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
  bool _rejoining = false;
  bool _rejoinAsked = false;

  /// The attempt work started now belongs to.
  int get attempt => _attempt;

  /// Whether [attempt] is still the one in progress.
  bool isCurrent(int attempt) => attempt == _attempt;

  /// Whether the session that is up now was asked for a rejoin whose offer
  /// is still awaited.
  bool get rejoinAsked => _rejoinAsked;

  /// A merge starts: whatever was in flight for the way in before is void,
  /// and so is its deadline; work for this one takes [attempt] from here on.
  void begin() {
    _deadline?.cancel();
    _attempt++;
    _rejoining = false;
    _rejoinAsked = false;
  }

  /// The host starts on his way back into a room he was in - when its
  /// connection failed, and again each time a new session is asked. Unlike a
  /// merge, this way in belongs to the signaling session it is asked of; see
  /// [sessionLost].
  void beginRejoin() {
    _deadline?.cancel();
    _attempt++;
    _rejoining = true;
  }

  /// The session that is up now has been handed a rejoin.
  void markRejoinAsked() => _rejoinAsked = true;

  /// The rejoin was refused: it brings no offer, so there is nothing for its
  /// deadline to wait for.
  void rejoinRefused() {
    _rejoinAsked = false;
    _deadline?.cancel();
  }

  /// Starts the deadline for the offer; [onOverdue] is called if it passes.
  void arm(void Function() onOverdue) {
    _deadline?.cancel();
    _deadline = _createTimer(timeout, onOverdue);
  }

  /// The signaling session is gone.
  ///
  /// A rejoin goes with the session it was asked of: the request, the offer
  /// that was to follow and an answer still in flight were all that
  /// session's, so the attempt is void from here - whatever comes back from
  /// it later, an acknowledgement as much as a failure, is nobody's - and its
  /// deadline stops, since nothing can deliver the offer. The next session's
  /// handshake starts the way back anew.
  ///
  /// A merge does not: its legs are silent until the offer comes, and the
  /// server's own word that the room failed is an event a dropped socket
  /// takes with it, so its attempt and its deadline run on.
  void sessionLost() {
    _rejoinAsked = false;
    if (!_rejoining) return;
    _deadline?.cancel();
    _attempt++;
  }

  /// The offer was answered: the host is in the room.
  void offerAnswered() {
    _deadline?.cancel();
    _rejoining = false;
    _rejoinAsked = false;
  }

  /// The room is left: nothing is awaited, and anything still in flight for
  /// it is void.
  void end() {
    _deadline?.cancel();
    _attempt++;
    _rejoining = false;
    _rejoinAsked = false;
  }

  /// Stops the deadline for good; for the owner's own disposal.
  void dispose() => _deadline?.cancel();
}
