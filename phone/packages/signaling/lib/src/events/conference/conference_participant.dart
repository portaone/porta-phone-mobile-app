import 'package:equatable/equatable.dart';

/// One leg of a conference as the server reports it.
///
/// [line] addresses the participant in `conference_mute` / `conference_remove`,
/// [callId] is how the client matches the participant to a call it already
/// knows, [muted] is the room-wide mute the host set. The host is never in the
/// list; a UI that shows them adds that row itself.
class ConferenceParticipant extends Equatable {
  const ConferenceParticipant({required this.line, required this.callId, this.muted = false});

  final int line;
  final String callId;
  final bool muted;

  @override
  List<Object?> get props => [line, callId, muted];

  factory ConferenceParticipant.fromJson(Map<String, dynamic> json) {
    return ConferenceParticipant(
      line: json['line'] as int,
      callId: json['call_id'] as String,
      // Lenient bool read, as in signaling_ts conference_participant.ts:
      // anything but an explicit true is not muted.
      muted: json['muted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'line': line, 'call_id': callId, 'muted': muted};

  static List<ConferenceParticipant> listFromJson(List<dynamic>? json) {
    if (json == null) return const [];
    return json.map((e) => ConferenceParticipant.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(List<ConferenceParticipant> participants) =>
      participants.map((p) => p.toJson()).toList(growable: false);

  @override
  String toString() => 'ConferenceParticipant{line: $line, callId: $callId, muted: $muted}';
}
