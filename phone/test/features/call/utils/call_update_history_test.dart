import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/utils/call_update_history.dart';

const _callId = 'call-abc';
const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 RTP/AVP 8\r\n'};
const _answer = {'type': 'answer', 'sdp': 'v=0\r\nm=audio 9 RTP/AVP 8\r\n'};

CallEventLog _update(int timestamp) => CallEventLog(
  timestamp: timestamp,
  callEvent: const UpdatingCallEvent(line: 0, callId: _callId, callee: 'callee', caller: '1234', jsep: _offer),
);

CallRequestLog _request(int timestamp, Map<String, dynamic> jsep) => CallRequestLog(
  timestamp: timestamp,
  callRequest: UpdateRequest(transaction: 't-$timestamp', line: 0, callId: _callId, jsep: jsep),
);

const _accepted = CallEventLog(timestamp: 2, callEvent: AcceptedEvent(line: 0, callId: _callId));

// The log is newest first.
void main() {
  test('a log without updates has none pending', () {
    final history = CallUpdateHistory([_accepted]);

    expect(history.count, 0);
    expect(history.pending, isNull);
  });

  test('an update with nothing after it is pending, numbered by its place', () {
    final history = CallUpdateHistory([_update(10), _accepted]);

    expect(history.count, 1);
    expect(history.pending?.ordinal, 1);
    expect(history.pending?.event.jsep, _offer);
  });

  test('the client\'s answer closes the update before it', () {
    final history = CallUpdateHistory([_request(11, _answer), _update(10), _accepted]);

    expect(history.count, 1);
    expect(history.pending, isNull);
  });

  test('an offer the client sent itself does not close the update', () {
    final history = CallUpdateHistory([_request(11, _offer), _update(10), _accepted]);

    expect(history.pending?.ordinal, 1);
  });

  test('of several updates only the newest can be pending, and it has the last number', () {
    final open = CallUpdateHistory([_update(20), _request(11, _answer), _update(10), _accepted]);
    final closed = CallUpdateHistory([
      _request(21, _answer),
      _update(20),
      _request(11, _answer),
      _update(10),
      _accepted,
    ]);

    expect(open.count, 2);
    expect(open.pending?.ordinal, 2);
    expect(closed.count, 2);
    expect(closed.pending, isNull);
  });

  test('requests and other events do not take a number', () {
    final history = CallUpdateHistory([
      _update(30),
      const CallEventLog(timestamp: 25, callEvent: UpdatedEvent(line: 0, callId: _callId)),
      _request(21, _answer),
      _update(20),
      _request(12, _offer),
      _accepted,
    ]);

    expect(history.count, 2);
    expect(history.pending?.ordinal, 2);
  });

  test('an update that carries no offer is counted but owes no answer', () {
    const noOffer = CallEventLog(
      timestamp: 10,
      callEvent: UpdatingCallEvent(line: 0, callId: _callId, callee: 'callee', caller: '1234'),
    );
    final history = CallUpdateHistory([noOffer, _accepted]);

    expect(history.count, 1);
    expect(history.pending, isNull, reason: 'the client answers no such update, so no log ever shows it answered');
  });
}
