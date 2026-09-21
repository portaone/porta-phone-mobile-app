import 'package:flutter_test/flutter_test.dart';

import 'package:phoenix_socket/phoenix_socket.dart';

import 'package:webtrit_phone/features/messaging/extensions/phoenix_socket.dart';
import 'package:webtrit_phone/models/models.dart';

Message userChannelMessage(String event, Map<String, dynamic> payload) {
  return Message(topic: 'chat:user:alice', event: PhoenixChannelEvent.custom(event), payload: payload);
}

void main() {
  // A mute made on another device reaches this one only here, on the personal
  // topic: the conversation topic carries nothing, because a mute is the
  // user's and not the conversation's. Anything this factory does not name
  // becomes UserChannelUnknown and is dropped by both sync workers, which is
  // what happened to these two events before they were mapped.
  group('mute events on the personal topic', () {
    test('a chat mute update carries the chat and its new state', () {
      final event = UserChannelEvent.fromMessage(
        userChannelMessage('chat_mute_update', {
          'chat_id': 42,
          'notifications_muted': true,
          'notifications_muted_until': '2026-09-01T18:00:00.000000Z',
        }),
      );

      expect(
        event,
        ChatConversationMuteUpdate(42, NotificationMute(muted: true, mutedUntil: DateTime.utc(2026, 9, 1, 18))),
      );
    });

    test('an sms conversation mute update carries the conversation and its new state', () {
      final event = UserChannelEvent.fromMessage(
        userChannelMessage('sms_conversation_mute_update', {
          'conversation_id': 7,
          'notifications_muted': false,
          'notifications_muted_until': null,
        }),
      );

      expect(event, SmsConversationMuteUpdate(7, NotificationMute.none));
    });

    test('an unmute forever and an unmute read apart', () {
      final forever = UserChannelEvent.fromMessage(
        userChannelMessage('chat_mute_update', {
          'chat_id': 42,
          'notifications_muted': true,
          'notifications_muted_until': null,
        }),
      );

      expect(forever, ChatConversationMuteUpdate(42, const NotificationMute(muted: true)));
      expect(forever, isNot(ChatConversationMuteUpdate(42, NotificationMute.none)));
    });

    test('the same event twice maps to equal values, so applying it twice is a no-op', () {
      Message message() => userChannelMessage('chat_mute_update', {
        'chat_id': 42,
        'notifications_muted': true,
        'notifications_muted_until': null,
      });

      expect(UserChannelEvent.fromMessage(message()), UserChannelEvent.fromMessage(message()));
    });

    test('an event of another kind is still unknown', () {
      final event = UserChannelEvent.fromMessage(userChannelMessage('something_else', {'chat_id': 42}));

      expect(event, isA<UserChannelUnknown>());
    });
  });
}
