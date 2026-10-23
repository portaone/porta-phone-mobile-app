import 'dart:async';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/features/call/utils/sdp_mod_builder.dart';
import 'package:webtrit_phone/models/enableble.dart';
import 'package:webtrit_phone/models/feature_access/encoding_config.dart';
import 'package:webtrit_phone/models/rtp_codec_profile.dart';

/// What [RoomCodecs] asks of whoever drives the calls.
sealed class RoomCodecsCommand {
  const RoomCodecsCommand();
}

/// Renegotiate [callId]: its offer is to carry the conference codecs alone.
final class RenegotiateForRoom extends RoomCodecsCommand {
  const RenegotiateForRoom(this.callId);
  final String callId;
}

/// Ask for the hold of [callId] again, if it is still held: the move took it
/// off hold on the far end, and no room took it.
final class HoldAgain extends RoomCodecsCommand {
  const HoldAgain(this.callId);
  final String callId;
}

/// Take the move's offer of [callId] back: the server acknowledged it, and
/// its answer did not come in time. See [RoomCodecs.takesBack].
final class TakeBackForRoom extends RoomCodecsCommand {
  const TakeBackForRoom(this.callId);
  final String callId;
}

/// Ask [request] again: the move it waited for is over.
final class AskAgain extends RoomCodecsCommand {
  const AskAgain(this.request);
  final void Function() request;
}

/// Whether calls can be put in a room as they are (see [RoomCodecs.check]).
enum RoomCodecsCheck {
  /// On the conference codecs: the request goes ahead.
  ready,

  /// Being moved onto them: the request is asked again once they are.
  moving,

  /// Still off them after a move: the request fails.
  off,
}

/// What to do with an offer the server answered with an error.
enum RoomOfferError {
  /// The move's offer is refused, or its move is over: roll it back, do not
  /// send it again.
  rollBack,

  /// Not about a move, or an error worth a retry: as for any renegotiation.
  asUsual,
}

/// The conference codecs: which calls may go into the room, the offers and
/// answers of those that do, and the move of a call on another codec onto
/// them before it is merged or added.
///
/// The codecs are the mixer's ([codecs], see
/// [EncodingConfig.conferenceAudioCodecs]); the person's media settings may
/// order them and leave some out ([preferred]), never add one.
///
/// A call placed as an ordinary call settled on whatever codec its two ends
/// liked best, often G.722, before anybody thought of a room, and the room's
/// mixer leaves such a call out. Before a merge or an add takes it, the call
/// is renegotiated with the conference codecs alone, and the request is asked
/// again once its answer is applied - checking the codecs again, since a far
/// end may answer on another codec all the same. A request asked while a move
/// is on waits for it.
///
/// A far end that answers [refusals] keeps its call as it was: the offer is
/// rolled back, not sent again as other refused offers are, and the request
/// asked again finds the call still off the codecs. So it goes when the
/// answers do not come within [timeout], and an error that arrives after that
/// rolls its offer back too.
///
/// An offer the server acknowledged with `updating` gets no error after that:
/// its answer is the only thing left to come, and a call left waiting for it
/// stays updating - hold and the keypad locked - with nothing that would end
/// the wait. Such an offer is taken back when [timeout] runs out, even when a
/// refusal of another call gave the move up first, or at once when its
/// acknowledgement arrives after the move was given up ([TakeBackForRoom]).
/// The owner then brings both ends back to one description with a fresh
/// offer, since the server may have applied the answer that was lost; a held
/// call is held again once that offer is answered ([holdAfterResync]).
///
/// A held call is moved as it is. The connection offers sendrecv - the hold
/// is the server's, asked for apart from it - so the move takes the call off
/// hold on the far end, as the merge would a moment later; when no room takes
/// it, its hold is asked for again. The direction cannot be written into the
/// offer instead: the connection would see its transceiver differ from what
/// was agreed and renegotiate again, sendrecv, on what is by then a leg of the
/// room.
///
/// It knows nothing of signaling or of connections: the owner tells it what
/// happened and carries out the [RoomCodecsCommand]s it is handed.
class RoomCodecs {
  RoomCodecs({
    required void Function(RoomCodecsCommand command) onCommand,
    this.codecs = EncodingConfig.defaultConferenceAudioCodecs,
    List<Enableble<RTPCodecProfile>>? Function()? preferred,
    this.timeout = const Duration(seconds: 20),
    Timer Function(Duration, void Function())? createTimer,
  }) : _onCommand = onCommand,
       _preferred = preferred ?? (() => null),
       _mixable = codecs.map((c) => c.sdpKey.toLowerCase()).toSet(),
       _createTimer = createTimer ?? Timer.new;

  static final _logger = Logger('RoomCodecs');

  /// How long the calls being moved get to be answered.
  final Duration timeout;

  /// What a far end answers when it will not speak the codecs offered.
  static const refusals = {415, 488, 606};

  /// The reason a request fails with when a call stays off the codecs.
  static const notMixable = 'codec_not_mixable';

  /// The reason a request fails with when the answer to a call's move did not
  /// come and its offer was taken back.
  static const notAnswered = 'codec_move_not_answered';

