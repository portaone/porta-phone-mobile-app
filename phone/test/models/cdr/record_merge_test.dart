import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

// The backend reports several records under one Call-ID: a transfer back is the incoming call,
// the forwarded leg and the call that came back; an IVR call is an outgoing leg and the same leg
// again with no direction. A list keys its rows by the record, and shows the IVR call once.
void main() {
  CdrRecord record(CallDirection direction, int secondsAfter) => CdrRecord(
    callId: 'KNMZv24z',
    direction: direction,
    status: CdrStatus.accepted,
    callee: '555006',
    calleeNumber: '555006',
    caller: '555011',
    callerNumber: '555011',
    connectTime: DateTime.utc(2026, 11, 18, 11, 2).add(Duration(seconds: secondsAfter)),
    disconnectTime: DateTime.utc(2026, 11, 18, 11, 3),
    disconnectReason: 'Normal call clearing',
    duration: const Duration(seconds: 5),
  );

  test('every record of a transfer back is a row of its own', () {
    final first = record(CallDirection.incoming, 0);
    final forwarded = record(CallDirection.forwarded, 19);
    final back = record(CallDirection.incoming, 27);

    final list = <CdrRecord>[].mergeWithUpdate(first).mergeWithUpdate(forwarded).mergeWithUpdate(back).toList();

    expect(list, [back, forwarded, first]);
  });

  test('a record that arrives again replaces itself', () {
    final first = record(CallDirection.incoming, 0);
    final again = record(CallDirection.incoming, 0);

    expect([first].mergeWithUpdate(again).toList(), hasLength(1));
    expect([first].mergeWithHistory([again]).toList(), hasLength(1));
  });

  test('the unattributed copy of an IVR call is not shown beside the attributed one', () {
    final outgoing = record(CallDirection.outgoing, 0);
    final copy = record(CallDirection.unknown, 0);

    expect([outgoing].mergeWithUpdate(copy).toList(), [outgoing]);
    expect([copy].mergeWithUpdate(outgoing).toList(), [outgoing]);
  });

  test('history pages of a transfer back are not merged into one row', () {
    final first = record(CallDirection.incoming, 0);
    final back = record(CallDirection.incoming, 27);

    expect([back].mergeWithHistory([first]).toList(), [back, first]);
  });
}
