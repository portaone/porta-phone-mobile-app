import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockChatsRepository extends Mock implements ChatsRepository {}

class _MockSmsRepository extends Mock implements SmsRepository {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockRemotePushRepository extends Mock implements RemotePushRepository {}

class _MockLocalPushRepository extends Mock implements LocalPushRepository {}

class _MockActiveMessagePushsRepository extends Mock implements ActiveMessagePushsRepository {}

class _MockMainScreenRouteStateRepository extends Mock implements MainScreenRouteStateRepository {}

class _MockMainShellRouteStateRepository extends Mock implements MainShellRouteStateRepository {}

class _FakeAppLocalPush extends Fake implements AppLocalPush {}

class _FakeActiveMessagePush extends Fake implements ActiveMessagePush {}

Chat _group() => Chat(
  id: 42,
  type: ChatType.group,
  name: 'engineering',
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  members: const [],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAppLocalPush());
    registerFallbackValue(_FakeActiveMessagePush());
  });

  late _MockChatsRepository chatsRepository;
  late _MockSmsRepository smsRepository;
  late _MockLocalPushRepository localPushRepository;
  late _MockActiveMessagePushsRepository activeMessagePushsRepository;
  late _MockMainShellRouteStateRepository mainShellRouteStateRepository;
  late StreamController<MessagePush> foregroundPushs;
  late MessagingPushService service;

  setUp(() {
    chatsRepository = _MockChatsRepository();
    smsRepository = _MockSmsRepository();
    localPushRepository = _MockLocalPushRepository();
    activeMessagePushsRepository = _MockActiveMessagePushsRepository();
    mainShellRouteStateRepository = _MockMainShellRouteStateRepository();
    final remotePushRepository = _MockRemotePushRepository();
    foregroundPushs = StreamController<MessagePush>();

    when(() => chatsRepository.eventBus).thenAnswer((_) => const Stream.empty());
    when(() => smsRepository.eventBus).thenAnswer((_) => const Stream.empty());
    when(() => localPushRepository.messagingActions).thenAnswer((_) => const Stream.empty());
    when(() => remotePushRepository.messagingOpenedPushs).thenAnswer((_) => const Stream.empty());
    when(() => remotePushRepository.messagingForegroundPushs).thenAnswer((_) => foregroundPushs.stream);
    when(() => localPushRepository.displayPush(any())).thenAnswer((_) async {});
    when(() => activeMessagePushsRepository.set(any())).thenAnswer((_) async {});
    when(() => chatsRepository.getChat(42)).thenAnswer((_) async => _group());
    when(() => mainShellRouteStateRepository.isChatConversationScreenActive(any(), any())).thenReturn(false);

    service = MessagingPushService(
      'user-1',
      chatsRepository,
      smsRepository,
      _MockContactsRepository(),
      remotePushRepository,
      localPushRepository,
      activeMessagePushsRepository,
      _MockMainScreenRouteStateRepository(),
      mainShellRouteStateRepository,
      () {},
      (_) {},
      (_) {},
      (_, _) {},
    )..init();
  });

  tearDown(() async {
    service.dispose();
    await foregroundPushs.close();
  });

  Future<void> deliver(MessagePush push) async {
    foregroundPushs.add(push);
    // The handler awaits two repository reads before deciding.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  // The core sends no push for a muted conversation, so this is about the
  // window: a mute set on another device reaches this one as an event, and a
  // push already on its way when it was set still lands here.
  group('a foreground push for a muted conversation', () {
    test('is not shown', () async {
      when(() => chatsRepository.getChatUserSettings(42))
          .thenAnswer((_) async => const ConversationUserSettings(mute: NotificationMute(muted: true)));

      await deliver(ChatsMessagePush('n1', 100, 42, title: 'engineering', body: 'hi'));

      verifyNever(() => localPushRepository.displayPush(any()));
      verifyNever(() => activeMessagePushsRepository.set(any()));
    });

    test('is shown once the mute has lapsed, whatever the stored value still says', () async {
      when(() => chatsRepository.getChatUserSettings(42)).thenAnswer(
        (_) async => ConversationUserSettings(
          mute: NotificationMute(muted: true, mutedUntil: DateTime.now().subtract(const Duration(minutes: 1))),
        ),
      );

      await deliver(ChatsMessagePush('n1', 100, 42, title: 'engineering', body: 'hi'));

      verify(() => localPushRepository.displayPush(any())).called(1);
    });

    test('is shown when nothing is muted', () async {
      when(() => chatsRepository.getChatUserSettings(42)).thenAnswer((_) async => ConversationUserSettings.none);

      await deliver(ChatsMessagePush('n1', 100, 42, title: 'engineering', body: 'hi'));

      verify(() => localPushRepository.displayPush(any())).called(1);
    });
  });
}
