import '../abstract_events.dart';
import 'conference_video_room.dart';

/// Who is in the conference's video room, sent to every subscribed participant
/// after `conference_video_subscribe` and on every change of streams,
/// publishers, participants, speaker or presenter.
///
/// [self] is this client's own feed. Feeds: the host is 1, the far end of the
/// host's line N is N + 2, guests 100 and up. [streams] is what this client
/// receives - never its own feed. [speaker] is whoever started talking last and
/// does not clear on silence; [presenter] whoever shares a screen. Both are
/// `null` when there is none.
class ConferenceVideoUpdatedEvent extends SessionEvent {
  const ConferenceVideoUpdatedEvent({
    super.transaction,
    required this.room,
    required this.self,
    this.streams = const [],
    this.publishers = const [],
    this.participants = const [],
    this.speaker,
    this.presenter,
  });

  final int room;
  final int self;
  final List<ConferenceVideoStream> streams;
  final List<ConferenceVideoPublisher> publishers;
  final List<ConferenceVideoParticipant> participants;
  final int? speaker;
  final int? presenter;

  @override
  List<Object?> get props => [...super.props, room, self, streams, publishers, participants, speaker, presenter];

  static const typeValue = 'conference_video_updated';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    'room': room,
    'self': self,
    'streams': streams.map((stream) => stream.toJson()).toList(growable: false),
    'publishers': publishers.map((publisher) => publisher.toJson()).toList(growable: false),
    'participants': participants.map((participant) => participant.toJson()).toList(growable: false),
    if (speaker != null) 'speaker': speaker,
    if (presenter != null) 'presenter': presenter,
  };

  factory ConferenceVideoUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoUpdatedEvent(
      transaction: json['transaction'],
      room: json['room'] as int,
      self: json['self'] as int,
      streams: conferenceVideoStreamsFromJson(json['streams']),
      publishers: conferenceVideoPublishersFromJson(json['publishers']),
      participants: conferenceVideoParticipantsFromJson(json['participants']),
      speaker: json['speaker'] as int?,
      presenter: json['presenter'] as int?,
    );
  }
}
