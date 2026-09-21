import 'package:equatable/equatable.dart';

/// One user's notification mute on one conversation, as the core stores it.
///
/// The two fields are not one value. [muted] without [mutedUntil] is "muted
/// forever"; [muted] with one is "muted until that moment". Not muted is
/// [none].
///
/// A timed mute **expires silently**: nothing runs at the expiry moment, no job
/// clears the flag and no event reaches the clients. The core derives the state
/// on every read, and so must every reader here - which is why the question is
/// [isActiveAt] with a time, and not a field. A [muted] answered once outlives
/// the mute.
class NotificationMute extends Equatable {
  const NotificationMute({required this.muted, this.mutedUntil});

  /// A conversation nobody has muted.
  ///
  /// Also what a core that does not carry the mute fields at all reports, which
  /// reads the same way: nothing is muted.
  static const none = NotificationMute(muted: false);

  final bool muted;

  /// The moment the mute lapses, or null when it was set to last forever.
  final DateTime? mutedUntil;

  /// Whether notifications are muted at [now].
  ///
  /// Pass the current time rather than caching the answer: the expiry passes
  /// with no event to notice it.
  bool isActiveAt(DateTime now) {
    if (!muted) return false;

    final until = mutedUntil;
    return until == null || until.isAfter(now);
  }

  @override
  List<Object?> get props => [muted, mutedUntil];

  @override
  String toString() {
    return 'NotificationMute(muted: $muted, mutedUntil: $mutedUntil)';
  }
}
