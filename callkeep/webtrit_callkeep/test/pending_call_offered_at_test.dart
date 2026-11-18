import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

void main() {
  test('a push carries Core\'s offered_at as offeredAt', () {
    final call = PendingCall.fromMap({'callId': 'c1', 'number': '100', 'offeredAt': '1795000000123'});

    expect(call.offeredAt, 1795000000123);
  });

  test('a push from an older Core has no offeredAt', () {
    final call = PendingCall.fromMap({'callId': 'c1', 'number': '100'});

    expect(call.offeredAt, isNull);
  });
}
