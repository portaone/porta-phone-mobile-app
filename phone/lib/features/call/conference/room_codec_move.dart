import 'dart:async';

/// The move of calls onto the conference codecs before they are put in a room.
///
/// A call placed as an ordinary call settled on whatever codec its two ends
/// liked best, often G.722, before anybody thought of a room, and the room's
/// mixer leaves such a call out. Before a merge or an add takes it, the call
/// is renegotiated with the conference codecs alone, and the request is asked
/// again once the answer is in - checking the codecs again, since a far end
/// may answer on another codec all the same.
///
/// What has to be kept about that, and changes together, is kept here rather
/// than as loose fields of whoever drives the calls:
///
/// - **which calls are awaited**, and whether each was held: the offer is
///   sendrecv, as the connection makes it - the hold is the server's - so a
///   held call whose offer was answered is off hold on the far end until a
///   room takes it.
/// - **which calls have the move's offer out**, so that an answer or an error
///   is known to be about it - also after the move has been given up, when a
///   late refusal must not be sent again as other refused offers are.
/// - **which calls were tried** for the requests being asked again: one still
///   off the codecs then is not tried a second time.
/// - **the requests waiting**: the one that started the move, and any asked
///   while it was on, each asked again once it is over.
/// - **when it is overdue**: an answer may never come.
///
/// It knows nothing of signaling or of connections; the owner tells it what
/// happened and asks again the requests it hands back.
class RoomCodecMove {
  RoomCodecMove({required this.timeout, Timer Function(Duration, void Function())? createTimer})
    : _createTimer = createTimer ?? Timer.new;

  /// How long the calls get to be answered before the move is given up.
  final Duration timeout;

  final Timer Function(Duration, void Function()) _createTimer;

  Timer? _deadline;

  /// The calls whose answer is awaited, and whether each was held.
  final Map<String, bool> _awaited = {};

  /// The calls whose outstanding offer is the move's.
  final Set<String> _offered = {};

  /// The calls tried for the requests being asked again.
  final Set<String> _tried = {};

  /// Held calls whose offer was answered: off hold on the far end.
  final Set<String> _offHoldOnFarEnd = {};

  /// The requests to ask again once the move is over.
  final List<void Function()> _waiting = [];

  /// Whether a move is on.
  bool get isOn => _awaited.isNotEmpty;

  /// Whether [callId] is being moved.
  bool moves(String callId) => _awaited.containsKey(callId);

  /// Whether the outstanding offer of [callId] is a move's - of the move on,
  /// or of one given up while the offer was out.
  bool hasOfferOut(String callId) => _offered.contains(callId);

  /// Whether [callId] was moved, or tried, for the requests being asked again.
  bool wasTried(String callId) => _tried.contains(callId);

  /// Starts moving [calls] (each with whether it is held) for [request];
  /// [onOverdue] is called when the answers do not come in time.
  void start(Map<String, bool> calls, {required void Function() request, required void Function() onOverdue}) {
    assert(!isOn, 'one move at a time; wait() for the one on');
    _awaited.addAll(calls);
    _tried.addAll(calls.keys);
    _waiting.add(request);
    _deadline?.cancel();
    _deadline = _createTimer(timeout, onOverdue);
  }

  /// Keeps [request] until the move on is over.
  void wait(void Function() request) => _waiting.add(request);

  /// The move's offer of [callId] is out.
  void offerSent(String callId) {
    if (moves(callId)) _offered.add(callId);
  }

  /// The answer to the move's offer of [callId] is applied. Returns the
  /// requests to ask again - none until every call has its answer.
  List<void Function()> answered(String callId) {
    _offered.remove(callId);
    final held = _awaited.remove(callId);
    if (held == null) return const [];
    if (held) _offHoldOnFarEnd.add(callId);
    return _awaited.isEmpty ? _over() : const [];
  }

  /// The move's offer of [callId] is withdrawn: refused and rolled back.
  void offerWithdrawn(String callId) => _offered.remove(callId);

  /// Gives the move up: a call turned the offer down, or the answers are
  /// overdue. Returns the requests to ask again; the calls left off the
  /// codecs make them fail.
  List<void Function()> giveUp() {
    if (!isOn) return const [];
    _awaited.clear();
    return _over();
  }

  /// [callId] is gone. Returns the requests to ask again when it was the
  /// last call awaited.
  List<void Function()> callRemoved(String callId) {
    _offered.remove(callId);
    _tried.remove(callId);
    _offHoldOnFarEnd.remove(callId);
    final awaited = _awaited.remove(callId) != null;
    return awaited && _awaited.isEmpty ? _over() : const [];
  }

  /// A request asked again for [callIds] is done, the room taking them or
  /// not. Returns the calls to hold again: held, off hold on the far end
  /// since their offer was answered, and in no room.
  List<String> settled(Iterable<String> callIds, {required bool roomTook}) {
    final holdAgain = roomTook ? const <String>[] : callIds.where(_offHoldOnFarEnd.contains).toList();
    _tried.removeAll(callIds);
    _offHoldOnFarEnd.removeAll(callIds);
    return holdAgain;
  }

  /// Stops the deadline for good; for the owner's own disposal.
  void dispose() => _deadline?.cancel();

  List<void Function()> _over() {
    _deadline?.cancel();
    _deadline = null;
    final waiting = List.of(_waiting);
    _waiting.clear();
    return waiting;
  }
}
