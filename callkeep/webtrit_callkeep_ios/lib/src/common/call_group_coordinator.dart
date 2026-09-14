import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

import 'call_group_assignment.dart';

/// Asks the native side to ungroup [callIds]; null when it did.
typedef NativeGroupRelease = Future<CallkeepCallRequestError?> Function(List<String> callIds);

/// Asks the native side to group [callIds] as one; null when it did.
typedef NativeGrouping = Future<CallkeepCallRequestError?> Function(List<String> callIds);

/// Owns the group record and runs the grouping requests against it.
///
/// A request is a sequence of stages, each an answer from CallKit awaited: the members that
/// left are released, then the group that remains is stated. Requests run one at a time, in
/// order, so each is planned against what the ones before it left. Between stages anything
/// can happen to the calls - a member ends, a new call takes an ended one's id, the provider
/// is reset, the session is torn down - and the coordinator is the one place that knows:
/// every end path reports here, every stage is checked here against the calls as they are
/// when the answer arrives, and the record changes only for what the native side has
/// actually taken. The record itself ([CallGroupAssignment]) knows nothing of sessions or
/// time; it only knows who is grouped.
class CallGroupCoordinator {
  CallGroupCoordinator({required NativeGroupRelease release, required NativeGrouping group})
    : _nativeRelease = release,
      _nativeGroup = group;

  final NativeGroupRelease _nativeRelease;
  final NativeGrouping _nativeGroup;
  final CallGroupAssignment _record = CallGroupAssignment();

  // The session of calls the record describes. Every reset or tearDown starts a new one, and
  // a stage that was asked in an earlier session records nothing when its answer arrives.
  int _session = 0;
  // Which lifetime of a call an id currently names. A call that ended leaves its lifetime
  // behind; a call reported under the same id afterwards is a new one, and a stage asked for
  // the old one leaves the new one alone.
  final Map<String, int> _lifetime = {};
  final Set<String> _ended = {};
  int _nextLifetime = 0;
  // Requests run one at a time, in the order they were made: each plan is worked out against
  // the record as the requests before it left it, and a request made while another is in
  // flight - a release of a member being grouped, a second name - is answered after it.
  Future<void> _queue = Future.value();

  /// The name of the one live group, or null while there is none.
  String? get liveGroupId => _record.liveGroupId;

  bool isGrouped(String callId) => _record.membersWith(callId).isNotEmpty;

  /// Every call sharing a group with [callId], [callId] included; empty when it is in none.
  List<String> membersWith(String callId) => _record.membersWith(callId);

  /// [callId] was reported to CallKit. A call that is already live keeps its lifetime; an id
  /// that ended, or was never seen, names a new call from here on.
  void callReported(String callId) {
    if (_ended.remove(callId) || !_lifetime.containsKey(callId)) _lifetime[callId] = _nextLifetime++;
  }

  /// [callId] ended, whoever ended it: it is in no group, and its lifetime is over - a call
  /// reported under the same id later is not the one a request in flight was asked for.
  void callEnded(String callId) {
    _ended.add(callId);
    _record.release([callId]);
  }

  /// Every call is gone - the provider was reset or torn down. A request still in flight for
  /// them records nothing when its answer arrives and asks CallKit for nothing more.
  void sessionEnded() {
    _record.clear();
    _ended.clear();
    _lifetime.clear();
    _session++;
    // A request of the old session that is still waiting on CallKit is over as far as the
    // record is concerned - its answer will find the session gone - so the next session's
    // requests do not queue behind it.
    _queue = Future.value();
  }

  /// The members of [callIds] that are the same live calls they were when the request was made.
  List<String> _stillLive(List<String> callIds, Map<String, int?> asked) =>
      callIds.where((id) => !_ended.contains(id) && _lifetime[id] == asked[id]).toList();

