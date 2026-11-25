import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call_pull/cubit/own_call_ids.dart';
import 'package:webtrit_phone/models/models.dart';

InUseLineState _ringing(String callId) => InUseLineState(callId: callId, ringingOnly: true);

InUseLineState _own(String callId) => InUseLineState(callId: callId, ringingOnly: false);

void main() {
  final start = DateTime(2026, 11, 25, 12);
  late OwnCallIds ids;

  setUp(() => ids = OwnCallIds());

  test('a call on a line is left out, ringing included', () {
    ids.update([_ringing('a'), _own('b')], start);

    expect(ids.contains('a', start), isTrue);
    expect(ids.contains('b', start), isTrue);
  });

  test('a call that only rang here is forgotten when it leaves the line', () {
    ids.update([_ringing('forked')], start);
    ids.update([], start);

    expect(ids.contains('forked', start), isFalse);
  });

  test('a call shown as more than ringing stays out after it leaves the line', () {
    ids.update([_ringing('own')], start);
    ids.update([_own('own')], start);
    ids.update([], start);

    expect(ids.contains('own', start.add(const Duration(minutes: 4))), isTrue);
  });

  test('an own call that ends while it looks like ringing again stays own', () {
    ids.update([_own('call')], start);
    ids.update([_ringing('call')], start);
    ids.update([], start);

    expect(ids.contains('call', start), isTrue);
  });

  test('an own call is forgotten when its time to stay out has passed', () {
    ids.update([_own('own')], start);
    ids.update([], start);

    expect(ids.contains('own', start.add(const Duration(minutes: 5, seconds: 1))), isFalse);
  });

  test('a call never on a line here is not left out', () {
    ids.update([_own('mine')], start);

    expect(ids.contains('elsewhere', start), isFalse);
  });
}
