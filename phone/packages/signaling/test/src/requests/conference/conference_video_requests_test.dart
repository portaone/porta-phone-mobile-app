import 'package:test/test.dart';

import 'package:signaling/signaling.dart';

void main() {
  const offer = {'type': 'offer', 'sdp': 'v=0'};
  const answer = {'type': 'answer', 'sdp': 'v=0'};

  group('requests without fields', () {
    final cases = <String, SessionRequest>{
      'conference_video_subscribe': const ConferenceVideoSubscribeRequest(transaction: 'v1'),
      'conference_video_unpublish': const ConferenceVideoUnpublishRequest(transaction: 'v1'),
      'conference_video_restart': const ConferenceVideoRestartRequest(transaction: 'v1'),
      'conference_video_leave': const ConferenceVideoLeaveRequest(transaction: 'v1'),
    };

    cases.forEach((type, request) {
      test('$type carries only its type and transaction, and is decoded back', () {
        expect(request.toJson(), {Request.typeKey: type, 'transaction': 'v1'});
        expect(Request.fromJson(request.toJson()), equals(request));
      });
    });
  });

  group('$ConferenceVideoAnswerRequest', () {
    test('toJson and round trip', () {
      const request = ConferenceVideoAnswerRequest(transaction: 'v2', jsep: answer);

      expect(request.toJson(), {Request.typeKey: 'conference_video_answer', 'transaction': 'v2', 'jsep': answer});
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceVideoPublishRequest', () {
    test('names each m-line, as in the guide', () {
      const request = ConferenceVideoPublishRequest(
        transaction: 'v3',
        jsep: offer,
        descriptions: [
          ConferenceVideoDescription(mid: '0', kind: ConferenceVideoKind.camera),
          ConferenceVideoDescription(mid: '1', kind: ConferenceVideoKind.screen),
        ],
      );

      expect(request.toJson(), {
        Request.typeKey: 'conference_video_publish',
        'transaction': 'v3',
        'jsep': offer,
        'descriptions': [
          {'mid': '0', 'kind': 'camera'},
          {'mid': '1', 'kind': 'screen'},
        ],
      });
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });

    test('without descriptions the field is left out, which Core reads as cameras', () {
      const request = ConferenceVideoPublishRequest(transaction: 'v3', jsep: offer);

      expect(request.toJson().containsKey('descriptions'), isFalse);
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });

    test('a kind other than camera or screen is refused, as Core refuses it with invalid_descriptions', () {
      expect(
        () => ConferenceVideoPublishRequest.fromJson({
          Request.typeKey: 'conference_video_publish',
          'transaction': 'v3',
          'jsep': offer,
          'descriptions': [
            {'mid': '0', 'kind': 'window'},
          ],
        }),
        throwsArgumentError,
      );
    });
  });

  test('a description of an unknown kind is refused before the request is sent', () {
    const request = ConferenceVideoPublishRequest(
      transaction: 'v3',
      jsep: offer,
      descriptions: [ConferenceVideoDescription(mid: '0', kind: ConferenceVideoKind.unknown)],
    );

    expect(request.toJson, throwsArgumentError);
  });

  group('$ConferenceVideoIceTrickleRequest', () {
    test('tags the candidate with its PeerConnection', () {
      const request = ConferenceVideoIceTrickleRequest(
        transaction: 'v5',
        pc: ConferenceVideoPc.publisher,
        candidate: {'candidate': 'candidate:1', 'sdpMid': '0', 'sdpMLineIndex': 0},
      );

      expect(request.toJson(), {
        Request.typeKey: 'conference_video_ice_trickle',
        'transaction': 'v5',
        'pc': 'publisher',
        'candidate': {'candidate': 'candidate:1', 'sdpMid': '0', 'sdpMLineIndex': 0},
      });
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });

    test('the end of gathering is sent as the completed marker', () {
      const request = ConferenceVideoIceTrickleRequest(transaction: 'v6', pc: ConferenceVideoPc.subscriber);

      expect(request.toJson()['candidate'], {'completed': true});
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });

    test('an unknown pc is refused', () {
      expect(
        () => ConferenceVideoIceTrickleRequest.fromJson({
          Request.typeKey: 'conference_video_ice_trickle',
          'transaction': 'v6',
          'pc': 'mixer',
        }),
        throwsArgumentError,
      );
    });
  });
}
