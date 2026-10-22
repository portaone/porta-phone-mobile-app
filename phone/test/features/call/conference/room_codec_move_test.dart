import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// The move of calls onto the conference codecs on its own: which calls are
/// awaited and which have its offer out, which were tried, which are off hold
/// on the far end, the requests waiting, and when the move is overdue.
void main() {
  const timeout = Duration(seconds: 20);

  late RoomCodecMove move;
  late List<String> asked;
  void Function() request(String name) =>
      () => asked.add(name);
  void askAll(List<void Function()> requests) {
    for (final r in requests) {
      r();
    }
  }

  setUp(() {
    move = RoomCodecMove(timeout: timeout);
    asked = [];
  });
  tearDown(() => move.dispose());

  test('the request is asked again once every call has its answer', () {
    move.start({'a': false, 'b': false}, request: request('merge'), onOverdue: () {});
    move.offerSent('a');
    move.offerSent('b');

    askAll(move.answered('a'));
    expect(asked, isEmpty);
    expect(move.isOn, isTrue);

    askAll(move.answered('b'));
    expect(asked, ['merge']);
    expect(move.isOn, isFalse);
    expect(move.hasOfferOut('a'), isFalse);
    expect(move.wasTried('a'), isTrue, reason: 'until the request asked again is done');
  });

  test('a request asked while a move is on waits for it, and is asked after the one that started it', () {
    move.start({'a': false}, request: request('merge'), onOverdue: () {});
    move.wait(request('join'));

    askAll(move.answered('a'));

    expect(asked, ['merge', 'join']);
  });

  test('a move given up hands its requests back; the offer stays known as the move\'s', () {
    move.start({'a': false}, request: request('merge'), onOverdue: () {});
    move.offerSent('a');

    askAll(move.giveUp());

    expect(asked, ['merge']);
    expect(move.isOn, isFalse);
    expect(move.moves('a'), isFalse);
    expect(move.hasOfferOut('a'), isTrue, reason: 'a late refusal must still be told apart');
    move.offerWithdrawn('a');
    expect(move.hasOfferOut('a'), isFalse);
  });

  test('an answer that is not to the move changes nothing', () {
    expect(move.answered('a'), isEmpty);
    move.start({'a': false}, request: request('merge'), onOverdue: () {});

    expect(move.answered('b'), isEmpty);
    expect(move.isOn, isTrue);
  });

  test('a held call whose offer was answered is to be held again when no room takes it', () {
    move.start({'a': true, 'b': false}, request: request('merge'), onOverdue: () {});
    move.answered('a');
    move.answered('b');

    expect(move.settled(['a', 'b'], roomTook: false), ['a']);
    expect(move.wasTried('a'), isFalse);
  });

  test('a held call taken by the room, or never answered, is not held again', () {
    move.start({'a': true}, request: request('merge'), onOverdue: () {});
    move.answered('a');
    expect(move.settled(['a'], roomTook: true), isEmpty);

    move.start({'b': true}, request: request('merge'), onOverdue: () {});
    move.giveUp();
    expect(move.settled(['b'], roomTook: false), isEmpty, reason: 'its offer was never answered');
  });

  test('the last awaited call gone ends the move; another gone leaves it on', () {
    move.start({'a': false, 'b': false}, request: request('merge'), onOverdue: () {});

    askAll(move.callRemoved('c'));
    expect(asked, isEmpty);
    askAll(move.callRemoved('a'));
    expect(asked, isEmpty);
    expect(move.wasTried('a'), isFalse);
    askAll(move.callRemoved('b'));
    expect(asked, ['merge']);
  });

  test('answers that do not come make the move overdue once, after the timeout', () {
    fakeAsync((async) {
      final move = RoomCodecMove(timeout: timeout);
      var overdue = 0;
      move.start({'a': false}, request: () {}, onOverdue: () => overdue++);

      async.elapse(timeout - const Duration(milliseconds: 1));
      expect(overdue, 0);
      async.elapse(const Duration(milliseconds: 1));
      expect(overdue, 1);
      async.elapse(timeout * 2);
      expect(overdue, 1);
    });
  });

  test('a move over in time is not overdue', () {
    fakeAsync((async) {
      final move = RoomCodecMove(timeout: timeout);
      var overdue = 0;
      move.start({'a': false}, request: () {}, onOverdue: () => overdue++);
      move.answered('a');

      async.elapse(timeout * 2);
      expect(overdue, 0);
    });
  });
}
