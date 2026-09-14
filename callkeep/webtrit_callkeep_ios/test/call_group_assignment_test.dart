import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/call_group_assignment.dart';

/// The membership rules the iOS side reconciles a declaration against.
///
/// These are the same cases the Android standalone backend is tested on, so both platforms
/// answer one declaration the same way: a declared membership is exact, a group needs two
/// calls, an empty list changes nothing.
void main() {
  group('CallGroupAssignment.declare', () {
    test('two calls form one group and nobody is removed', () {
      final a = CallGroupAssignment();
      final change = a.declare('room', ['A', 'B']);
      expect(a.membersWith('A'), ['A', 'B']);
      expect(change.removed, isEmpty);
      expect(change.added, ['A', 'B']);
    });

    test('a longer list grows the same group', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      final change = a.declare('room', ['A', 'B', 'C']);
      expect(a.membersWith('C'), ['A', 'B', 'C']);
      expect(a.groups.values.toSet().length, 1);
      expect(change.removed, isEmpty);
      expect(change.added, ['C']);
    });

    test('restating the same membership changes nothing', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      final change = a.declare('room', ['B', 'A']);
      expect(change.isEmpty, isTrue);
      expect(a.membersWith('A'), ['A', 'B']);
    });

    test('a member left off the list is removed - the shrink the review found', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B', 'C']);
      final change = a.declare('room', ['A', 'B']);
      expect(change.removed, ['C']);
      expect(a.membersWith('A'), ['A', 'B']);
      expect(a.membersWith('C'), isEmpty);
    });

    test('naming a single call takes its whole group apart', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B', 'C']);
      final change = a.declare('room', ['A']);
      expect(change.removed, ['A', 'B', 'C']);
      expect(a.groups, isEmpty);
    });

    test('an empty list names no group and changes nothing', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      expect(a.declare('room', []).isEmpty, isTrue);
      expect(a.membersWith('A'), ['A', 'B']);
    });

    test('there is one group at a time - declaring another replaces it', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      final change = a.declare('room', ['C', 'D']);
      expect(a.groups.values.toSet().length, 1);
      expect(a.membersWith('A'), isEmpty);
      expect(a.membersWith('C'), ['C', 'D']);
      expect(change.removed, ['A', 'B']);
      expect(change.added, ['C', 'D']);
    });

    test('a member left off the list leaves, whatever it was grouped with', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B', 'C']);
      final change = a.declare('room', ['A', 'C']);
      expect(a.membersWith('A'), ['A', 'C']);
      expect(change.removed, ['B']);
    });
  });

  group('CallGroupAssignment.release', () {
    test('releasing one of three leaves the other two grouped', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B', 'C']);
      final change = a.release(['C']);
      expect(change.removed, ['C']);
      expect(a.membersWith('A'), ['A', 'B']);
    });

    test('releasing one of two dissolves the group, and both count as removed', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      final change = a.release(['A']);
      expect(change.removed, ['A', 'B']);
      expect(a.groups, isEmpty);
    });

    test('releasing an empty list does nothing', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      expect(a.release([]).isEmpty, isTrue);
      expect(a.membersWith('A'), ['A', 'B']);
    });

    test('a call that ends is forgotten and its lone partner is released with it', () {
      final a = CallGroupAssignment()..declare('room', ['A', 'B']);
      final change = a.forget('B');
      expect(change.removed, ['A', 'B']);
      expect(a.groups, isEmpty);
    });
  });
}
