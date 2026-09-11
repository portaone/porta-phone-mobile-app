import 'package:test/test.dart';

import 'package:signaling/src/requests/conference/conference_requests.dart';
import 'package:signaling/src/requests/request.dart';
import 'package:signaling/src/requests/session_request.dart';

void main() {
  group('$MergeRequest', () {
    const request = MergeRequest(transaction: 't1', lines: [0, 1]);

    test('toJson', () {
      expect(request.toJson(), {
        Request.typeKey: 'merge',
        'transaction': 't1',
        'lines': [0, 1],
      });
    });

    test('round trip via SessionRequest', () {
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceAddRequest', () {
    const request = ConferenceAddRequest(transaction: 't2', line: 2);

    test('toJson keeps line as a parameter, not an address', () {
      expect(request.toJson(), {Request.typeKey: 'conference_add', 'transaction': 't2', 'line': 2});
    });

    test('round trip via SessionRequest', () {
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceAnswerRequest', () {
    const request = ConferenceAnswerRequest(transaction: 't3', jsep: {'type': 'answer', 'sdp': 'v=0'});

    test('toJson', () {
      expect(request.toJson(), {
        Request.typeKey: 'conference_answer',
        'transaction': 't3',
        'jsep': {'type': 'answer', 'sdp': 'v=0'},
      });
    });

    test('round trip via SessionRequest', () {
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceIceTrickleRequest', () {
    test('toJson with a candidate', () {
      const request = ConferenceIceTrickleRequest(transaction: 't4', candidate: {'candidate': 'a=1', 'sdpMid': '0'});

      expect(request.toJson(), {
        Request.typeKey: 'conference_ice_trickle',
        'transaction': 't4',
        'candidate': {'candidate': 'a=1', 'sdpMid': '0'},
      });
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });

    test('null candidate is sent as the completed marker, like the line path', () {
      const request = ConferenceIceTrickleRequest(transaction: 't5');

      expect(request.toJson(), {
        Request.typeKey: 'conference_ice_trickle',
        'transaction': 't5',
        'candidate': {'completed': true},
      });
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceMuteRequest', () {
    test('toJson carries muted explicitly, both ways', () {
      const mute = ConferenceMuteRequest(transaction: 't6', line: 1, muted: true);
      const unmute = ConferenceMuteRequest(transaction: 't7', line: 1, muted: false);

      expect(mute.toJson(), {Request.typeKey: 'conference_mute', 'transaction': 't6', 'line': 1, 'muted': true});
      expect(unmute.toJson()['muted'], isFalse);
      expect(SessionRequest.fromJson(unmute.toJson()), equals(unmute));
    });
  });

  group('$ConferenceRemoveRequest', () {
    const request = ConferenceRemoveRequest(transaction: 't8', line: 0);

    test('toJson and round trip', () {
      expect(request.toJson(), {Request.typeKey: 'conference_remove', 'transaction': 't8', 'line': 0});
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  group('$ConferenceHangupRequest', () {
    const request = ConferenceHangupRequest(transaction: 't9');

    test('toJson has no line and no call_id', () {
      expect(request.toJson(), {Request.typeKey: 'conference_hangup', 'transaction': 't9'});
      expect(SessionRequest.fromJson(request.toJson()), equals(request));
    });
  });

  test('a conference request with the wrong type is refused by its own fromJson', () {
    expect(
      () => MergeRequest.fromJson({Request.typeKey: 'conference_add', 'transaction': 't', 'line': 0}),
      throwsArgumentError,
    );
  });
}
