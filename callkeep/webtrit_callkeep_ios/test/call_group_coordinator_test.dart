import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep_ios/src/common/call_group_coordinator.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

/// The coordinator against a native side under the test's control: every stage answers
/// when the test says so, so the calls can change between a request and its answer.
void main() {
  late CallGroupCoordinator groups;
  late List<List<String>> releases;
  late List<List<String>> groupings;
  late Completer<CallkeepCallRequestError?> releaseGate;
  late Completer<CallkeepCallRequestError?> groupGate;

  setUp(() {
    releases = [];
    groupings = [];
    releaseGate = Completer()..complete(null);
    groupGate = Completer()..complete(null);
    groups = CallGroupCoordinator(
      release: (ids) {
        releases.add(ids);
        return releaseGate.future;
      },
      group: (ids) {
        groupings.add(ids);
        return groupGate.future;
      },
    );
  });

  group('a declaration', () {
    test('states the whole group once and records it', () async {
      expect(await groups.declare('room', ['a', 'b']), isNull);
      expect(groupings, [
        ['a', 'b'],
      ]);
      expect(releases, isEmpty);
      expect(groups.membersWith('a'), ['a', 'b']);
      expect(groups.liveGroupId, 'room');
    });

    test('releases the members that left, then restates the rest', () async {
      await groups.declare('room', ['a', 'b', 'c']);
      expect(await groups.declare('room', ['a', 'b']), isNull);
      expect(releases, [
        ['c'],
      ]);
      expect(groupings.last, ['a', 'b']);
      expect(groups.isGrouped('c'), isFalse);
    });

    test('of one member takes the group apart and asks for no grouping', () async {
      await groups.declare('room', ['a', 'b']);
      expect(await groups.declare('room', ['a']), isNull);
      expect(releases, [
        ['a', 'b'],
      ]);
      expect(groupings, hasLength(1));
      expect(groups.liveGroupId, isNull);
    });

    test('under a second name is refused while a group is live', () async {
      await groups.declare('room', ['a', 'b']);
      expect(await groups.declare('other', ['c', 'd']), CallkeepCallRequestError.maximumCallGroupsReached);
      expect(groupings, hasLength(1));
      groups.callEnded('a');
      expect(groups.liveGroupId, isNull, reason: 'a lone member is no group');
      expect(await groups.declare('other', ['c', 'd']), isNull);
    });
  });

  group('what CallKit refused stays as it was', () {
    test('a refused release keeps the members recorded for a retry', () async {
      await groups.declare('room', ['a', 'b', 'c']);
      releaseGate = Completer()..complete(CallkeepCallRequestError.internal);
      expect(await groups.declare('room', ['a', 'b']), CallkeepCallRequestError.internal);
      expect(groups.membersWith('c'), ['a', 'b', 'c']);
      releaseGate = Completer()..complete(null);
      expect(await groups.declare('room', ['a', 'b']), isNull);
      expect(groups.membersWith('a'), ['a', 'b']);
    });

    test('a refused grouping after a taken release keeps what CallKit still shows', () async {
      await groups.declare('room', ['a', 'b', 'c']);
      groupGate = Completer()..complete(CallkeepCallRequestError.internal);
      expect(await groups.declare('room', ['a', 'b']), CallkeepCallRequestError.internal);
      expect(groups.isGrouped('c'), isFalse, reason: 'CallKit took the release');
      expect(groups.membersWith('a'), ['a', 'b'], reason: 'the group CallKit still shows stands');
    });

    test('a refused first grouping leaves nobody grouped', () async {
      groupGate = Completer()..complete(CallkeepCallRequestError.internal);
      expect(await groups.declare('room', ['a', 'b']), CallkeepCallRequestError.internal);
      expect(groups.liveGroupId, isNull);
    });
  });

  group('the record follows the calls', () {
    test('a member that ended while CallKit was asked is not recorded', () async {
      groupGate = Completer();
      final request = groups.declare('room', ['a', 'b', 'c']);
      await Future<void>.delayed(Duration.zero);
      groups.callEnded('a');
      groupGate.complete(null);
      expect(await request, isNull);
      expect(groups.isGrouped('a'), isFalse);
      expect(groups.membersWith('b'), ['b', 'c']);
    });

    test('a session that ended during the release stage stops the request there', () async {
      await groups.declare('room', ['a', 'b', 'c']);
      releaseGate = Completer();
      final request = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groups.sessionEnded();
      releaseGate.complete(null);
      expect(await request, isNull);
      expect(groupings, hasLength(1), reason: 'no grouping is asked of a provider that is gone');
      expect(groups.liveGroupId, isNull);
    });

    test('a release answered after a new session leaves that session alone', () async {
      await groups.declare('room', ['a', 'b']);
      releaseGate = Completer();
      final leaving = groups.release(['a']);
      await Future<void>.delayed(Duration.zero);
      groups.sessionEnded();
      for (final id in ['a', 'b']) {
        groups.callReported(id);
      }
      expect(await groups.declare('new-room', ['a', 'b']), isNull);
      releaseGate.complete(null);
      expect(await leaving, isNull);
      expect(groups.membersWith('a'), ['a', 'b']);
    });

    test('a later release is applied after the pending declaration', () async {
      groupGate = Completer();
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      final second = groups.release(['a']);
      await Future<void>.delayed(Duration.zero);
      groupGate.complete(null);
      expect(await first, isNull);
      expect(await second, isNull);
      expect(groups.isGrouped('b'), isFalse, reason: 'the later release is not undone by the earlier declaration');
      expect(releases, [
        ['a', 'b'],
      ]);
    });

    test('a second name waits for the pending first group and is then refused', () async {
      groupGate = Completer();
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      final second = groups.declare('other', ['c', 'd']);
      await Future<void>.delayed(Duration.zero);
      groupGate.complete(null);
      expect(await first, isNull);
      expect(await second, CallkeepCallRequestError.maximumCallGroupsReached);
      expect(groupings, [
        ['a', 'b'],
      ]);
    });

    test('a late answer does not attach a new call that took an ended one\'s id', () async {
      for (final id in ['a', 'b']) {
        groups.callReported(id);
      }
      groupGate = Completer();
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groups.callEnded('a');
      groups.callReported('a');
      groupGate.complete(null);
      expect(await first, isNull);
      expect(groups.isGrouped('a'), isFalse, reason: 'the answer was for the a that ended');
      expect(groups.isGrouped('b'), isFalse, reason: 'b was left alone when that a ended');
    });

    test('a call reported again under an ended id is live again', () async {
      await groups.declare('room', ['a', 'b']);
      groups.callEnded('a');
      groups.callReported('a');
      expect(await groups.declare('room', ['a', 'b']), isNull);
      expect(groups.membersWith('a'), ['a', 'b']);
    });
  });

  group('a request waiting in the queue is about the session and the calls it was made in', () {
    // The first grouping is held by the test; the requests queued behind it are run only once
    // it is answered, by which time the session, or a member, may have been replaced.
    late Completer<CallkeepCallRequestError?> held;

    setUp(() {
      held = Completer();
      groupGate = held;
      for (final id in ['a', 'b', 'c', 'd']) {
        groups.callReported(id);
      }
    });

    test('a release queued before a reset does not ungroup the next session', () async {
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groupGate = Completer()..complete(null);
      final queued = groups.release(['a']);
      groups.sessionEnded();
      for (final id in ['a', 'b']) {
        groups.callReported(id);
      }
      expect(await groups.declare('new-room', ['a', 'b']), isNull);
      held.complete(null);
      expect(await first, isNull);
      expect(await queued, isNull);
      expect(groups.membersWith('b'), ['a', 'b'], reason: 'the release was made in the session that ended');
      expect(releases, isEmpty);
    });

    test('a declaration queued before a reset does not replace the next session\'s group', () async {
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groupGate = Completer()..complete(null);
      final queued = groups.declare('room', ['c', 'd']);
      groups.sessionEnded();
      for (final id in ['a', 'b', 'c', 'd']) {
        groups.callReported(id);
      }
      expect(await groups.declare('room', ['a', 'b']), isNull);
      held.complete(null);
      expect(await first, isNull);
      expect(await queued, isNull);
      expect(groups.membersWith('a'), ['a', 'b'], reason: 'the declaration was made in the session that ended');
      expect(groupings, hasLength(2));
    });

    test('a member replaced while the request waited is left out of it', () async {
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groupGate = Completer()..complete(null);
      final queued = groups.declare('room', ['a', 'b', 'c']);
      groups.callEnded('c');
      groups.callReported('c');
      held.complete(null);
      expect(await first, isNull);
      expect(await queued, isNull);
      expect(groups.isGrouped('c'), isFalse, reason: 'the request named the c that ended, not its successor');
      expect(groups.membersWith('a'), ['a', 'b']);
      expect(groupings.last, ['a', 'b']);
    });

    test('the list a request was made with is the one it runs with', () async {
      final first = groups.declare('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      groupGate = Completer()..complete(null);
      final members = ['a', 'b', 'c'];
      final queued = groups.declare('room', members);
      members.removeLast();
      held.complete(null);
      expect(await first, isNull);
      expect(await queued, isNull);
      expect(groups.membersWith('a'), ['a', 'b', 'c']);
    });
  });
}
