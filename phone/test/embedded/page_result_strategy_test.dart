import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/webview/web_view_container.dart';

class MockWebViewController extends Mock implements WebViewController {}

const _refused = PageResult(channel: 'SomeChannel', event: 'request', ok: false, reason: 'refused');

final _address = Uri.parse('https://example.com/login');

// The page put itself into a waiting state when it posted a request; these pin down how it is
// brought back for each strategy, and that it is brought back once and only while it is in front
// of the user.
void main() {
  late MockWebViewController controller;
  late List<String> calls;

  setUpAll(() => registerFallbackValue(Uri()));

  MockWebViewController page({bool history = false, bool takesResults = false}) {
    controller = MockWebViewController();
    calls = [];
    rememberOpenedAddressForTesting(controller, _address);
    when(() => controller.canGoBack()).thenAnswer((_) async => history);
    when(() => controller.goBack()).thenAnswer((_) async => calls.add('goBack'));
    when(() => controller.reload()).thenAnswer((_) async => calls.add('reload'));
    when(() => controller.loadRequest(any())).thenAnswer((i) async => calls.add('load ${i.positionalArguments.first}'));
    when(() => controller.runJavaScriptReturningResult(any())).thenAnswer((_) async => takesResults);
    when(() => controller.runJavaScript(any())).thenAnswer((i) async => calls.add('js ${i.positionalArguments.first}'));
    return controller;
  }

  PageResultStrategy attached(ResultStrategy type, MockWebViewController controller) =>
      PageResultStrategy.create(type)..attachForTesting(controller);

  Future<List<String>> answered(ResultStrategy type, MockWebViewController controller) async {
    await attached(type, controller).onResult(_refused, covered: false);
    return calls;
  }

  test('each strategy is created for its configured value', () {
    for (final type in ResultStrategy.values) {
      expect(PageResultStrategy.create(type).strategy, type);
    }
  });

  group('a page whose request ended without success', () {
    test('goes back in its history by default', () async {
      expect(await answered(ResultStrategy.historyBack, page(history: true)), ['goBack']);
    });

    test('is reloaded by default when it has no history to go back in', () async {
      expect(await answered(ResultStrategy.historyBack, page()), ['reload']);
    });

    test('is told the result when it takes one', () async {
      expect(await answered(ResultStrategy.notify, page(history: true, takesResults: true)), [
        'js window.onWebTritResult({"channel":"SomeChannel","event":"request","ok":false,"reason":"refused"})',
      ]);
    });

    test('that does not take a result goes back in its history instead', () async {
      expect(await answered(ResultStrategy.notify, page(history: true)), ['goBack']);
    });

    test('that cannot be asked whether it takes a result goes back in its history instead', () async {
      final controller = page(history: true);
      when(() => controller.runJavaScriptReturningResult(any())).thenThrow(UnsupportedError('browser'));

      expect(await answered(ResultStrategy.notify, controller), ['goBack']);
    });

    test('is opened again from its address when restarted', () async {
      expect(await answered(ResultStrategy.restart, page(history: true)), ['load $_address']);
    });

    test('is reloaded when that is its strategy', () async {
      expect(await answered(ResultStrategy.reload, page(history: true)), ['reload']);
    });

    test('is left alone when that is its strategy', () async {
      expect(await answered(ResultStrategy.none, page(history: true)), isEmpty);
    });
  });

  group('a page covered by a screen of the app when its request ended', () {
    test('is not answered while the screen is over it', () async {
      await attached(ResultStrategy.historyBack, page(history: true)).onResult(_refused, covered: true);

      expect(calls, isEmpty);
    });

    test('is answered once the screen is gone', () async {
      final strategy = attached(ResultStrategy.historyBack, page(history: true));

      await strategy.onResult(_refused, covered: true);
      await strategy.onUncovered();

      expect(calls, ['goBack']);
    });

    test('is answered once, however often the screen goes', () async {
      final strategy = attached(ResultStrategy.historyBack, page(history: true));

      await strategy.onResult(_refused, covered: true);
      await strategy.onUncovered();
      await strategy.onUncovered();

      expect(calls, ['goBack']);
    });

    test('is not answered when a new request took the place of that result', () async {
      final strategy = attached(ResultStrategy.historyBack, page(history: true));

      await strategy.onResult(_refused, covered: true);
      strategy.cancelHeld();
      await strategy.onUncovered();

      expect(calls, isEmpty);
    });
  });

  test('a screen going away with nothing held does nothing to the page', () async {
    await attached(ResultStrategy.historyBack, page(history: true)).onUncovered();

    expect(calls, isEmpty);
  });

  test('a strategy not attached to a page does nothing', () async {
    page(history: true);

    await PageResultStrategy.create(ResultStrategy.historyBack).onResult(_refused, covered: false);

    expect(calls, isEmpty);
  });
}
