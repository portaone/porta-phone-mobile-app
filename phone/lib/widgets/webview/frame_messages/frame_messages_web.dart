import 'dart:js_interop';

import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'page_origin.dart';

final _logger = Logger('FrameMessages');

/// Listens for messages a page posts to the app from inside a browser web view.
///
/// A browser web view is a plain iframe and has no JavaScript channels: there
/// is no object for the page to call, and adding one throws. What a page in an
/// iframe can do is post to its parent window, so a page posts
/// `{channel: <name>, message: <string>}` to `window.parent`, and this hands
/// `message` to the handler [channels] keeps under that name, as the channel
/// would have. The message is the same string either way, so whoever reads it
/// does not need to know which way it came.
///
/// A message is taken only when both hold:
/// - it was posted by the iframe of [controller]: the window hears every frame
///   on the page and any window that opened it;
/// - it comes from the origin of [pageUri]: a browser web view follows any
///   link the page has, with nothing to stop it, and a page the sign-up page
///   led to must not complete a login. A page with no origin of its own, such
///   as an inline `data:` page, posts with the origin `null`. A message from
///   the iframe turned away for its origin is logged, since a page that was
///   redirected to another origin otherwise fails without a trace.
///
/// Answers how to stop listening, or null when [controller] is not a browser
/// web view.
void Function()? listenFrameMessages(
  WebViewController controller, {
  required Uri pageUri,
  required Map<String, void Function(String message)> channels,
}) {
  final params = controller.platform.params;
  if (params is! WebWebViewControllerCreationParams) return null;
  // The iframe is the only handle on which window a message came from, and the
  // plugin exposes it on the creation params without a public alternative. The
  // plugin is pinned to an exact version in pubspec.yaml for this reason.
  // ignore: invalid_use_of_visible_for_testing_member
  final frame = params.iFrame;
  final origin = pageOrigin(pageUri);

  final subscription = web.EventStreamProviders.messageEvent
      .forTarget(web.window)
      .listen((event) => _deliver(event, frame, origin, channels));

  return subscription.cancel;
}

void _deliver(
  web.MessageEvent event,
  web.HTMLIFrameElement frame,
  String origin,
  Map<String, void Function(String message)> channels,
) {
  final source = event.source;
  if (source == null || !source.strictEquals(frame.contentWindow).toDart) return;
  if (event.origin != origin) {
    _logger.warning('Ignored a message from ${event.origin}: the page was opened at $origin');
    return;
  }

  final data = event.data.dartify();
  if (data is! Map) return;

  final handler = channels[data['channel']];
  final message = data['message'];
  if (handler != null && message is String) handler(message);
}
