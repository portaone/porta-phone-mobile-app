import 'package:webview_flutter/webview_flutter.dart';

/// Listens for messages a page posts to the app from inside a browser web view.
///
/// Only a browser web view needs this, so off the web there is nothing to
/// listen to and the answer is always null.
void Function()? listenFrameMessages(
  WebViewController controller, {
  required Uri pageUri,
  required Map<String, void Function(String message)> channels,
}) => null;
