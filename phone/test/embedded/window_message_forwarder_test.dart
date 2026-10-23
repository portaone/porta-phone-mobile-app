@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';

import 'package:web/web.dart' as web;

import 'package:webtrit_phone/widgets/webview/frame_messages/window_message_forwarder.dart';

/// On a phone a page posts to `window.parent`, which is the page itself, and the
/// injected script hands that to the channel object the app registered. These
/// run the script in a real browser window, with stand-ins for those objects.
void main() {
  const login = 'WebtritLoginChannelForwarderTest';
  const other = 'OtherChannelForwarderTest';

  late Map<String, List<String>> received;

  JSObject channelObject(String name) {
    final target = JSObject();
    target['postMessage'] = ((JSString message) => received[name]!.add(message.toDart)).toJS;
    return target;
  }

  setUpAll(() {
    received = {login: [], other: []};
    globalContext[login] = channelObject(login);
    globalContext[other] = channelObject(other);

    globalContext.callMethod('eval'.toJS, windowMessageForwarderScript([login, other]).toJS);
  });

  setUp(() {
    for (final messages in received.values) {
      messages.clear();
    }
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 100));

  void postToSelf(Object? data) => web.window.postMessage(data.jsify(), '*'.toJS);

  test('a message the page posts to itself reaches the channel it names', () async {
    postToSelf({'channel': login, 'message': '{"event":"signup"}'});
    postToSelf({'channel': other, 'message': 'other'});
    await settle();

    expect(received[login], ['{"event":"signup"}']);
    expect(received[other], ['other']);
  });

  test('a message for a channel not named or not a string is left alone', () async {
    postToSelf({'channel': 'SomethingElse', 'message': 'x'});
    postToSelf({'channel': login, 'message': 42});
    await settle();

    expect(received[login], isEmpty);
  });

  test('a message from a frame inside the page is not forwarded', () async {
    final frame = web.HTMLIFrameElement()
      ..srcdoc = "<script>parent.postMessage({channel: '$login', message: 'from a frame'}, '*');</script>".toJS;
    final loaded = frame.onLoad.first;
    web.document.body!.append(frame);
    await loaded;
    await settle();
    frame.remove();

    expect(received[login], isEmpty);
  });

  test('running the script again does not deliver a message twice', () async {
    globalContext.callMethod('eval'.toJS, windowMessageForwarderScript([login, other]).toJS);

    postToSelf({'channel': login, 'message': 'once'});
    await settle();

    expect(received[login], ['once']);
  });
}
