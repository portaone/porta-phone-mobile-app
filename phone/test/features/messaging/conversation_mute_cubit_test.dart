import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:clock/clock.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import 'conversation_screen_harness.dart';

class _MockPhoenixChannel extends Mock implements PhoenixChannel {}

class _MockPush extends Mock implements Push {}

class _MockChatsRepository extends Mock implements ChatsRepository {}

class _MockChatsOutboxRepository extends Mock implements ChatsOutboxRepository {}

class _MockSmsOutboxRepository extends Mock implements SmsOutboxRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(NotificationMute.none);
    registerFallbackValue(MessageSyncCursorType.oldest);
    registerFallbackValue(SmsSyncCursorType.oldest);
    registerFallbackValue(DateTime(0));
  });

  final at = DateTime.utc(2026, 9, 21, 12);

  late MockPhoenixSocket socket;
  late _MockPhoenixChannel channel;
  late _MockPush push;

  /// What the socket answers: a settled state from the core, or a failure.
  void channelAnswers(String event, {Map<String, dynamic>? reply, Object? failure}) {
    when(() => channel.push(event, any())).thenReturn(push);
    if (failure != null) {
      when(() => push.future).thenThrow(failure);
    } else {
      when(() => push.future).thenAnswer((_) async => PushResponse(status: 'ok', response: reply));
    }
  }

  Map<String, dynamic> sentPayload(String event) {
    return verify(() => channel.push(event, captureAny())).captured.single as Map<String, dynamic>;
  }

  setUp(() {
    socket = MockPhoenixSocket();
    channel = _MockPhoenixChannel();
    push = _MockPush();
    when(() => channel.state).thenReturn(PhoenixChannelState.joined);
    when(() => channel.topic).thenReturn('chat:42');
  });

  group('a chat', () {
    late _MockChatsRepository chatsRepository;
    late ConversationCubit cubit;

    setUp(() async {
      chatsRepository = _MockChatsRepository();
      final outbox = _MockChatsOutboxRepository();
      when(() => chatsRepository.getChat(42)).thenAnswer((_) async => groupChat(id: 42, name: 'Team'));
      when(() => chatsRepository.getChatMessageSyncCursor(42, any())).thenAnswer((_) async => null);
      when(() => chatsRepository.getMessageHistory(42, to: any(named: 'to'))).thenAnswer((_) async => []);
      when(() => chatsRepository.eventBus).thenAnswer((_) => const Stream.empty());
      when(() => chatsRepository.watchChatMessageReadCursors(42)).thenAnswer((_) => const Stream.empty());
      when(() => chatsRepository.upsertChatMute(42, any())).thenAnswer((_) async {});
      when(() => outbox.watchChatOutboxMessages()).thenAnswer((_) => const Stream.empty());
      when(() => outbox.watchChatOutboxMessageEdits()).thenAnswer((_) => const Stream.empty());
      when(() => outbox.watchChatOutboxMessageDeletes()).thenAnswer((_) => const Stream.empty());
      // getChatChannel is an extension over the socket's channel map.
      when(() => socket.channels).thenReturn({'chat:42': channel});

      cubit = ConversationCubit((chatId: 42, participantId: null), socket, chatsRepository, outbox);
      await cubit.init();
    });

    tearDown(() => cubit.close());

    // The core refuses a moment with no offset rather than guess at the zone,
    // and "forever" is the absence of the field, not a far-off date.
    test('muting for an hour asks for an hour from now, with the offset the core insists on', () async {
      channelAnswers(
        'chat:mute',
        reply: {'chat_id': 42, 'notifications_muted': true, 'notifications_muted_until': '2026-09-21T13:00:00.000000Z'},
      );

      await withClock(Clock.fixed(at), () => cubit.muteFor(const Duration(hours: 1)));

      final mutedUntil = sentPayload('chat:mute')['muted_until'] as String;
      expect(mutedUntil, endsWith('Z'));
      expect(DateTime.parse(mutedUntil), at.add(const Duration(hours: 1)));
    });

    test('muting for good sends no expiration at all', () async {
      channelAnswers(
        'chat:mute',
        reply: {'chat_id': 42, 'notifications_muted': true, 'notifications_muted_until': null},
      );

      await cubit.muteFor(null);

      expect(sentPayload('chat:mute'), isEmpty);
    });

    // The reply is the state the core settled on. It is stored at once; the
    // personal topic brings the same value a moment later, a no-op by then.
    test('the state the core settled on is stored, and the lock is let go', () async {
      channelAnswers(
        'chat:mute',
        reply: {'chat_id': 42, 'notifications_muted': true, 'notifications_muted_until': null},
      );

      await cubit.muteFor(null);

      verify(() => chatsRepository.upsertChatMute(42, const NotificationMute(muted: true))).called(1);
      expect((cubit.state as CVSReady).busy, isFalse);
    });

    test('unmuting stores the unmuted state', () async {
      channelAnswers(
        'chat:unmute',
        reply: {'chat_id': 42, 'notifications_muted': false, 'notifications_muted_until': null},
      );

      await cubit.unmute();

      verify(() => chatsRepository.upsertChatMute(42, NotificationMute.none)).called(1);
    });

    test('a refusal stores nothing and does not leave the screen busy', () async {
      channelAnswers(
        'chat:mute',
        failure: const PushResponse(status: 'error', response: {'code': 'user_not_in_chat'}),
      );

      await cubit.muteFor(null);

      verifyNever(() => chatsRepository.upsertChatMute(any(), any()));
      expect((cubit.state as CVSReady).busy, isFalse);
    });

    test('nothing is sent while the channel is not joined', () async {
      when(() => channel.state).thenReturn(PhoenixChannelState.closed);

      await cubit.muteFor(null);

      verifyNever(() => channel.push(any(), any()));
    });
  });

  group('a text conversation', () {
    late MockSmsRepository smsRepository;
    late SmsConversationCubit cubit;

    setUp(() async {
      smsRepository = MockSmsRepository();
      final outbox = _MockSmsOutboxRepository();
      final conversation = SmsConversation(
        id: 7,
        firstPhoneNumber: '111',
        secondPhoneNumber: '222',
        createdAt: at,
        updatedAt: at,
      );
      when(() => smsRepository.findConversationBetweenNumbers('111', '222')).thenAnswer((_) async => conversation);
      when(() => smsRepository.getMessageSyncCursor(7, any())).thenAnswer((_) async => null);
      when(() => smsRepository.getMessageHistory(7, to: any(named: 'to'))).thenAnswer((_) async => []);
      when(() => smsRepository.eventBus).thenAnswer((_) => const Stream.empty());
      when(() => smsRepository.watchMessageReadCursors(7)).thenAnswer((_) => const Stream.empty());
      when(() => smsRepository.upsertConversationMute(7, any())).thenAnswer((_) async {});
      when(() => outbox.watchOutboxMessages()).thenAnswer((_) => const Stream.empty());
      when(() => outbox.watchOutboxMessageDeletes()).thenAnswer((_) => const Stream.empty());
      when(() => channel.topic).thenReturn('chat:sms:7');
      when(() => socket.channels).thenReturn({'chat:sms:7': channel});

      cubit = SmsConversationCubit(
        (firstNumber: '111', secondNumber: '222', recipientId: null),
        socket,
        smsRepository,
        outbox,
      );
      // The cubit prepares itself from the constructor; let that settle.
      await cubit.stream.firstWhere((state) => state is SCSReady);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => cubit.close());

    test('muting for two days asks the conversation topic, and stores the reply', () async {
      channelAnswers(
        'sms:conversation:mute',
        reply: {
          'conversation_id': 7,
          'notifications_muted': true,
          'notifications_muted_until': '2026-09-23T12:00:00.000000Z',
        },
      );

      await withClock(Clock.fixed(at), () => cubit.muteFor(const Duration(days: 2)));

      final mutedUntil = sentPayload('sms:conversation:mute')['muted_until'] as String;
      expect(DateTime.parse(mutedUntil), at.add(const Duration(days: 2)));
      verify(
        () => smsRepository.upsertConversationMute(
          7,
          NotificationMute(muted: true, mutedUntil: DateTime.utc(2026, 9, 23, 12)),
        ),
      ).called(1);
      expect((cubit.state as SCSReady).busy, isFalse);
    });

    test('unmuting asks the conversation topic', () async {
      channelAnswers(
        'sms:conversation:unmute',
        reply: {'conversation_id': 7, 'notifications_muted': false, 'notifications_muted_until': null},
      );

      await cubit.unmute();

      verify(() => smsRepository.upsertConversationMute(7, NotificationMute.none)).called(1);
    });
  });
}
