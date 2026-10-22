import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// The conference codecs on their own: the offers and answers of calls in the
/// room, and the move of a call on another codec onto them - which calls are
/// awaited, which have the move's offer out, which were tried, which are off
/// hold on the far end, the requests waiting, and when the move is overdue.
void main() {
  const timeout = Duration(seconds: 20);
  const offer =
      'v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n'
      'm=audio 9 UDP/TLS/RTP/SAVPF 111 9 0 126\r\nc=IN IP4 0.0.0.0\r\n'
      'a=rtpmap:111 opus/48000/2\r\na=rtpmap:9 G722/8000\r\na=rtpmap:0 PCMU/8000\r\n'
      'a=rtpmap:126 telephone-event/8000\r\n';

  late RoomCodecs codecs;
  late List<RoomCodecsCommand> commands;
  late List<String> asked;
  void Function() request(String name) =>
      () => asked.add(name);

  /// Carries the commands out the way the owner does: a request asked again.
  void onCommand(RoomCodecsCommand command) {
    commands.add(command);
    if (command is AskAgain) command.request();
  }

  List<String> renegotiated() => [
    for (final c in commands)
      if (c is RenegotiateForRoom) c.callId,
  ];
  List<String> heldAgain() => [
    for (final c in commands)
      if (c is HoldAgain) c.callId,
  ];

  /// Starts moving [calls] - all on G.722 - for the request 'merge', with
  /// each offer out.
  void move(Map<String, bool> calls) {
    expect(
      codecs.check({for (final e in calls.entries) e.key: (codec: 'g722', held: e.value)}, request: request('merge')),
      RoomCodecsCheck.moving,
    );
    calls.keys.forEach(codecs.offerSent);
  }

  setUp(() {
    commands = [];
    asked = [];
    codecs = RoomCodecs(onCommand: onCommand, timeout: timeout);
  });
  tearDown(() => codecs.dispose());

  group('restrict', () {
    test('leaves only the conference codecs to a call in the room', () {
      final sdp = codecs.restrict('a', offer, inRoom: true)!;
      expect(sdp, contains('m=audio 9 UDP/TLS/RTP/SAVPF 111 0 126'));
    });

    test('leaves a call outside the room alone, unless it is being moved', () {
      expect(codecs.restrict('a', offer, inRoom: false), isNull);
      move({'a': false});
      expect(codecs.restrict('a', offer, inRoom: false), isNotNull);
    });
  });

  test('codecOf reads the voice codec an answer settled on', () {
    expect(RoomCodecs.codecOf('v=0\r\nm=audio 9 RTP/AVP 9 126\r\na=rtpmap:126 telephone-event/8000\r\n'), 'g722');
  });

  group('check', () {
    test('lets calls on the conference codecs, or on unknown ones, go ahead', () {
      final check = codecs.check({
        'a': (codec: 'pcmu', held: false),
        'b': (codec: 'opus', held: false),
        'c': (codec: null, held: false),
      }, request: request('merge'));

      expect(check, RoomCodecsCheck.ready);
      expect(commands, isEmpty);
    });

    test('moves the calls off them and asks the request again once every answer is applied', () {
      move({'a': false, 'b': false});
      expect(renegotiated(), ['a', 'b']);

      codecs.answerApplied('a');
      expect(asked, isEmpty);
      codecs.answerApplied('b');

      expect(asked, ['merge']);
      expect(codecs.isMoving, isFalse);
    });

    test('a call still off them after its move fails the request; settled, it may be moved again', () {
      move({'a': false});
      codecs.answerApplied('a');

      expect(codecs.check({'a': (codec: 'g722', held: false)}, request: request('merge')), RoomCodecsCheck.off);
      codecs.settled(['a'], roomTook: false);
      expect(codecs.check({'a': (codec: 'g722', held: false)}, request: request('merge')), RoomCodecsCheck.moving);
    });

    test('a request asked while a move is on waits, and is asked after the one that started it', () {
      move({'a': false});

      expect(codecs.check({'b': (codec: 'pcmu', held: false)}, request: request('join')), RoomCodecsCheck.moving);
      codecs.answerApplied('a');

      expect(asked, ['merge', 'join']);
    });
  });

  group('answers', () {
    test('an answer to an offer that is not the move\'s does not count', () {
      expect(codecs.check({'a': (codec: 'g722', held: false)}, request: request('merge')), RoomCodecsCheck.moving);

      codecs.answerApplied('a');

      expect(codecs.isMoving, isTrue, reason: 'the move\'s offer was never sent');
    });

    test('updated counts only once the connection is stable', () {
      move({'a': false});

      codecs.updated('a', stable: false);
      expect(asked, isEmpty);
      codecs.updated('a', stable: true);
      expect(asked, ['merge']);
    });

    test('a kept offer is withdrawn for the move\'s own, but not the move\'s own', () {
      expect(codecs.check({'a': (codec: 'g722', held: false)}, request: request('merge')), RoomCodecsCheck.moving);
      expect(codecs.withdrawsKeptOffer('a'), isTrue);
      codecs.offerSent('a');
      expect(codecs.withdrawsKeptOffer('a'), isFalse);
      expect(codecs.withdrawsKeptOffer('b'), isFalse);
    });
  });

  group('errors', () {
    for (final code in RoomCodecs.refusals) {
      test('$code rolls the move\'s offer back and gives the move up', () {
        move({'a': false, 'b': false});

        expect(codecs.offerFailed('a', code), RoomOfferError.rollBack);
        expect(asked, ['merge']);
        expect(codecs.isMoving, isFalse);
      });
    }

    test('another error while the move is on is retried as usual', () {
      move({'a': false});

      expect(codecs.offerFailed('a', 491), RoomOfferError.asUsual);
      expect(codecs.offerFailed('a', 500), RoomOfferError.asUsual);
      expect(codecs.isMoving, isTrue);
    });

    test('any error on a move\'s offer after the move is over rolls it back', () {
      move({'a': false, 'b': false});
      codecs.offerFailed('a', 488);

      expect(codecs.offerFailed('b', 500), RoomOfferError.rollBack);
    });

    test('an error on an offer that is not a move\'s is not touched', () {
      expect(codecs.offerFailed('a', 488), RoomOfferError.asUsual);
    });
  });

  group('the hold', () {
    test('a held call whose offer was answered is held again when no room takes it', () {
      move({'a': true, 'b': false});
      codecs.answerApplied('a');
      codecs.answerApplied('b');

      codecs.settled(['a', 'b'], roomTook: false);

      expect(heldAgain(), ['a']);
    });

    test('a held call the room took, or whose offer was refused, is not held again', () {
      move({'a': true});
      codecs.answerApplied('a');
      codecs.settled(['a'], roomTook: true);

      move({'b': true});
      codecs.offerFailed('b', 488);
      codecs.settled(['b'], roomTook: false);

      expect(heldAgain(), isEmpty);
    });
  });

  test('the last awaited call gone ends the move; another gone leaves it on', () {
    move({'a': false, 'b': false});

    codecs.callRemoved('c');
    codecs.callRemoved('a');
    expect(asked, isEmpty);
    codecs.callRemoved('b');

    expect(asked, ['merge']);
  });

  test('answers that do not come give the move up once, after the timeout', () {
    fakeAsync((async) {
      final codecs = RoomCodecs(onCommand: onCommand, timeout: timeout);
      codecs.check({'a': (codec: 'g722', held: false)}, request: request('merge'));

      async.elapse(timeout - const Duration(milliseconds: 1));
      expect(asked, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(asked, ['merge']);
      async.elapse(timeout * 2);
      expect(asked, ['merge']);
      codecs.dispose();
    });
  });
}
