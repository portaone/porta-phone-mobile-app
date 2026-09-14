/// Which group each call belongs to, and how a declared membership changes it.
///
/// A record of membership and nothing else: it knows who is grouped, not when a request was
/// asked or whether the calls are still live. [CallGroupCoordinator] owns those questions.
///
/// CallKit keeps no readable record of which calls are grouped, and a whole-membership
/// request only means something against a record: a member left off the list has to be
/// taken out, and a call named on its own has to leave the group it was in. So the record
/// lives here, on the Dart side, and the native side is only ever told what to do.
///
/// The rules are the ones the Android standalone backend applies, so that both platforms
/// reconcile the same declaration the same way: a declared membership is exact, a group needs
/// two calls, and an empty list changes nothing.
class CallGroupAssignment {
  CallGroupAssignment([Map<String, String>? groups]) : _groups = Map.of(groups ?? const {});

  final Map<String, String> _groups;

  /// An independent record with the same membership, for working out a change before it is
  /// known whether the native side takes it.
  CallGroupAssignment copy() => CallGroupAssignment(_groups);

  /// The name of the one live group, or null while there is none.
  String? get liveGroupId => _groups.values.firstOrNull;

  /// The group each call is in. Calls in no group are absent.
  Map<String, String> get groups => Map.unmodifiable(_groups);

  /// Every call that shares a group with [callId], [callId] included, or empty when it is
  /// in no group.
  List<String> membersWith(String callId) {
    final group = _groups[callId];
    if (group == null) return const [];
    return _groups.entries.where((e) => e.value == group).map((e) => e.key).toList()..sort();
  }

  /// Declares [callIds] to be the whole membership of the group [groupId].
  ///
  /// Returns which calls left a group as a result. One group at a time: whatever was grouped
  /// before and is not listed now is out, whichever name it had. A list of one is a
  /// declaration that the call stands alone, which takes its group apart. An empty list names
  /// no group at all. Telling a second name apart from the live one is the caller's business.
  CallGroupChange declare(String groupId, List<String> callIds) {
    if (callIds.isEmpty) return const CallGroupChange.none();
    final before = Map.of(_groups);
    _groups.clear();
    for (final id in callIds) {
      _groups[id] = groupId;
    }
    _dropLoneMembers();
    return _diff(before);
  }

  /// Takes [callIds] out of whatever group they are in. A group left with one member is
  /// dissolved, and an empty list does nothing.
  CallGroupChange release(List<String> callIds) {
    if (callIds.isEmpty) return const CallGroupChange.none();
    final before = Map.of(_groups);
    callIds.forEach(_groups.remove);
    _dropLoneMembers();
    return _diff(before);
  }

  /// Forgets [callId] entirely: a call that has ended is in no group.
  CallGroupChange forget(String callId) => release([callId]);

  void clear() => _groups.clear();

  void _dropLoneMembers() {
    final sizes = <String, int>{};
    for (final g in _groups.values) {
      sizes[g] = (sizes[g] ?? 0) + 1;
    }
    _groups.removeWhere((_, g) => (sizes[g] ?? 0) < 2);
  }

  CallGroupChange _diff(Map<String, String> before) {
    final removed = before.keys.where((id) => !_groups.containsKey(id)).toList()..sort();
    final added = _groups.keys.where((id) => !before.containsKey(id)).toList()..sort();
    return CallGroupChange(removed: removed, added: added);
  }
}

/// What a declaration changed: which calls are no longer in any group, and which joined one.
class CallGroupChange {
  const CallGroupChange({required this.removed, required this.added});

  const CallGroupChange.none() : removed = const [], added = const [];

  final List<String> removed;
  final List<String> added;

  bool get isEmpty => removed.isEmpty && added.isEmpty;
}
