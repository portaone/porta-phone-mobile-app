import 'dart:convert';

import 'package:test/test.dart';

import 'package:signaling/signaling.dart';

Event decode(String source) => Event.fromJson(json.decode(source) as Map<String, dynamic>);

void main() {
  group('$ConferenceVideoOfferEvent and $ConferenceVideoPublisherAnswerEvent', () {
    test('carry the jsep and round trip', () {
      final offer = decode('{"event": "conference_video_offer", "jsep": {"type": "offer", "sdp": "v=0"}}');
      final answer = decode('{"event": "conference_video_publisher_answer", "jsep": {"type": "answer", "sdp": "v=0"}}');

      expect(offer, equals(const ConferenceVideoOfferEvent(jsep: {'type': 'offer', 'sdp': 'v=0'})));
      expect(answer, equals(const ConferenceVideoPublisherAnswerEvent(jsep: {'type': 'answer', 'sdp': 'v=0'})));
      expect(Event.fromJson(offer.toJson()), equals(offer));
      expect(Event.fromJson(answer.toJson()), equals(answer));
    });
  });

  group('$ConferenceVideoUpdatedEvent', () {
    // The example of the Core conference guide, section 4.5.
    const source = '''
    {"event": "conference_video_updated", "room": 4242, "self": 1,
     "streams": [{"mid": "0", "feed": 2, "kind": "camera"},
                 {"mid": "1", "feed": 3, "kind": "screen"}],
     "publishers": [{"feed": 1, "display": "Alice", "line": null, "kinds": ["camera"]},
                    {"feed": 2, "display": "1002", "line": 0, "kinds": ["camera"]},
                    {"feed": 3, "display": "Bob", "line": 1, "kinds": ["camera", "screen"]}],
     "participants": [{"feed": 1, "display": "Alice", "host": true, "muted": false},
                      {"feed": 2, "display": "1002", "host": false, "muted": false},
                      {"feed": 3, "display": "Bob", "host": false, "muted": true},
                      {"feed": 100, "display": "Ann", "host": false, "muted": false, "guest": true}],
     "speaker": 2, "presenter": 3}
    ''';
    const event = ConferenceVideoUpdatedEvent(
      room: 4242,
      self: 1,
      streams: [
        ConferenceVideoStream(mid: '0', feed: 2, kind: ConferenceVideoKind.camera),
        ConferenceVideoStream(mid: '1', feed: 3, kind: ConferenceVideoKind.screen),
      ],
      publishers: [
        ConferenceVideoPublisher(feed: 1, display: 'Alice', kinds: [ConferenceVideoKind.camera]),
        ConferenceVideoPublisher(feed: 2, display: '1002', line: 0, kinds: [ConferenceVideoKind.camera]),
        ConferenceVideoPublisher(
          feed: 3,
          display: 'Bob',
          line: 1,
          kinds: [ConferenceVideoKind.camera, ConferenceVideoKind.screen],
        ),
      ],
      participants: [
        ConferenceVideoParticipant(feed: 1, display: 'Alice', host: true),
        ConferenceVideoParticipant(feed: 2, display: '1002'),
        ConferenceVideoParticipant(feed: 3, display: 'Bob', muted: true),
        ConferenceVideoParticipant(feed: 100, display: 'Ann', guest: true),
      ],
      speaker: 2,
      presenter: 3,
    );

    test('reads the guide example', () {
      expect(decode(source), equals(event));
    });

    test('round trips', () {
      expect(Event.fromJson(event.toJson()), equals(event));
    });

    test('speaker and presenter are left out by Core when there is none', () {
      final decoded = Event.fromJson({
        'event': 'conference_video_updated',
        'room': 4242,
        'self': 2,
        'streams': [],
        'publishers': [],
        'participants': [
          {'feed': 1, 'display': null, 'host': true, 'muted': false},
        ],
      });

      expect(
        decoded,
        equals(
          const ConferenceVideoUpdatedEvent(
            room: 4242,
            self: 2,
            participants: [ConferenceVideoParticipant(feed: 1, host: true)],
          ),
        ),
      );
      expect(decoded.toJson().containsKey('speaker'), isFalse);
    });

    test('a malformed entry is left out and the event still reads', () {
      final decoded =
          Event.fromJson({
                'event': 'conference_video_updated',
                'room': 1,
                'self': 1,
                'streams': [
                  {'mid': 0, 'feed': 2, 'kind': 'camera'},
                  {'mid': '1', 'feed': 3, 'kind': 'camera'},
                ],
                'publishers': [
                  {'display': 'no feed'},
                  {'feed': 3, 'display': 5, 'kinds': 'camera'},
                ],
                'participants': [
                  'not a participant',
                  {'feed': 3, 'display': 'Bob'},
                ],
              })
              as ConferenceVideoUpdatedEvent;

      expect(decoded.streams, const [ConferenceVideoStream(mid: '1', feed: 3, kind: ConferenceVideoKind.camera)]);
      expect(decoded.publishers, const [ConferenceVideoPublisher(feed: 3)]);
      expect(decoded.participants, const [ConferenceVideoParticipant(feed: 3, display: 'Bob')]);
    });

    test('a stream kind from a newer Core is unknown, not an error', () {
      final decoded =
          Event.fromJson({
                'event': 'conference_video_updated',
                'room': 1,
                'self': 1,
                'streams': [
                  {'mid': '0', 'feed': 2, 'kind': 'whiteboard'},
                ],
              })
              as ConferenceVideoUpdatedEvent;

      expect(decoded.streams.single.kind, ConferenceVideoKind.unknown);
    });
  });

  group('$ConferenceVideoFailedEvent', () {
    test('a room refusal names the PeerConnection and carries Janus code and text', () {
      final decoded = Event.fromJson({
        'event': 'conference_video_failed',
        'pc': 'publisher',
        'reason': 'Maximum number of active publishers (100) already reached',
        'code': 432,
      });

      expect(
        decoded,
        equals(
          const ConferenceVideoFailedEvent(
            pc: ConferenceVideoPc.publisher,
            reason: 'Maximum number of active publishers (100) already reached',
            code: 432,
          ),
        ),
      );
      expect(Event.fromJson(decoded.toJson()), equals(decoded));
    });

    test('a refusal relayed to an invited far end names the request instead', () {
      final decoded = Event.fromJson({
        'event': 'conference_video_failed',
        'request': 'conference_video_answer',
        'reason': 'not_subscribed',
      });

      expect(
        decoded,
        equals(const ConferenceVideoFailedEvent(request: 'conference_video_answer', reason: 'not_subscribed')),
      );
      expect(decoded.toJson(), {
        'event': 'conference_video_failed',
        'request': 'conference_video_answer',
        'reason': 'not_subscribed',
      });
    });
  });

  test('$ConferenceVideoFailedEvent without a text still reads', () {
    expect(
      Event.fromJson({'event': 'conference_video_failed', 'pc': 'subscriber', 'code': 428}),
      equals(const ConferenceVideoFailedEvent(pc: ConferenceVideoPc.subscriber, reason: '', code: 428)),
    );
  });

  group('$ConferenceVideoIceTrickleEvent', () {
    test('tags the candidate with its PeerConnection', () {
      final decoded = Event.fromJson({
        'event': 'conference_video_ice_trickle',
        'pc': 'subscriber',
        'candidate': {'candidate': 'candidate:1', 'sdpMid': '0', 'sdpMLineIndex': 0},
      });

      expect(
        decoded,
        equals(
          const ConferenceVideoIceTrickleEvent(
            pc: ConferenceVideoPc.subscriber,
            candidate: {'candidate': 'candidate:1', 'sdpMid': '0', 'sdpMLineIndex': 0},
          ),
        ),
      );
    });

    test('the completed marker is a null candidate and back', () {
      final decoded = Event.fromJson({
        'event': 'conference_video_ice_trickle',
        'pc': 'publisher',
        'candidate': {'completed': true},
      });

      expect(decoded, equals(const ConferenceVideoIceTrickleEvent(pc: ConferenceVideoPc.publisher)));
      expect(decoded.toJson()['candidate'], {'completed': true});
    });
  });

  test('$ConferenceVideoIceTrickleEvent with a pc from a newer Core is read, not failed', () {
    final decoded =
        Event.fromJson({
              'event': 'conference_video_ice_trickle',
              'pc': 'mixer',
              'candidate': {'candidate': 'c'},
            })
            as ConferenceVideoIceTrickleEvent;

    expect(decoded.pc, isNull);
  });

  group('$ConferenceVideoInviteEvent and $ConferenceVideoTerminatedEvent', () {
    test('the invitation names the room, the own line and the host', () {
      final decoded = decode('{"event": "conference_video_invite", "room": 4242, "line": 0, "host": "Alice"}');

      expect(decoded, equals(const ConferenceVideoInviteEvent(room: 4242, line: 0, host: 'Alice')));
      expect(Event.fromJson(decoded.toJson()), equals(decoded));
    });

    test('a host without a display name is left out by Core', () {
      expect(
        Event.fromJson({'event': 'conference_video_invite', 'room': 4242, 'line': 1}),
        equals(const ConferenceVideoInviteEvent(room: 4242, line: 1)),
      );
    });

    test('the end of the invitation', () {
      final decoded = Event.fromJson({'event': 'conference_video_terminated', 'room': 4242});

      expect(decoded, equals(const ConferenceVideoTerminatedEvent(room: 4242)));
      expect(Event.fromJson(decoded.toJson()), equals(decoded));
    });
  });
}
