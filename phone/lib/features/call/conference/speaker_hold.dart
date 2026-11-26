import 'dart:async';

/// Who the room shows as speaking: the room's word for it, held for a while
/// after every change so that the highlight does not flicker.
///
/// The room names whoever started talking last (`speaker` of
/// `conference_video_updated`) and keeps naming him through silence, so the
/// word only changes when somebody else starts. Two people cutting into each
/// other would move it back and forth several times a second; the highlight
/// that follows it then blinks between their tiles. So a new speaker is
/// shown at once when the last change is at least [hold] old, and otherwise
/// at the end of that [hold] - and only if the room still names him then: a
/// word taken back within the hold never shows.
///
/// Nobody speaking (`null`) is shown at once: it comes when the video is
/// left, and nothing is held over from a room that is gone.
///
/// It knows nothing of signaling or of the room's state; the owner tells it
/// what the room said and is told what to show.
class SpeakerHold {
  SpeakerHold({
    required this.onChanged,
    this.hold = const Duration(seconds: 1),
    Timer Function(Duration, void Function())? createTimer,
    DateTime Function()? now,
  }) : _createTimer = createTimer ?? Timer.new,
       _now = now ?? DateTime.now;

  /// Told the feed to show as speaking, every time it changes.
  final void Function(int? speaker) onChanged;

  /// How long a speaker shown stays before the next one may take his place.
  final Duration hold;

  /// Makes the timer of a held change; a test passes one it can let pass by hand.
  final Timer Function(Duration, void Function()) _createTimer;
  final DateTime Function() _now;

  int? _shown;
  int? _pending;
  DateTime? _shownAt;
  Timer? _timer;

  /// The feed shown as speaking now; `null` while nobody is.
  int? get shown => _shown;

  /// The room named [speaker] - or nobody - as speaking.
  void heard(int? speaker) {
    if (speaker == null) {
      _cancel();
      _show(null);
      return;
    }
    if (speaker == _shown) {
      // Back to the one shown within the hold: the change waiting is void.
      _cancel();
      return;
    }
    final shownAt = _shownAt;
    final since = shownAt == null ? null : _now().difference(shownAt);
    if (_shown == null || since == null || since >= hold) {
      _cancel();
      _show(speaker);
      return;
    }
    _pending = speaker;
    _timer ??= _createTimer(hold - since, _release);
  }

  /// The video is left: nobody is shown and nothing waits.
  void clear() => heard(null);

  void _release() {
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null && pending != _shown) _show(pending);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void _show(int? speaker) {
    if (speaker == _shown) return;
    _shown = speaker;
    _shownAt = speaker == null ? null : _now();
    onChanged(speaker);
  }
}
