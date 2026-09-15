import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

final _logger = Logger('LegMuteSync');

/// Keeps the operating system's mute for every call in the room in step with
/// the room's own, and tells this client's echoes from somebody pressing mute.
///
/// The platform keeps a mute state per call and re-publishes it unasked, so a
/// leg left out of step would ask for the opposite of what the host wants the
/// moment anything made the platform repeat itself - hanging that participant
/// up, or merely changing the audio device. Telling every leg the same thing
/// means nothing it repeats is news.
///
/// Nothing in such a report says whether a person asked for it, and the
/// platform does not wait for the report before the command returns, so a
/// report can still be on its way when the host asks for the opposite. The
/// value alone therefore cannot tell an answer from an intention. What can is
/// what was asked for and in what order.
class LegMuteSync {
  LegMuteSync(this._callkeep);

  final Callkeep _callkeep;

  /// Per call, the commands sent and not yet seen reported back, oldest first.
  final Map<String, Queue<bool>> _awaited = {};

  /// Tells [callIds] the room's mute, and remembers having asked.
  Future<void> apply(Iterable<String> callIds, bool muted) async {
    for (final callId in callIds) {
      final awaited = _awaited[callId] ??= Queue<bool>();
      awaited.add(muted);
      final error = await _callkeep.setMuted(callId, muted: muted);
      if (error != null) {
        // Nothing will come back for a command that was refused; leaving it
        // outstanding would make this client mistake the next real action for
        // its own echo.
        awaited.remove(muted);
        _logger.warning('apply: setMuted error: $error');
      }
    }
  }

  /// Whether this report is the oldest command still outstanding for [callId]
  /// coming home, rather than something a person just did.
  ///
  /// Reports arrive in the order the commands were sent, so the oldest one
  /// outstanding is the one being answered. Anything else - a report with
  /// nothing outstanding to answer, or one that does not match - is somebody
  /// pressing mute.
  bool consume(String callId, bool muted) {
    final awaited = _awaited[callId];
    if (awaited == null || awaited.isEmpty || awaited.first != muted) return false;
    awaited.removeFirst();
    if (awaited.isEmpty) _awaited.remove(callId);
    return true;
  }

  /// Whatever has not come back concerns a room that is over.
  void forgetAll() => _awaited.clear();
}
