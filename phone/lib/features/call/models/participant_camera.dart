import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// One participant's camera as the room's video sends it: the stream that
/// carries it and the track of that stream that is the camera.
///
/// The track is named, not the stream alone: the room may give every track of
/// its subscription the same stream id (Janus sends `a=msid:janus janus<N>`),
/// and a renderer handed a stream id alone shows the first track of the first
/// stream of that id - another participant's camera.
///
/// A renegotiation of the subscription hands the same track over in a new
/// stream object: [isSameTrackAs] tells it from a subscription made again,
/// which is a new connection ([MediaStream.ownerTag]).
@immutable
class ParticipantCamera {
  const ParticipantCamera({required this.stream, required this.trackId});

  /// The stream the camera arrived in.
  final MediaStream stream;

  /// The camera's track in [stream].
  final String trackId;

  /// Whether [other] is this camera's track on the same connection, perhaps
  /// handed over in another stream object.
  bool isSameTrackAs(ParticipantCamera other) =>
      other.stream.ownerTag == stream.ownerTag && other.stream.id == stream.id && other.trackId == trackId;

  @override
  bool operator ==(Object other) =>
      other is ParticipantCamera && identical(other.stream, stream) && other.trackId == trackId;

  @override
  int get hashCode => Object.hash(identityHashCode(stream), trackId);

  @override
  String toString() => 'ParticipantCamera(${stream.id}, $trackId)';
}
