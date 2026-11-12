import 'package:quiver/collection.dart';

import 'package:webtrit_phone/models/models.dart';

/// The calls of this device that the call pull list leaves out, by call id.
///
/// A call on a line of this device is left out while it is there, ringing
/// included. After it leaves the line it is left out for [ttl] more, unless it
/// only rang here: a forked call keeps its call id on every device of the
/// account, and the call that rang here and was answered on another device is
/// the one to offer for pulling. Any other call - placed here, answered here,
/// or with an answer started here that did not go through - is this device's
/// own, and its dialog lingers on the server after it ends.
class OwnCallIds {
  OwnCallIds({this.ttl = const Duration(minutes: 5), int maximumSize = 50})
    : _own = LruMap<String, DateTime>(maximumSize: maximumSize);

  /// How long an own call is left out after it leaves the line.
  final Duration ttl;

  /// The own calls, with the last time a line held them.
  final LruMap<String, DateTime> _own;

  Set<String> _onLine = const {};

  /// The calls on the lines of this device now. A call becomes own the first
  /// time a line shows it as more than ringing, and stays own while it lives.
  void update(Iterable<InUseLineState> lines, DateTime now) {
    _onLine = {for (final line in lines) line.callId};
    for (final line in lines) {
      if (!line.ringingOnly || _own.containsKey(line.callId)) _own[line.callId] = now;
    }
    _forgetExpired(now);
  }

  /// Whether the pull list leaves [callId] out at [now].
  bool contains(String callId, DateTime now) {
    if (_onLine.contains(callId)) return true;
    final seen = _own[callId];
    if (seen == null) return false;
    if (now.difference(seen) > ttl) {
      _own.remove(callId);
      return false;
    }
    return true;
  }

  int get onLineCount => _onLine.length;

  int get ownCount => _own.length;

  void _forgetExpired(DateTime now) {
    final expired = [
      for (final entry in _own.entries)
        if (now.difference(entry.value) > ttl) entry.key,
    ];
    expired.forEach(_own.remove);
  }
}
