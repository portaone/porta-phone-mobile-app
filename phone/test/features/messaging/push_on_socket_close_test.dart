import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:phoenix_socket/phoenix_socket.dart';

import 'package:webtrit_phone/features/messaging/extensions/phoenix_socket.dart';

/// A Phoenix endpoint on loopback that acknowledges the heartbeat and the
/// channel join, then closes the socket normally when [closeOn] arrives -
/// the socket dropping while a push waits for its reply.
Future<HttpServer> _startPhoenixServer({required String closeOn}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final ws = await WebSocketTransformer.upgrade(request);
    ws.listen((raw) {
      final [joinRef, ref, topic, event, _] = jsonDecode(raw as String) as List;
      if (event == closeOn) {
        ws.close(WebSocketStatus.normalClosure);
        return;
      }
      ws.add(
        jsonEncode([
          joinRef,
          ref,
          topic,
          'phx_reply',
          {'status': 'ok', 'response': {}},
        ]),
      );
    });
  });
  return server;
}

void main() {
  // phoenix_socket 0.8.0 left the future of its reply waiter unhandled, so this
  // close reached the root zone and was reported to Crashlytics as a fatal
  // crash, although the caller below handles it and the app keeps running.
  test('a socket closing during a push fails the push and nothing else', () async {
    final server = await _startPhoenixServer(closeOn: 'chat:get_all');
    addTearDown(() => server.close(force: true));

    final uncaught = <Object>[];
    Object? pushError;

    await runZonedGuarded(() async {
      final socket = PhoenixSocket('ws://127.0.0.1:${server.port}/socket/websocket');
      addTearDown(socket.dispose);
      await socket.connect();

      final channel = socket.createUserChannel('alice');
      await channel.join().future;

      try {
        await channel.chatConversationsIds;
      } catch (e) {
        pushError = e;
      }
      // The leaked error arrives a few microtasks after the push has failed.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }, (error, _) => uncaught.add(error));

    expect(pushError, isA<MessagingSocketException>().having((e) => e.code, 'code', kPhxSocketClosedCode));
    expect(uncaught, isEmpty);
  });
}
