import 'package:test/test.dart';

import 'package:signaling/signaling.dart';

void main() {
  test('decodes the event PortaSwitch sends, without counters', () {
    final event = Event.fromJson({'event': 'message_summary_update', 'messages_waiting': true});

    expect(event, const MessageSummaryUpdate(messagesWaiting: true));
  });

  test('decodes the counters when the SIP server reports them', () {
    final event = Event.fromJson({
      'event': 'message_summary_update',
      'messages_waiting': true,
      'voice_message': {'new': 2, 'old': 8, 'urgent_new': 0, 'urgent_old': 2},
    });

    expect(
      event,
      const MessageSummaryUpdate(
        messagesWaiting: true,
        voiceMessage: SignalingVoiceMessageSummary(newCount: 2, oldCount: 8, urgentNewCount: 0, urgentOldCount: 2),
      ),
    );
  });

  test('is not a global event: presence and dialogs are, and those go to calls', () {
    expect(Event.fromJson({'event': 'message_summary_update', 'messages_waiting': true}), isNot(isA<GlobalEvent>()));
  });

  test('round-trips through toJson, as the Android hub passes it between isolates', () {
    const events = [
      MessageSummaryUpdate(messagesWaiting: false),
      MessageSummaryUpdate(
        messagesWaiting: true,
        voiceMessage: SignalingVoiceMessageSummary(newCount: 1, oldCount: 0, urgentNewCount: 0, urgentOldCount: 0),
      ),
    ];

    for (final event in events) {
      expect(Event.fromJson(event.toJson()), event);
    }
  });
}
