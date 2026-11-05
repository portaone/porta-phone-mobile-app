import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:signaling/signaling.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

void main() {
  late StreamController<dynamic> messages;
  late List<Event> events;
  late List<Object> errors;

  Future<void> receive(Map<String, dynamic> message) async {
    messages.add(jsonEncode(message));
    await pumpEventQueue();
  }

  setUp(() {
    final channel = MockWebSocketChannel();
    messages = StreamController<dynamic>();
    when(() => channel.stream).thenAnswer((_) => messages.stream);
    events = [];
    errors = [];
    WebtritSignalingClient.inner(channel).listen(
      onStateHandshake: (_) {},
      onEvent: events.add,
      onError: (error, _) => errors.add(error),
      onDisconnect: (_, _) {},
    );
  });

  tearDown(() async {
    await messages.close();
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

  test('an unknown event type is logged once per client', () async {
    final previousLevel = Logger.root.level;
    Logger.root.level = Level.WARNING;
    addTearDown(() => Logger.root.level = previousLevel);
    final logged = <String>[];
    final subscription = Logger.root.onRecord.listen((record) => logged.add(record.message));
    addTearDown(subscription.cancel);

    await receive({'event': 'message_summary_update', 'messages_waiting': true});
    await receive({'event': 'message_summary_update', 'messages_waiting': false});

    expect(logged.where((message) => message.contains('message_summary_update')), hasLength(1));
  });

  test('an error event of no known shape stays a failure', () async {
    await receive({'event': 'error', 'code': 'not a number'});

    expect(events, isEmpty);
    expect(errors, hasLength(1));
  });

  test('a known event that fails to parse stays a failure', () async {
    await receive({'event': 'conference_terminated', 'room': 'not a number'});

    expect(events, isEmpty);
    expect(errors, hasLength(1));
  });

  test('a new value of an enum reaches the app as unknown', () async {
    await receive({'event': 'ice_media', 'line': 0, 'mid': '0', 'type': 'screen', 'receiving': true});

    expect(events.single, isA<IceMediaEvent>().having((e) => e.type, 'type', IceMediaType.unknown));
    expect(errors, isEmpty);
  });

  test('a message of no known kind is skipped', () async {
    await receive({'handshake': 'future_handshake'});
    await receive({'something': 'else'});

    expect(events, isEmpty);
    expect(errors, isEmpty);
  });

  for (final type in [null, 5]) {
    test('an event type of $type stays a failure', () async {
      await receive({'event': type});

      expect(events, isEmpty);
      expect(errors, hasLength(1));
    });
  }
}
