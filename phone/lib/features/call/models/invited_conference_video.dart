import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'participant_camera.dart';

/// The video of a room this client was invited to as the far end of the
/// host's call (protocol section 19): the cameras it receives, by feed, and
/// its own camera as it is published there.
///
/// Kept apart from `ConferenceState`, which is the room this client hosts: an
/// invited client has no room of its own, no legs and no mixer.
@immutable
class InvitedConferenceVideo {
  const InvitedConferenceVideo({required this.line, this.feeds = const {}, this.selfVideo});

  /// The line of the call through which this client takes part.
  final int line;

  /// The cameras this client receives, by feed: the host is 1, the far end
  /// of the host's line N is N + 2.
  final Map<int, ParticipantCamera> feeds;

  /// This client's camera in the room; `null` while it is not published.
  final MediaStream? selfVideo;

  @override
  bool operator ==(Object other) =>
      other is InvitedConferenceVideo &&
      other.line == line &&
      mapEquals(other.feeds, feeds) &&
      other.selfVideo == selfVideo;

  @override
  int get hashCode => Object.hash(line, Object.hashAllUnordered(feeds.entries.map((e) => (e.key, e.value))), selfVideo);

  @override
  String toString() => 'InvitedConferenceVideo(line: $line, feeds: ${feeds.keys.toList()}, self: ${selfVideo != null})';
}
