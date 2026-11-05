import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:signaling/signaling.dart';

class _FakeChannel implements WebSocketChannel {
  final messages = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => messages.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeChannel channel;
  late List<Event> events;
  late List<Object> errors;

  Future<void> receive(Map<String, dynamic> message) async {
    channel.messages.add(jsonEncode(message));
    await pumpEventQueue();
  }

  setUp(() {
    channel = _FakeChannel();
    events = [];
    errors = [];
    WebtritSignalingClient.inner(channel).listen(
      onStateHandshake: (_) {},
      onEvent: events.add,
      onError: (error, _) => errors.add(error),
      onDisconnect: (_, _) {},
    );
  });

  test('an unknown event reaches neither handler', () async {
    await receive({'event': 'message_summary_update', 'messages_waiting': true});

    expect(events, isEmpty);
    expect(errors, isEmpty);
  });

  test('the client goes on after an unknown event', () async {
    await receive({'event': 'message_summary_update', 'messages_waiting': true});
    await receive({'event': 'conference_terminated', 'room': 4242});

    expect(events, [const ConferenceTerminatedEvent(room: 4242)]);
    expect(errors, isEmpty);
  });

  test('an error event of no known shape stays a failure', () async {
    await receive({'event': 'error', 'code': 'not a number'});

    expect(events, isEmpty);
    expect(errors, hasLength(1));
  });
}