  /// The codecs the mixer speaks: a call on any of them can be put in a room
  /// as it is.
  final Set<RTPCodec> codecs;

  /// The person's order of the conference codecs, read for each offer since
  /// the settings may change between calls; null or empty for none.
  final List<Enableble<RTPCodecProfile>>? Function() _preferred;

  /// [codecs] by encoding name in lower case, as [codecOf] reads them.
  final Set<String> _mixable;

  final void Function(RoomCodecsCommand command) _onCommand;
  final Timer Function(Duration, void Function()) _createTimer;

  Timer? _deadline;

  /// The calls whose answer is awaited, and whether each was held.
  final Map<String, bool> _awaited = {};

  /// The calls whose outstanding offer is a move's.
  final Set<String> _offered = {};

  /// The calls whose move's offer the server acknowledged and that wait for
  /// its answer.
  final Set<String> _acknowledged = {};

  /// The calls whose move's offer is to be taken back.
  final Set<String> _takenBack = {};

  /// The calls whose take-back an answer made needless before it ran.
  final Set<String> _takeBackSkipped = {};

  /// Taken-back calls among those tried: a request failing for them failed
  /// for a lost answer, not for a codec.
  final Set<String> _unanswered = {};

  /// Held calls to be held again once the offer that resyncs them is
  /// answered.
  final Set<String> _holdAfterResync = {};

  /// The calls tried for the requests being asked again.
  final Set<String> _tried = {};

  /// Held calls whose offer was answered: off hold on the far end.
  final Set<String> _offHoldOnFarEnd = {};

  /// The requests to ask again once the move is over.
  final List<void Function()> _waiting = [];

  /// [sdp] with the conference codecs alone, in the person's order when they
  /// set one, or null when that changes nothing - it has no other codec, or
  /// none of them, since an audio section left with no voice codec carries no
  /// call at all.
  ///
  /// For a call [inRoom] - a leg, or placed to join - and for one being
  /// moved: its own offers, and its answers to an offer from the far end,
  /// which could otherwise move it off them. Applied after the encoding
  /// settings, which a deployment may switch off as a whole: what the room
  /// needs is kept even then, and only the person's order goes with them.
  ///
  /// The codecs the person left are kept when the description has any of
  /// them, and every codec the mixer speaks otherwise: a call the encoding
  /// settings already narrowed to another of them still joins.
  String? restrict(String callId, String sdp, {required bool inRoom}) {
    if (!inRoom && !moves(callId)) return null;
    final order = [
      for (final p in _preferred() ?? const <Enableble<RTPCodecProfile>>[])
        if (p.enabled && p.option.kind == RTPCodecKind.audio && codecs.contains(p.option.codec)) p.option,
    ];
    final builder = SDPModBuilder(sdp: sdp);
    var changed = order.isNotEmpty && builder.keepAudioCodecs({for (final p in order) p.codec});
    if (!changed) changed = builder.keepAudioCodecs(codecs);
    if (order.isNotEmpty) {
      builder.reorderProfiles(order, RTPCodecKind.audio);
      changed = true;
    }
    return changed ? builder.sdp : null;
  }

  /// The voice codec an answer settled on, as its encoding name in lower
  /// case; null when it cannot be read.
  static String? codecOf(String answer) => SDPModBuilder(sdp: answer).audioCodecInUse();

  /// Whether a move is on.
  bool get isMoving => _awaited.isNotEmpty;

  /// Whether [callId] is being moved.
  bool moves(String callId) => _awaited.containsKey(callId);

  /// Whether calls with these codecs can go into a room now, each with the
  /// codec its last answer settled on (null when unknown) and whether it is
  /// held. When one is on a codec the room does not mix, it is moved first and
  /// [request] asked again once it is; so it is when a move is already on.
  RoomCodecsCheck check(Map<String, ({String? codec, bool held})> calls, {required void Function() request}) {
    if (isMoving) {
      _waiting.add(request);
      return RoomCodecsCheck.moving;
    }
    final off = {
      for (final MapEntry(key: callId, value: call) in calls.entries)
        if (call.codec != null && !_mixable.contains(call.codec)) callId: call,
    };
    if (off.isEmpty) return RoomCodecsCheck.ready;
    if (off.keys.any(_tried.contains)) {
      _logger.warning('still off the conference codecs after a move: ${off.map((k, v) => MapEntry(k, v.codec))}');
      return RoomCodecsCheck.off;
    }

    _logger.info('moving ${off.map((k, v) => MapEntry(k, v.codec))} onto the conference codecs');
    for (final MapEntry(key: callId, value: call) in off.entries) {
      _awaited[callId] = call.held;
    }
    _tried.addAll(off.keys);
    _waiting.add(request);
    _deadline?.cancel();
    _deadline = _createTimer(timeout, () {
      _logger.warning('${_awaited.keys} not answered in time, giving the move up');
      _deadline = null;
      // Every acknowledged offer still here is unanswered, this move's or one
      // a refusal gave up before: an answer takes its call out.
      final unanswered = List.of(_acknowledged);
      _giveUp();
      unanswered.forEach(_takeBack);
    });
    for (final callId in off.keys) {
      _onCommand(RenegotiateForRoom(callId));
    }
    return RoomCodecsCheck.moving;
  }

