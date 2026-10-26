import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class _Page implements ResultPage {
  _Page({this.history = false, this.takesResult = false});

  final bool history;
  final bool takesResult;
  final calls = <String>[];

  @override
  Future<bool> canGoBack() async => history;

  @override
  Future<void> goBack() async => calls.add('goBack');

  @override
  Future<void> reload() async => calls.add('reload');

  @override
  Future<void> restart() async => calls.add('restart');

  @override
  Future<bool> takesResults() async => takesResult;

  @override
  Future<void> sendResult(PageResult result) async => calls.add('result $result');
}

const _refused = PageResult(channel: 'SomeChannel', event: 'request', ok: false, reason: 'refused');

// The page put itself into a waiting state when it posted a request; these pin down how it is
// brought back for each strategy, and that it is brought back once and only while it is in front
// of the user.
void main() {
  Future<List<String>> answered(ResultStrategy strategy, _Page page) async {
    await PageResultAnswer(strategy: strategy, page: page).ended(_refused, covered: false);
    return page.calls;
  }

  group('a page whose request ended without success', () {
    test('goes back in its history by default', () async {
      expect(await answered(ResultStrategy.historyBack, _Page(history: true)), ['goBack']);
    });

    test('is reloaded by default when it has no history to go back in', () async {
      expect(await answered(ResultStrategy.historyBack, _Page()), ['reload']);
    });

    test('is told the result when it takes one', () async {
      expect(await answered(ResultStrategy.notify, _Page(history: true, takesResult: true)), ['result $_refused']);
    });

    test('that does not take a result goes back in its history instead', () async {
      expect(await answered(ResultStrategy.notify, _Page(history: true)), ['goBack']);
    });

    test('is opened again from its address when restarted', () async {
      expect(await answered(ResultStrategy.restart, _Page(history: true)), ['restart']);
    });

    test('is reloaded when that is its strategy', () async {
      expect(await answered(ResultStrategy.reload, _Page(history: true)), ['reload']);
    });

    test('is left alone when that is its strategy', () async {
      expect(await answered(ResultStrategy.none, _Page(history: true)), isEmpty);
    });
  });

  group('a page covered by a screen of the app when its request ended', () {
    test('is not answered while the screen is over it', () async {
      final page = _Page(history: true);
      await PageResultAnswer(strategy: ResultStrategy.historyBack, page: page).ended(_refused, covered: true);

      expect(page.calls, isEmpty);
    });

    test('is answered once the screen is gone', () async {
      final page = _Page(history: true);
      final answer = PageResultAnswer(strategy: ResultStrategy.historyBack, page: page);

      await answer.ended(_refused, covered: true);
      await answer.uncovered();

      expect(page.calls, ['goBack']);
    });

    test('is answered once, however often the screen goes', () async {
      final page = _Page(history: true);
      final answer = PageResultAnswer(strategy: ResultStrategy.historyBack, page: page);

      await answer.ended(_refused, covered: true);
      await answer.uncovered();
      await answer.uncovered();

      expect(page.calls, ['goBack']);
    });

    test('is not answered when a new request took the place of that result', () async {
      final page = _Page(history: true);
      final answer = PageResultAnswer(strategy: ResultStrategy.historyBack, page: page);

      await answer.ended(_refused, covered: true);
      answer.drop();
      await answer.uncovered();

      expect(page.calls, isEmpty);
    });
  });

  group('a page that posts the same request again as soon as it is brought back', () {
    late DateTime now;
    final ticking = Clock(() => now);

    setUp(() => now = DateTime(2026, 10, 25, 12));

    test('is not moved again for the result that follows at once', () {
      return withClock(ticking, () async {
        final page = _Page();
        final answer = PageResultAnswer(strategy: ResultStrategy.historyBack, page: page);

        await answer.ended(_refused, covered: false);
        now = now.add(const Duration(seconds: 2));
        await answer.ended(_refused, covered: false);

        expect(page.calls, ['reload']);
      });
    });

    test('is moved again for a result that comes after the window', () {
      return withClock(ticking, () async {
        final page = _Page(history: true);
        final answer = PageResultAnswer(strategy: ResultStrategy.historyBack, page: page);

        await answer.ended(_refused, covered: false);
        now = now.add(PageResultAnswer.repostWindow);
        await answer.ended(_refused, covered: false);

        expect(page.calls, ['goBack', 'goBack']);
      });
    });

    test('is moved again for the next result once one was left unanswered', () {
      return withClock(ticking, () async {
        final page = _Page();
        final answer = PageResultAnswer(strategy: ResultStrategy.reload, page: page);

        await answer.ended(_refused, covered: false);
        now = now.add(const Duration(seconds: 1));
        await answer.ended(_refused, covered: false);
        now = now.add(const Duration(seconds: 1));
        await answer.ended(_refused, covered: false);

        expect(page.calls, ['reload', 'reload']);
      });
    });

    test('is told every result: telling does not move it', () {
      return withClock(ticking, () async {
        final page = _Page(takesResult: true);
        final answer = PageResultAnswer(strategy: ResultStrategy.notify, page: page);

        await answer.ended(_refused, covered: false);
        await answer.ended(_refused, covered: false);

        expect(page.calls, hasLength(2));
      });
    });
  });

  test('a screen going away with nothing held does nothing to the page', () async {
    final page = _Page(history: true);

    await PageResultAnswer(strategy: ResultStrategy.historyBack, page: page).uncovered();

    expect(page.calls, isEmpty);
  });
}
