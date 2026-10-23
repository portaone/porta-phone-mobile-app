import 'dart:convert';

/// The script that lets a page on a phone send the way it sends in a browser.
///
/// A page can reach the app with one call wherever it runs:
/// `window.parent.postMessage({channel: <name>, message: <string>}, '*')`. In a
/// browser the page is an iframe and that reaches the app's window, which
/// listens for it. On a phone the page is the top window, so `window.parent` is
/// the page itself and the message lands on its own window; this script,
/// injected once the page has finished loading, hands such a message to the
/// JavaScript channel of that name, which the app has registered there.
///
/// One script serves all of [channels]. Only messages the page posted to itself
/// are forwarded, never those from a frame inside it. Running the script again
/// on the same page adds nothing.
String windowMessageForwarderScript(Iterable<String> channels) {
  final names = jsonEncode(channels.toList());
  return '''
(function () {
  if (window.__webtritForwardsWindowMessages) return;
  window.__webtritForwardsWindowMessages = true;
  var names = $names;
  window.addEventListener('message', function (event) {
    if (event.source !== window) return;
    var data = event.data;
    if (!data || names.indexOf(data.channel) < 0 || typeof data.message !== 'string') return;
    var target = window[data.channel];
    if (target && typeof target.postMessage === 'function') target.postMessage(data.message);
  });
})();
''';
}
