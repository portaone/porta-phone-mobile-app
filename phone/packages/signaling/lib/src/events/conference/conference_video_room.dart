import 'package:equatable/equatable.dart';

import '../../conference_video_types.dart';

/// One stream this client receives on its subscriber PeerConnection: [mid] is
/// the m-line there, [feed] whose stream it is. Remote tracks are matched to
/// participants by [mid].
class ConferenceVideoStream extends Equatable {
  const ConferenceVideoStream({required this.mid, required this.feed, required this.kind});

  final String mid;
  final int feed;
  final ConferenceVideoKind kind;

  @override
  List<Object?> get props => [mid, feed, kind];

  factory ConferenceVideoStream.fromJson(Map<String, dynamic> json) => ConferenceVideoStream(
    mid: json['mid'] as String,
    feed: json['feed'] as int,
    kind: ConferenceVideoKind.fromValue(json['kind']),
  );

  Map<String, dynamic> toJson() => {'mid': mid, 'feed': feed, 'kind': kind.value};
}

/// A participant that currently publishes video, with what it publishes.
/// [line] is the host's line of that participant, meaningful to the host only;
/// `null` for the host itself and for guests. [display] is `null` when Core
/// has no name for it.
class ConferenceVideoPublisher extends Equatable {
  const ConferenceVideoPublisher({required this.feed, this.display, this.line, this.kinds = const []});

  final int feed;
  final String? display;
  final int? line;
  final List<ConferenceVideoKind> kinds;

  @override
  List<Object?> get props => [feed, display, line, kinds];

  factory ConferenceVideoPublisher.fromJson(Map<String, dynamic> json) => ConferenceVideoPublisher(
    feed: json['feed'] as int,
    display: json['display'] as String?,
    line: json['line'] as int?,
    kinds: (json['kinds'] as List<dynamic>? ?? const []).map(ConferenceVideoKind.fromValue).toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'feed': feed,
    'display': display,
    'line': line,
    'kinds': kinds.map((kind) => kind.value).toList(growable: false),
  };
}

/// Someone in the conference, with or without video, as every participant is
/// told: the host first, then the far ends by line, then admitted guests.
/// [muted] is the host's mute for the room.
class ConferenceVideoParticipant extends Equatable {
  const ConferenceVideoParticipant({
    required this.feed,
    this.display,
    this.host = false,
    this.muted = false,
    this.guest = false,
  });

  final int feed;
  final String? display;
  final bool host;
  final bool muted;
  final bool guest;

  @override
  List<Object?> get props => [feed, display, host, muted, guest];

  factory ConferenceVideoParticipant.fromJson(Map<String, dynamic> json) => ConferenceVideoParticipant(
    feed: json['feed'] as int,
    display: json['display'] as String?,
    host: json['host'] == true,
    muted: json['muted'] == true,
    guest: json['guest'] == true,
  );

  Map<String, dynamic> toJson() => {
    'feed': feed,
    'display': display,
    'host': host,
    'muted': muted,
    if (guest) 'guest': true,
  };
}

/// Reads one list of `conference_video_updated`; a missing list is empty, and an
/// entry [read] cannot take (no `feed` number, no `mid` string) is left out:
/// the event goes to every participant on every change, and one that fails to
/// parse would fail the connection.
List<T> _listFromJson<T>(Object? json, T? Function(Map<String, dynamic>) read) => [
  if (json is List)
    for (final entry in json)
      if (entry is Map<String, dynamic>)
        if (read(entry) case final T value) value,
];

ConferenceVideoStream? _streamOf(Map<String, dynamic> json) {
  if (json case {'mid': String _, 'feed': int _}) return ConferenceVideoStream.fromJson(json);
  return null;
}

ConferenceVideoPublisher? _publisherOf(Map<String, dynamic> json) {
  if (json case {'feed': int feed}) {
    return ConferenceVideoPublisher(
      feed: feed,
      display: json['display'] is String ? json['display'] as String : null,
      line: json['line'] is int ? json['line'] as int : null,
      kinds: [if (json['kinds'] case final List<dynamic> kinds) ...kinds.map(ConferenceVideoKind.fromValue)],
    );
  }
  return null;
}

ConferenceVideoParticipant? _participantOf(Map<String, dynamic> json) {
  if (json case {'feed': int feed}) {
    return ConferenceVideoParticipant(
      feed: feed,
      display: json['display'] is String ? json['display'] as String : null,
      host: json['host'] == true,
      muted: json['muted'] == true,
      guest: json['guest'] == true,
    );
  }
  return null;
}

/// Reads the lists of `conference_video_updated`.
List<ConferenceVideoStream> conferenceVideoStreamsFromJson(Object? json) => _listFromJson(json, _streamOf);

List<ConferenceVideoPublisher> conferenceVideoPublishersFromJson(Object? json) => _listFromJson(json, _publisherOf);

List<ConferenceVideoParticipant> conferenceVideoParticipantsFromJson(Object? json) =>
    _listFromJson(json, _participantOf);
