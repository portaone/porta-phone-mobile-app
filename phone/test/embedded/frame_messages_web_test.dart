@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';

import 'package:web/web.dart' as web;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'package:webtrit_phone/widgets/webview/frame_messages/frame_messages.dart';

/// A page in a browser web view reaches the app by posting to its parent
/// window, and only its own iframe, from the origin it was opened at, may:
/// these run in a real browser, with a real iframe and real cross-window
/// messages.
void main() {
  setUpAll(() => WebViewPlatform.instance = WebWebViewPlatform());

  // An inline page, which is what loadHtmlString opens, has no origin of its
  // own and posts with the origin "null".
  final inlinePage = Uri.parse('data:text/html,');

  late WebViewController controller;
  late web.HTMLIFrameElement frame;
  late List<String> received;
  late void Function()? stop;

  void listen(Uri pageUri) {
    stop = listenFrameMessages(controller, pageUri: pageUri, channels: {'WebtritLoginChannel': received.add});
  }

  setUp(() async {
    controller = WebViewController();
    // ignore: invalid_use_of_visible_for_testing_member
    frame = (controller.platform.params as WebWebViewControllerCreationParams).iFrame;
    web.document.body!.append(frame);
    received = [];
    stop = null;
  });

  tearDown(() {
    stop?.call();
    frame.remove();
  });

  Future<void> loadPage(String script) async {
    final loaded = frame.onLoad.first;
    await controller.loadHtmlString('<html><body><script>$script</script></body></html>');
    await loaded;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 200));

  test('a message the page posts for the channel is delivered as the channel would deliver it', () async {
    listen(inlinePage);

    await loadPage("parent.postMessage({channel: 'WebtritLoginChannel', message: '{\"event\":\"signup\"}'}, '*');");
    await settle();

    expect(received, ['{"event":"signup"}']);
  });

  test('a message for another channel is left alone', () async {
    listen(inlinePage);

    await loadPage("parent.postMessage({channel: 'SomethingElse', message: 'x'}, '*');");
    await settle();

    expect(received, isEmpty);
  });

  test('a message from another origin than the page was opened at is not taken', () async {
    listen(Uri.parse('https://signup.example.com/page'));

    await loadPage("parent.postMessage({channel: 'WebtritLoginChannel', message: 'elsewhere'}, '*');");
    await settle();

    expect(received, isEmpty);
  });

  test('a message posted by any window but the frame is not taken', () async {
    listen(inlinePage);

    web.window.postMessage({'channel': 'WebtritLoginChannel', 'message': 'forged'}.jsify(), '*'.toJS);
    await settle();

    expect(received, isEmpty);
  });

  test('nothing is delivered once listening stops', () async {
    listen(inlinePage);
    stop!();
    stop = null;

    await loadPage("parent.postMessage({channel: 'WebtritLoginChannel', message: 'late'}, '*');");
    await settle();

    expect(received, isEmpty);
  });
}
