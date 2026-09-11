import 'dart:convert';

import 'package:test/test.dart';

import 'package:signaling/src/events/events.dart';

void main() {
  const participants = [
    ConferenceParticipant(line: 0, callId: 'abc'),
    ConferenceParticipant(line: 1, callId: 'def', muted: true),
  ];

  group('$ConferenceParticipant', () {
    test('fromJson reads muted, absent muted means false', () {
      expect(
        ConferenceParticipant.fromJson({'line': 1, 'call_id': 'def', 'muted': true}),
        equals(const ConferenceParticipant(line: 1, callId: 'def', muted: true)),
      );
      expect(ConferenceParticipant.fromJson({'line': 0, 'call_id': 'abc'}).muted, isFalse);
    });

    test('listFromJson of null is empty', () {
      expect(ConferenceParticipant.listFromJson(null), isEmpty);
    });
  });

  group('$ConferenceOfferEvent', () {
    final eventJson = '''
    {
      "event": "conference_offer",
      "room": 4242,
      "jsep": {"type": "offer", "sdp": "v=0"},
      "participants": [
        {"line": 0, "call_id": "abc", "muted": false},
        {"line": 1, "call_id": "def", "muted": true}
      ]
    }
    ''';
    const event = ConferenceOfferEvent(room: 4242, jsep: {'type': 'offer', 'sdp': 'v=0'}, participants: participants);

    test('Event.fromJson dispatches it as a session event', () {
      expect(Event.fromJson(json.decode(eventJson) as Map<String, dynamic>), equals(event));
    });

    test('toJson round trips', () {
      expect(Event.fromJson(event.toJson()), equals(event));
    });
  });

  group('$ConferenceIceTrickleEvent', () {
    test('a candidate is kept', () {
      final decoded = Event.fromJson({
        'event': 'conference_ice_trickle',
        'candidate': {'candidate': 'a=1', 'sdpMid': '0'},
      });

      expect(decoded, equals(const ConferenceIceTrickleEvent(candidate: {'candidate': 'a=1', 'sdpMid': '0'})));
    });

    test('the completed marker becomes a null candidate and back', () {
      final decoded = Event.fromJson({
        'event': 'conference_ice_trickle',
        'candidate': {'completed': true},
      });

      expect(decoded, equals(const ConferenceIceTrickleEvent(candidate: null)));
      expect((decoded as ConferenceIceTrickleEvent).toJson()['candidate'], {'completed': true});
    });
  });

  group('$ConferenceUpdatedEvent', () {
    test('carries the authoritative participant list', () {
      final decoded = Event.fromJson({
        'event': 'conference_updated',
        'room': 4242,
        'participants': [
          {'line': 0, 'call_id': 'abc', 'muted': false},
        ],
      });

      expect(
        decoded,
        equals(const ConferenceUpdatedEvent(room: 4242, participants: [ConferenceParticipant(line: 0, callId: 'abc')])),
      );
      expect(Event.fromJson((decoded as ConferenceUpdatedEvent).toJson()), equals(decoded));
    });

    test('an empty list is allowed', () {
      final decoded = Event.fromJson({'event': 'conference_updated', 'room': 1, 'participants': []});
      expect((decoded as ConferenceUpdatedEvent).participants, isEmpty);
    });
  });

  group('$ConferenceFailedEvent', () {
    test('video_not_supported with detail', () {
      final decoded = Event.fromJson({
        'event': 'conference_failed',
        'room': 4242,
        'reason': 'video_not_supported',
        'detail': 'line 1 is a video call and the mixer is audio only',
      });

      expect(
        decoded,
        equals(
          const ConferenceFailedEvent(
            room: 4242,
            reason: 'video_not_supported',
            detail: 'line 1 is a video call and the mixer is audio only',
          ),
        ),
      );
    });

    test('room and detail are optional, and toJson omits them when absent', () {
      const event = ConferenceFailedEvent(reason: 'room_create_failed: boom');

      expect(Event.fromJson({'event': 'conference_failed', 'reason': 'room_create_failed: boom'}), equals(event));
      expect(event.toJson(), {'event': 'conference_failed', 'reason': 'room_create_failed: boom'});
    });
  });

  group('$ConferenceTerminatedEvent', () {
    test('with and without room', () {
      expect(
        Event.fromJson({'event': 'conference_terminated', 'room': 4242}),
        equals(const ConferenceTerminatedEvent(room: 4242)),
      );
      expect(Event.fromJson({'event': 'conference_terminated'}), equals(const ConferenceTerminatedEvent()));
      expect(const ConferenceTerminatedEvent().toJson(), {'event': 'conference_terminated'});
    });
  });

  test('an unknown event still throws, so the conference events did not loosen the parser', () {
    expect(() => Event.fromJson({'event': 'conference_something_new', 'room': 1}), throwsArgumentError);
  });
}
