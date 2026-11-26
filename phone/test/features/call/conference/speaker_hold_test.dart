import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// Who the room shows as speaking, held against flicker: a change shows at once after a quiet
/// second, else at the end of the second, and only if the room still says so then.
void main() {
  const hold = Duration(seconds: 1);

  SpeakerHold holdIn(FakeAsync async, List<int?> shown) {
    final start = DateTime(2026);
    return SpeakerHold(onChanged: shown.add, hold: hold, now: () => start.add(async.elapsed));
  }

  test('the first speaker shows at once, and the same one again changes nothing', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);

      speaker.heard(3);
      speaker.heard(3);

      expect(shown, [3]);
      expect(speaker.shown, 3);
    });
  });

  test('a change after the hold shows at once', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);
      speaker.heard(3);

      async.elapse(hold);
      speaker.heard(4);

      expect(shown, [3, 4]);
    });
  });

  test('a change within the hold waits for its end', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);
      speaker.heard(3);

      async.elapse(const Duration(milliseconds: 300));
      speaker.heard(4);
      expect(shown, [3], reason: 'the speaker shown keeps the highlight for the hold');

      async.elapse(const Duration(milliseconds: 699));
      expect(shown, [3]);
      async.elapse(const Duration(milliseconds: 1));
      expect(shown, [3, 4]);
    });
  });

  test('two people cutting into each other do not make it blink', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);
      speaker.heard(3);

      for (var i = 0; i < 4; i++) {
        async.elapse(const Duration(milliseconds: 100));
        speaker.heard(4);
        async.elapse(const Duration(milliseconds: 100));
        speaker.heard(3);
      }
      async.elapse(const Duration(seconds: 5));

      expect(shown, [3], reason: 'back to the one shown before the hold ended: the change is void');
    });
  });

  test('of several changes within the hold, the last one shows', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);
      speaker.heard(3);

      speaker.heard(4);
      speaker.heard(5);
      async.elapse(hold);

      expect(shown, [3, 5]);
    });
  });

  test('nobody speaking shows at once and voids a change waiting', () {
    fakeAsync((async) {
      final shown = <int?>[];
      final speaker = holdIn(async, shown);
      speaker.heard(3);
      speaker.heard(4);

      speaker.clear();
      async.elapse(hold);

      expect(shown, [3, null]);
      expect(speaker.shown, isNull);

      speaker.heard(4);
      expect(shown, [3, null, 4], reason: 'a new room starts without a hold');
    });
  });
}
