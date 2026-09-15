import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:signaling/signaling.dart';

part 'conference_state.freezed.dart';

/// Where the conference room stands, from this client's side.
enum ConferencePhase {
  /// No room: calls are held and resumed one at a time.
  none,

  /// The merge was acknowledged; the legs are quiet and the room's offer is
  /// awaited.
  assembling,

  /// The room's offer was answered: the legs are mixed on the server.
  active,
}

/// The conference room this client hosts, as the app knows it.
///
/// Membership of a call is a derived fact - [isLeg] over [legs] - rather than
/// a flag on the call itself: [ActiveCall] is copied in dozens of places, and
/// a second source of truth would drift. The server's participant list is
/// kept as sent ([participants], the host is never in it); [legs] is the
/// client's own record of which calls it merged, known from the merge's
/// acknowledgement, before the room's offer arrives.
@freezed
class ConferenceState with _$ConferenceState {
  const ConferenceState({
    this.room,
    this.phase = ConferencePhase.none,
    this.legs = const {},
    this.participants = const [],
    this.selfMuted = false,
  });

  /// The room the server assigned, from the conference offer; `null` before it.
  @override
  final int? room;

  @override
  final ConferencePhase phase;

  /// The calls merged into the room, by call id, with the line each is on.
  @override
  final Map<String, int> legs;

  /// The server's participant list as last sent. The host is not in it.
  @override
  final List<ConferenceParticipant> participants;

  /// Whether the host's own microphone is muted towards the room.
  @override
  final bool selfMuted;

  /// A room exists, whether still assembling or already active.
  bool get isPresent => phase != ConferencePhase.none;

  /// Whether an event naming [room] is about the room this client holds.
  ///
  /// Before the offer this room has no id of its own, and the server's
  /// terminal events for a room it never named carry none either, so
  /// anything unnamed is taken as this one. A named one that differs
  /// describes a room this client is not in.
  bool concerns(int? room) => room == null || this.room == null || room == this.room;

  /// Whether [callId] is one of the room's legs.
  bool isLeg(String callId) => legs.containsKey(callId);

  /// The room's legs, by call id.
  Set<String> get legIds => legs.keys.toSet();

  /// Whether the server has announced [callId] as a participant - the point
  /// from which a mute for it is accepted rather than refused as not ready.
  bool isReady(String callId) => participants.any((participant) => participant.callId == callId);

  /// Whether the server reports [callId] muted in the room.
  bool participantMuted(String callId) =>
      participants.firstWhereOrNull((participant) => participant.callId == callId)?.muted ?? false;
}