  /// Whether a kept offer of [callId] is to be withdrawn rather than sent
  /// again: the move needs one of the conference codecs alone, and one kept
  /// from before carries every codec - its answer would be taken for the
  /// move's.
  bool withdrawsKeptOffer(String callId) => moves(callId) && !_offered.contains(callId);

  /// An offer of [callId] is out.
  void offerSent(String callId) {
    if (moves(callId)) _offered.add(callId);
  }

  /// The server acknowledged an offer of [callId] with `updating`: its answer
  /// comes later. One of a move already given up is taken back at once.
  void acknowledged(String callId) {
    if (!_offered.contains(callId)) return;
    if (moves(callId)) {
      _acknowledged.add(callId);
    } else {
      _takeBack(callId);
    }
  }

  /// Whether the offer of [callId] is to be taken back now - once: rolled
  /// back, the call no longer updating, and both ends brought back to one
  /// description, since the server may have applied the answer that was lost.
  bool takesBack(String callId) => _takenBack.remove(callId);

  /// Whether a take-back of [callId] asked for was made needless by an answer
  /// applied before it ran - once.
  bool takeBackSkipped(String callId) => _takeBackSkipped.remove(callId);

  /// [callId], taken back while held, is to be held again once the offer that
  /// resyncs it is answered: that offer is sendrecv and lifts the hold on the
  /// far end, as the move did.
  void holdAfterResync(String callId) => _holdAfterResync.add(callId);

  /// The reason a request fails with for [callIds] still off the codecs.
  String offReason(Iterable<String> callIds) => callIds.any(_unanswered.contains) ? notAnswered : notMixable;

  /// An answer to an offer of [callId] is applied.
  void answerApplied(String callId) {
    _acknowledged.remove(callId);
    if (_takenBack.remove(callId)) _takeBackSkipped.add(callId);
    if (_holdAfterResync.remove(callId)) _onCommand(HoldAgain(callId));
    if (!_offered.remove(callId)) return;
    final held = _awaited.remove(callId);
    if (held == null) return;
    if (held) _offHoldOnFarEnd.add(callId);
    if (_awaited.isEmpty) _over();
  }

  /// The server answered an offer of [callId] with `updated`, which carries
  /// no answer: one is in only when the connection is [stable] again.
  void updated(String callId, {required bool stable}) {
    if (stable) answerApplied(callId);
  }

  /// The server answered an offer of [callId] with an error [code].
  RoomOfferError offerFailed(String callId, int code) {
    if (!_offered.contains(callId)) return RoomOfferError.asUsual;
    if (!refusals.contains(code) && moves(callId)) return RoomOfferError.asUsual;
    _logger.warning('the move of $callId failed with $code');
    _offered.remove(callId);
    _acknowledged.remove(callId);
    _giveUp();
    return RoomOfferError.rollBack;
  }

  /// [callId] is gone. When it was the last call awaited, the requests are
  /// asked again without it.
  void callRemoved(String callId) {
    _offered.remove(callId);
    _acknowledged.remove(callId);
    _takenBack.remove(callId);
    _takeBackSkipped.remove(callId);
    _unanswered.remove(callId);
    _holdAfterResync.remove(callId);
    _tried.remove(callId);
    _offHoldOnFarEnd.remove(callId);
    final awaited = _awaited.remove(callId) != null;
    if (awaited && _awaited.isEmpty) _over();
  }

  /// A request asked for [callIds] is done, the room taking them or not; the
  /// held calls the move took off hold on the far end that no room took are
  /// to be held again.
  void settled(Iterable<String> callIds, {required bool roomTook}) {
    if (!roomTook) {
      for (final callId in callIds.where(_offHoldOnFarEnd.contains)) {
        _onCommand(HoldAgain(callId));
      }
    }
    _tried.removeAll(callIds);
    _unanswered.removeAll(callIds);
    _offHoldOnFarEnd.removeAll(callIds);
  }

  /// Stops the deadline for good; for the owner's own disposal.
  void dispose() => _deadline?.cancel();

  void _takeBack(String callId) {
    _logger.warning('the answer to the move of $callId did not come, taking its offer back');
    _offered.remove(callId);
    _acknowledged.remove(callId);
    _takenBack.add(callId);
    _unanswered.add(callId);
    _onCommand(TakeBackForRoom(callId));
  }

  void _giveUp() {
    if (!isMoving) return;
    _awaited.clear();
    _over();
  }

  void _over() {
    // The deadline stays while an acknowledged offer waits for its answer:
    // a move a refusal gave up has no other way to take it back.
    if (_acknowledged.isEmpty) {
      _deadline?.cancel();
      _deadline = null;
    }
    final waiting = List.of(_waiting);
    _waiting.clear();
    for (final request in waiting) {
      _onCommand(AskAgain(request));
    }
  }
}
