import 'package:equatable/equatable.dart';

/// Which of a participant's two conference video PeerConnections a message is
/// about: the one that sends its camera and screen, or the one that receives
/// everyone else's.
enum ConferenceVideoPc {
  /// Offered by the client; carries its camera and/or screen.
  publisher('publisher'),

  /// Offered by the room through Core; carries every other participant's video.
  subscriber('subscriber');

  const ConferenceVideoPc(this.value);

  /// The `pc` string as it travels on the wire.
  final String value;

  /// The value for [value], or `null` for anything else.
  static ConferenceVideoPc? tryFromValue(Object? value) {
    for (final pc in values) {
      if (pc.value == value) return pc;
    }
    return null;
  }

  /// The value for [value]; throws [ArgumentError] for anything else.
  static ConferenceVideoPc fromValue(Object? value) =>
      tryFromValue(value) ?? (throw ArgumentError.value(value, 'pc', 'Not a conference video PeerConnection'));
}

/// What a conference video stream shows.
enum ConferenceVideoKind {
  camera('camera'),
  screen('screen'),

  /// A kind this client does not know, from a newer Core. Never sent.
  unknown('');

  const ConferenceVideoKind(this.value);

  /// The `kind` string as it travels on the wire.
  final String value;

  /// The value for [value], or [unknown].
  static ConferenceVideoKind fromValue(Object? value) =>
      values.firstWhere((kind) => kind != unknown && kind.value == value, orElse: () => unknown);
}

/// What one video m-line of a `conference_video_publish` offer carries, named
/// by its `mid`. Core accepts `camera` and `screen` only.
class ConferenceVideoDescription extends Equatable {
  const ConferenceVideoDescription({required this.mid, required this.kind});

  final String mid;
  final ConferenceVideoKind kind;

  @override
  List<Object?> get props => [mid, kind];

  factory ConferenceVideoDescription.fromJson(Map<String, dynamic> json) {
    final kind = ConferenceVideoKind.fromValue(json['kind']);
    if (kind == ConferenceVideoKind.unknown) {
      throw ArgumentError.value(json['kind'], 'kind', 'Not camera or screen');
    }
    return ConferenceVideoDescription(mid: json['mid'] as String, kind: kind);
  }

  /// The description as it is sent. [ConferenceVideoKind.unknown] has no wire
  /// value and Core would refuse the whole publication for it, so it throws
  /// [ArgumentError] here, before anything is sent, in every build.
  Map<String, dynamic> toJson() {
    if (kind == ConferenceVideoKind.unknown) {
      throw ArgumentError.value(kind, 'kind', 'Only camera or screen can be published');
    }
    return {'mid': mid, 'kind': kind.value};
  }
}
