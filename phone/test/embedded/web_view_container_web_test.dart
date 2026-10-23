@TestOn('browser')
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web/web.dart' as web;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/webview/webview.dart';

/// What a page shown in a WebViewContainer can do in a browser, where the web
/// view is a plain iframe with no history and no reload: these run in a real
/// browser, with the real web view plugin.
void main() {
  setUpAll(() => WebViewPlatform.instance = WebWebViewPlatform());

  late WebViewController controller;
  late web.HTMLIFrameElement frame;
  late List<String> received;

  setUp(() {
    controller = WebViewController();
    // ignore: invalid_use_of_visible_for_testing_member
    frame = (controller.platform.params as WebWebViewControllerCreationParams).iFrame;
    received = [];
  });

  Widget container(Uri page) => MaterialApp(
    locale: const Locale('uk'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WebViewContainer(
      initialUri: page,
      userAgent: 'test',
      showToolbar: false,
      webViewController: controller,
      jSChannelStrategies: [JSChannelStrategy(name: 'WebtritLoginChannel', onEvent: (_, e) => received.add(e.event))],
    ),
  );

  Future<void> settle(WidgetTester tester) =>
      tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));

  testWidgets('a reload opens the page again, locale included', (tester) async {
    await tester.pumpWidget(container(Uri.parse('https://signup.example.com/page')));
    frame.src = 'about:blank';

    await tester.runAsync(controller.reloadPage);

    final reopened = Uri.parse(frame.src);
    expect(reopened.host, 'signup.example.com');
    expect(reopened.queryParameters['localeName'], 'uk');
  });

  testWidgets('stepping back neither throws nor claims history there is none of', (tester) async {
    await tester.pumpWidget(container(Uri.parse('https://signup.example.com/page')));

    expect(await tester.runAsync(controller.canGoBackInPage), isFalse);
    await tester.runAsync(controller.goBackInPage);
  });

  testWidgets('a page opened at a new address is listened to at its new origin', (tester) async {
    await tester.pumpWidget(container(Uri.parse('https://signup.example.com/page')));
    web.document.body!.append(frame);

    const script = "parent.postMessage({channel: 'WebtritLoginChannel', message: '{\"event\":\"signup\"}'}, '*');";
    final inline = Uri.dataFromString('<script>$script</script>', mimeType: 'text/html');
    await tester.pumpWidget(container(inline));
    await settle(tester);
    frame.remove();

    expect(received, ['signup']);
  });
}
