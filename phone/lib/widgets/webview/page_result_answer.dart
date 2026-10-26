import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';

import 'web_view_container.dart';

final _logger = Logger('PageResultAnswer');

/// What [PageResultAnswer] does to the page; [WebViewResultPage] implements it over a web view.
abstract interface class ResultPage {
  Future<bool> canGoBack();

  Future<void> goBack();

  Future<void> reload();

  /// Opens the page's own address again, with a fresh history.
  Future<void> restart();

  /// Whether the page defines `window.onWebTritResult`.
  Future<bool> takesResults();

  /// Calls `window.onWebTritResult` with [result].
  Future<void> sendResult(PageResult result);
}

/// Brings an embedded page back when a request it posted to the app ends without success.
///
/// The page put itself into a waiting state when it posted and cannot learn the outcome by
/// itself, so the app answers it once, the way its resource's [ResultStrategy] says. A result
/// that comes while a screen of the app covers the page is held until that screen is gone: the
/// page is answered while it is in front of the user, and a page that posts again on its own does
/// not do it behind that screen.
///
/// Which requests end this way, and when a screen covers the page, is up to the screen that
/// shows the page and routes its requests.
class PageResultAnswer {
  PageResultAnswer({required this.strategy, required this.page});

  final ResultStrategy strategy;
  final ResultPage page;

  PageResult? _held;

  /// A request of the page ended with [result]; [covered] is whether a screen of the app is over
  /// the page right now.
  Future<void> ended(PageResult result, {required bool covered}) async {
    if (covered) {
      _held = result;
      return;
    }
    _held = null;
    await _answer(result);
  }

  /// The screen that covered the page is gone; a result held for it is answered now.
  Future<void> uncovered() async {
    final result = _held;
    _held = null;
    if (result != null) await _answer(result);
  }

  /// The page is no longer waiting for the held result - a new request started, or the app is
  /// leaving the page - so it is not answered.
  void drop() => _held = null;

  Future<void> _answer(PageResult result) async {
    _logger.info('Answering the page for $result with ${strategy.name}');
    switch (strategy) {
      case ResultStrategy.none:
        return;
      case ResultStrategy.reload:
        return page.reload();
      case ResultStrategy.restart:
        return page.restart();
      case ResultStrategy.notify:
        if (await page.takesResults()) return page.sendResult(result);
        return _historyBack();
      case ResultStrategy.historyBack:
        return _historyBack();
    }
  }

  Future<void> _historyBack() async {
    if (await page.canGoBack()) {
      await page.goBack();
    } else {
      await page.reload();
    }
  }
}

/// [ResultPage] over the web view a page is shown in.
class WebViewResultPage implements ResultPage {
  WebViewResultPage(this._controller);

  /// The function on `window` a page defines to take results.
  static const callbackFunction = 'onWebTritResult';

  final WebViewController _controller;

  @override
  Future<bool> canGoBack() => _controller.canGoBackInPage();

  @override
  Future<void> goBack() => _controller.goBackInPage();

  @override
  Future<void> reload() => _controller.reloadPage();

  @override
  Future<void> restart() => _controller.restartPage();

  @override
  Future<bool> takesResults() async {
    try {
      final result = await _controller.runJavaScriptReturningResult("typeof window.$callbackFunction === 'function'");
      return result == true || result.toString() == 'true';
    } catch (_) {
      // A browser web view cannot run scripts in the page's frame: the page cannot be told.
      return false;
    }
  }

  @override
  Future<void> sendResult(PageResult result) =>
      _controller.runJavaScript('window.$callbackFunction(${jsonEncode(result.toJson())})');
}
