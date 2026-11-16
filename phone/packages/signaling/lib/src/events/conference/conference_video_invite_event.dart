import '../abstract_events.dart';

/// This client is the far end of a conference host's call and is invited to
/// the conference's video room.
///
/// [line] is this client's own line, the call through which it takes part: its
/// audio keeps travelling on that call, which now carries the mix, and it has no
/// mixer PeerConnection. Its video goes through the `conference_video_*`
/// requests. [host] is the host's display name, `null` when the PBX gave none.
/// The invitation is not repeated and not in the handshake; it ends with
/// `conference_video_terminated`.
class ConferenceVideoInviteEvent extends SessionEvent {
  const ConferenceVideoInviteEvent({super.transaction, required this.room, required this.line, this.host});

  final int room;
  final int line;
  final String? host;

  @override
  List<Object?> get props => [...super.props, room, line, host];

  static const typeValue = 'conference_video_invite';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    'room': room,
    'line': line,
    if (host != null) 'host': host,
  };

  factory ConferenceVideoInviteEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoInviteEvent(
      transaction: json['transaction'],
      room: json['room'] as int,
      line: json['line'] as int,
      host: json['host'] as String?,
    );
  }
}
