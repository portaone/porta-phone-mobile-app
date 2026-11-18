import 'dart:convert';

import 'package:test/test.dart';

import 'package:signaling/src/events/call/incoming_call_event.dart';

void main() {
  test('$IncomingCallEvent fromJson reads Core\'s offered_at', () {
    const incomingCallEventJson = '''
    {
      "event": "incoming_call",
      "line": 0,
      "call_id": "qwerty",
      "callee": "200",
      "caller": "100",
      "offered_at": 1795000000123
    }
    ''';

    final event = IncomingCallEvent.fromJson(json.decode(incomingCallEventJson) as Map<String, dynamic>);

    expect(event.offeredAt, 1795000000123);
    expect(event.toJson()['offered_at'], 1795000000123);
  });

  test('$IncomingCallEvent fromJson without offered_at, from an older Core', () {
    const incomingCallEventJson = '''
    {
      "event": "incoming_call",
      "line": 0,
      "call_id": "qwerty",
      "callee": "200",
      "caller": "100"
    }
    ''';

    final event = IncomingCallEvent.fromJson(json.decode(incomingCallEventJson) as Map<String, dynamic>);

    expect(event.offeredAt, isNull);
    expect(event.toJson().containsKey('offered_at'), isFalse);
  });

  test('$IncomingCallEvent fromJson takes a fractional offered_at and ignores one that is not a number', () {
    Map<String, dynamic> event(Object offeredAt) => {
      'event': 'incoming_call',
      'line': 0,
      'call_id': 'qwerty',
      'callee': '200',
      'caller': '100',
      'offered_at': offeredAt,
    };

    expect(IncomingCallEvent.fromJson(event(1795000000123.0)).offeredAt, 1795000000123);
    expect(IncomingCallEvent.fromJson(event('1795000000123')).offeredAt, isNull);
  });
}
