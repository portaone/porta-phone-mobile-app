import 'package:equatable/equatable.dart';

import '../events/conference/conference_participant.dart';

/// The conference running on this signalling session, as the `state` handshake
/// reports it. A conference outlives a signalling drop while the media
/// server stays up, so a reconnecting client reconciles against this: it ends a
/// room it cannot rejoin, forgets one the server no longer has, and adopts the
/// server's participants when both sides have one.
class ConferenceInfo extends Equatable {
  const ConferenceInfo({required this.room, this.participants = const []});

  final int room;
  final List<ConferenceParticipant> participants;

  @override
  List<Object?> get props => [room, participants];

  factory ConferenceInfo.fromJson(Map<String, dynamic> json) {
    return ConferenceInfo(
      room: json['room'] as int,
      participants: ConferenceParticipant.listFromJson(json['participants'] as List<dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {'room': room, 'participants': ConferenceParticipant.listToJson(participants)};
}