  /// Runs [request] after every request made before it, for the calls as they are when its
  /// turn comes.
  ///
  /// A request is about the session and the calls it was made in, not the ones its turn finds:
  /// while it waits in the queue the session may end and a member may end and be reported
  /// again under the same id. So the session and the lifetime of every named call are taken
  /// here, when the request is made, and checked when its turn comes - a request of a session
  /// that ended is over, and a member that is not the call it named is left out - and again
  /// after every stage the request awaits. The list is copied, so the request is the one that
  /// was made even if the caller changes its list afterwards.
  Future<CallkeepCallRequestError?> _inTurn(
    List<String> callIds,
    Future<CallkeepCallRequestError?> Function(List<String> callIds, _Asked asked) request,
  ) {
    final asked = _Asked(_session, {for (final id in callIds) id: _lifetime[id]});
    final named = List.of(callIds);
    final turn = _queue.then((_) {
      if (asked.session != _session) return null;
      return request(_stillLive(named, asked.lifetimes), asked);
    });
    _queue = turn.then((_) {}, onError: (_) {});
    return turn;
  }

  /// Declares [callIds] as the whole membership of the group [groupId].
  ///
  /// The declaration is reconciled here, because CallKit keeps no record of who is grouped
  /// with whom and a whole-membership request means nothing without one. Members that left
  /// are ungrouped first; then the group that remains, if it is still a group, is stated in
  /// full, which the native side turns into one transaction grouping every member with the
  /// first. Stating it in full is idempotent, so a member already in place costs nothing.
  ///
  /// The record describes what CallKit shows, so it changes only once CallKit has taken a
  /// stage: a refused release leaves the members recorded and a retry asks again, and a
  /// refused grouping leaves nobody grouped. The change is worked out on a copy first.
  Future<CallkeepCallRequestError?> declare(String groupId, List<String> callIds) =>
      _inTurn(callIds, (callIds, asked) => _declare(groupId, callIds, asked));

  Future<CallkeepCallRequestError?> _declare(String groupId, List<String> callIds, _Asked asked) async {
    // One group at a time. A second name while another group is live is refused with the
    // answer CallKit gives for its own group limit, and nothing changes.
    final live = _record.liveGroupId;
    if (live != null && live != groupId) return CallkeepCallRequestError.maximumCallGroupsReached;

    final planned = _record.copy();
    final change = planned.declare(groupId, callIds);

    final released = await _releaseStage(change.removed);
    if (released != null) return released;
    if (asked.session != _session) return null;
    _record.release(change.removed);

    final members = callIds.isEmpty
        ? const <String>[]
        : _stillLive(planned.membersWith(callIds.first), asked.lifetimes);
    if (members.length < 2) return null;
    final grouped = await _nativeGroup(members);
    if (grouped != null) return grouped;
    if (asked.session != _session) return null;
    // CallKit answered for the calls as they were when asked; a member that ended meanwhile,
    // or that is a new call under an old id, is not recorded as grouped by that answer.
    _record.declare(groupId, _stillLive(callIds, asked.lifetimes));
    return null;
  }

  /// Takes [callIds] out of their group; a group left with one member is dissolved.
  Future<CallkeepCallRequestError?> release(List<String> callIds) => _inTurn(callIds, _release);

  Future<CallkeepCallRequestError?> _release(List<String> callIds, _Asked asked) async {
    final removed = _record.copy().release(callIds).removed;
    final released = await _releaseStage(removed);
    if (released != null) return released;
    // The answer is for the session that asked; a record the next session built under the
    // same call ids is not touched by it.
    if (asked.session != _session) return null;
    _record.release(callIds);
    return null;
  }

  Future<CallkeepCallRequestError?> _releaseStage(List<String> callIds) async {
    if (callIds.isEmpty) return null;
    return _nativeRelease(callIds);
  }
}

/// What a request was made about: the session, and which lifetime of each named call.
class _Asked {
  const _Asked(this.session, this.lifetimes);

  final int session;
  final Map<String, int?> lifetimes;
}
