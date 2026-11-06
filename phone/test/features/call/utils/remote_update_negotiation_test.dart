import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/utils/remote_update_negotiation.dart';

const _callId = 'call-abc';

UpdatingCallEvent _update([String callId = _callId]) =>
    UpdatingCallEvent(line: 0, callId: callId, caller: '1', callee: '2');

void main() {
  late RemoteUpdateNegotiation negotiation;

  setUp(() => negotiation = RemoteUpdateNegotiation());

  group('numbering', () {
    test('a call\'s updates are numbered from one, on top of what a handshake counted', () {
      expect(negotiation.heardLive(_update())!.ordinal, 1);
      expect(negotiation.heardLive(_update())!.ordinal, 2);

      negotiation.handshakeShows({_callId: 5});
      expect(negotiation.heardLive(_update())!.ordinal, 6);

      expect(negotiation.heardLive(_update('another call'))!.ordinal, 1);
    });

    test('a handshake that counts the same updates names them by the same numbers', () {
      final answered = negotiation.heardLive(_update())!;
      negotiation.ended(answered, CallUpdateAnswer.acknowledged);

      // The socket reconnects; the new handshake's log shows that one update.
      negotiation.handshakeShows({_callId: 1});

      expect(negotiation.foundUnanswered(_update(), 1), isNull);
      expect(negotiation.heardLive(_update())!.ordinal, 2);
    });

    test('a handshake that shows fewer updates than were counted does not number a new one as an old one', () {
      for (var i = 0; i < 3; i++) {
        negotiation.ended(negotiation.heardLive(_update())!, CallUpdateAnswer.acknowledged);
      }

      // A log entry the client could not parse: the handshake counts two.
      negotiation.handshakeShows({_callId: 2});

      final next = negotiation.heardLive(_update());
      expect(next, isNotNull, reason: 'the next live update is a new one and must be answered');
      expect(next!.ordinal, 4);
    });

    test('a handshake forgets the calls it no longer shows', () {
      negotiation.ended(negotiation.heardLive(_update())!, CallUpdateAnswer.acknowledged);
      negotiation.heardLive(_update('b'));

      negotiation.handshakeShows({'b': 1});

      expect(negotiation.heardLive(_update())!.ordinal, 1, reason: 'the call the server no longer has is gone');
      expect(negotiation.heardLive(_update('b'))!.ordinal, 2);
    });

    test('a call that is over is forgotten with its count', () {
      negotiation.ended(negotiation.heardLive(_update())!, CallUpdateAnswer.acknowledged);

      negotiation.forget(_callId);

      final again = negotiation.heardLive(_update())!;
      expect(again.ordinal, 1);
    });
  });

  group('an update is answered once', () {
    test('one being answered is not handed over again', () {
      expect(negotiation.foundUnanswered(_update(), 1), isNotNull);
      expect(negotiation.foundUnanswered(_update(), 1), isNull);
    });

    test('one answered is not handed over again', () {
      negotiation.ended(negotiation.foundUnanswered(_update(), 1)!, CallUpdateAnswer.acknowledged);

      expect(negotiation.foundUnanswered(_update(), 1), isNull);
    });

    test('one whose attempt ended without an answer is free again', () {
      negotiation.ended(negotiation.foundUnanswered(_update(), 1)!, CallUpdateAnswer.notSent);

      expect(negotiation.foundUnanswered(_update(), 1), isNotNull);
    });

    test('an attempt ends the update it was opened for, whatever else is open', () {
      final first = negotiation.foundUnanswered(_update(), 1)!;
      final second = negotiation.foundUnanswered(_update(), 2)!;

      negotiation.ended(second, CallUpdateAnswer.notSent);

      expect(negotiation.foundUnanswered(_update(), 1), isNull, reason: 'the first is still being answered');
      expect(negotiation.foundUnanswered(_update(), 2), isNotNull, reason: 'the second is free again');

      negotiation.ended(first, CallUpdateAnswer.acknowledged);
      expect(negotiation.foundUnanswered(_update(), 1), isNull, reason: 'answered');
    });

    test('ending an attempt twice changes nothing the second time', () {
      final attempt = negotiation.foundUnanswered(_update(), 1)!;
      negotiation.ended(attempt, CallUpdateAnswer.notSent);

      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged), isEmpty);
      expect(negotiation.foundUnanswered(_update(), 1), isNotNull, reason: 'the first ending stands');
    });

    test('an attempt that outlives its call leaves nothing behind when it ends', () {
      final attempt = negotiation.foundUnanswered(_update(), 1)!;
      negotiation.forget(_callId);

      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged), isEmpty);
      expect(negotiation.foundUnanswered(_update(), 1), isNotNull, reason: 'a new call with the same id starts clean');
    });
  });

  group('an update a handshake shows unanswered while its answer still waits', () {
    test('is handed back when that answer is not taken', () {
      final attempt = negotiation.heardLive(_update())!;
      final fromLog = _update();
      expect(negotiation.foundUnanswered(fromLog, 1), isNull);

      final steps = negotiation.ended(attempt, CallUpdateAnswer.notSent);

      final again = steps.single as AnswerUpdate;
      expect(again.update, same(fromLog));
      expect(again.attempt.ordinal, 1);
      expect(negotiation.foundUnanswered(_update(), 1), isNull, reason: 'handed back means being answered again');
    });

    test('is handed back after a refused answer too', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.foundUnanswered(_update(), 1);

      expect(negotiation.ended(attempt, CallUpdateAnswer.refused).single, isA<AnswerUpdate>());
    });

    test('is not handed back once that answer was taken', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.foundUnanswered(_update(), 1);

      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged), isEmpty);
      expect(negotiation.foundUnanswered(_update(), 1), isNull);
    });

    test('is handed back once, not by a later attempt nobody asked again', () {
      final first = negotiation.heardLive(_update())!;
      negotiation.foundUnanswered(_update(), 1);
      final second = (negotiation.ended(first, CallUpdateAnswer.notSent).single as AnswerUpdate).attempt;

      expect(negotiation.ended(second, CallUpdateAnswer.notSent), isEmpty);
    });
  });

  group('our own offer behind an open update', () {
    test('goes at once while the call has no open update', () {
      expect(negotiation.putOffOffer(_callId, 1), isFalse);

      negotiation.ended(negotiation.heardLive(_update())!, CallUpdateAnswer.acknowledged);
      expect(negotiation.putOffOffer(_callId, 1), isFalse, reason: 'an answered update holds nothing back');
    });

    test('is put off and made once the update is answered', () {
      final attempt = negotiation.heardLive(_update())!;
      expect(negotiation.putOffOffer(_callId, 3), isTrue);

      final offer = negotiation.ended(attempt, CallUpdateAnswer.acknowledged).single as OfferOwn;

      expect(offer.callId, _callId);
      expect(offer.lineId, 3);
      expect(negotiation.putOffOffer(_callId, 3), isFalse);
    });

    test('is made once the update is left unanswered too', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.putOffOffer(_callId, 1);

      expect(negotiation.ended(attempt, CallUpdateAnswer.notSent).single, isA<OfferOwn>());
    });

    test('is dropped when the server refused the answer: its retry renegotiates the call', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.putOffOffer(_callId, 1);

      expect(negotiation.ended(attempt, CallUpdateAnswer.refused), isEmpty);
      expect(negotiation.putOffOffer(_callId, 1), isFalse);
    });

    test('waits for every open update of its call, and only of its call', () {
      final first = negotiation.heardLive(_update())!;
      final second = negotiation.heardLive(_update())!;
      final other = negotiation.heardLive(_update('b'))!;
      negotiation.putOffOffer(_callId, 1);

      expect(negotiation.ended(other, CallUpdateAnswer.acknowledged), isEmpty);
      expect(negotiation.ended(first, CallUpdateAnswer.acknowledged), isEmpty);
      expect(negotiation.ended(second, CallUpdateAnswer.acknowledged).single, isA<OfferOwn>());
    });

    test('keeps waiting while the update is handed back to be answered again', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.foundUnanswered(_update(), 1);
      negotiation.putOffOffer(_callId, 1);

      final again = (negotiation.ended(attempt, CallUpdateAnswer.notSent).single as AnswerUpdate).attempt;
      expect(negotiation.ended(again, CallUpdateAnswer.acknowledged).single, isA<OfferOwn>());
    });

    test('waits on when the answer is lost with its session: the next handshake shows the update again', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.putOffOffer(_callId, 1);

      expect(negotiation.ended(attempt, CallUpdateAnswer.lost), isEmpty);
      expect(negotiation.foundUnanswered(_update(), 1), isNotNull, reason: 'the update is free to be answered again');
    });

    test('a put-off offer left behind by a lost answer is not made again once an offer went', () {
      negotiation.ended(negotiation.heardLive(_update())!, CallUpdateAnswer.lost);
      negotiation.putOffOffer(_callId, 1);
      // The handshake did not show the update: the reconnect's own offer goes at once.
      expect(negotiation.putOffOffer(_callId, 1), isFalse);

      final next = negotiation.heardLive(_update())!;
      expect(negotiation.ended(next, CallUpdateAnswer.acknowledged), isEmpty, reason: 'nothing was left put off');
    });

    test('is dropped with its call', () {
      final attempt = negotiation.heardLive(_update())!;
      negotiation.putOffOffer(_callId, 1);
      negotiation.forget(_callId);

      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged), isEmpty);
    });
  });

  group('a call restored with an update it missed', () {
    test('answers it, and the answer negotiates the call: no offer of its own follows', () {
      final attempt = negotiation.restoredWith(_update(), 2, 4)!;

      expect(attempt.ordinal, 2);
      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged), isEmpty);
    });

    test('makes its own offer if the update ends unanswered', () {
      final attempt = negotiation.restoredWith(_update(), 1, 4)!;

      final offer = negotiation.ended(attempt, CallUpdateAnswer.notSent).single as OfferOwn;
      expect(offer.lineId, 4);
    });

    test('an offer asked for outright meanwhile is made even after the answer', () {
      final attempt = negotiation.restoredWith(_update(), 1, 4)!;
      negotiation.putOffOffer(_callId, 4);

      expect(negotiation.ended(attempt, CallUpdateAnswer.acknowledged).single, isA<OfferOwn>());
    });

    test('with the update handled already, it opens nothing', () {
      negotiation.heardLive(_update());

      expect(negotiation.restoredWith(_update(), 1, 4), isNull);
    });
  });
}
