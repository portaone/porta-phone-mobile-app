import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';

import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

Chat _chat({String? name}) => Chat(
  id: 42,
  type: ChatType.group,
  name: name ?? 'engineering',
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  members: const [],
);

SmsConversation _conversation() => SmsConversation(
  id: 7,
  firstPhoneNumber: '123010',
  secondPhoneNumber: '123009',
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase appDatabase;
  late ChatsRepository chatsRepository;
  late SmsRepository smsRepository;

  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory());
    chatsRepository = ChatsRepository(appDatabase: appDatabase);
    smsRepository = SmsRepository(appDatabase: appDatabase);
  });

  tearDown(() => appDatabase.close());

  // The mute is stored beside the conversation rather than on it, and this is
  // the reason why. A conversation row is replaced whole every time the core
  // sends the conversation again, and the event that does so most often -
  // a rename, broadcast to every member - carries no mute at all.
  group('a conversation write cannot take the mute with it', () {
    test('renaming a chat leaves its mute alone', () async {
      await chatsRepository.upsertChat(_chat());
      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));

      await chatsRepository.upsertChat(_chat(name: 'engineering (renamed)'));

      expect((await chatsRepository.getChatUserSettings(42)).mute, const NotificationMute(muted: true));
      expect((await chatsRepository.getChat(42))?.name, 'engineering (renamed)');
    });

    test('writing an sms conversation again leaves its mute alone', () async {
      await smsRepository.upsertConversation(_conversation());
      await smsRepository.upsertConversationMute(7, const NotificationMute(muted: true));

      await smsRepository.upsertConversation(_conversation());

      expect((await smsRepository.getConversationUserSettings(7)).mute, const NotificationMute(muted: true));
    });
  });

  group('reading the mute back', () {
    test('a conversation nobody muted reads as none, not as missing', () async {
      await chatsRepository.upsertChat(_chat());

      expect((await chatsRepository.getChatUserSettings(42)).mute, NotificationMute.none);
      expect((await smsRepository.getConversationUserSettings(7)).mute, NotificationMute.none);
    });

    test('an expiration survives the round trip to the same instant', () async {
      final mutedUntil = DateTime.utc(2026, 9, 1, 18, 30);
      await chatsRepository.upsertChat(_chat());

      await chatsRepository.upsertChatMute(42, NotificationMute(muted: true, mutedUntil: mutedUntil));

      // Plain equality, not isAtSameMomentAs: the socket parses the core's
      // UTC timestamps into UTC values and Dart's == is false across UTC and
      // local, so a mute read back as local would never equal the mute it
      // was stored from, and every "unchanged?" check downstream would fail.
      final stored = (await chatsRepository.getChatUserSettings(42)).mute;
      expect(stored, NotificationMute(muted: true, mutedUntil: mutedUntil));
      expect(stored.isActiveAt(DateTime.utc(2026, 9, 1, 18, 29)), isTrue);
      expect(stored.isActiveAt(DateTime.utc(2026, 9, 1, 18, 31)), isFalse);
    });

    test('the same write twice stores once, and puts nothing on the bus', () async {
      // The other device's mute comes back to this one on the personal topic,
      // and a reconnect re-reads every conversation, so the repeated write is
      // the ordinary case. Nothing on the bus consumes a mute, and every
      // listener there would pay for one - some with a database read.
      await chatsRepository.upsertChat(_chat());
      final events = <ChatsEvent>[];
      final sub = chatsRepository.eventBus.listen(events.add);
      addTearDown(sub.cancel);

      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));
      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));
      await Future<void>.delayed(Duration.zero);

      expect((await chatsRepository.getChatUserSettings(42)).mute, const NotificationMute(muted: true));
      expect(events, isEmpty);
    });

    test('a mute for a chat this client does not hold is dropped, not written', () async {
      // Another device creates a group and mutes it at once; the join and the
      // mute reach this one on the personal topic while chat:get is still in
      // flight. The row the mute hangs off does not exist yet, and chat:get
      // carries the mute anyway - so nothing is written, and nothing throws
      // out of the personal-topic loop.
      final events = <ChatsEvent>[];
      final sub = chatsRepository.eventBus.listen(events.add);
      addTearDown(sub.cancel);

      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));
      await smsRepository.upsertConversationMute(7, const NotificationMute(muted: true));
      await Future<void>.delayed(Duration.zero);

      expect((await chatsRepository.getChatUserSettings(42)).mute, NotificationMute.none);
      expect(events, isEmpty);
    });

    test('watching hands out every mute at once, keyed by conversation', () async {
      await chatsRepository.upsertChat(_chat());
      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));

      expect(await chatsRepository.watchChatUserSettings().first, {
        42: const ConversationUserSettings(mute: NotificationMute(muted: true)),
      });
    });
  });

  // A mute belongs to a conversation this client still has. Leaving a group
  // drops it in the core too, so a stale row must not outlive the row it
  // hangs off and come back as a muted icon on a rejoin.
  group('the mute goes when the conversation goes', () {
    test('deleting a chat takes its mute with it', () async {
      await chatsRepository.upsertChat(_chat());
      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));

      await chatsRepository.deleteChatById(42);

      expect((await chatsRepository.getChatUserSettings(42)).mute, NotificationMute.none);
    });

    test('deleting an sms conversation takes its mute with it', () async {
      await smsRepository.upsertConversation(_conversation());
      await smsRepository.upsertConversationMute(7, const NotificationMute(muted: true));

      await smsRepository.deleteConversationById(7);

      expect((await smsRepository.getConversationUserSettings(7)).mute, NotificationMute.none);
    });

    test('a wipe clears the mutes along with everything else', () async {
      await chatsRepository.upsertChat(_chat());
      await chatsRepository.upsertChatMute(42, const NotificationMute(muted: true));
      await smsRepository.upsertConversation(_conversation());
      await smsRepository.upsertConversationMute(7, const NotificationMute(muted: true));

      await appDatabase.chatsDao.wipeChatsData();
      await appDatabase.smsDao.wipeData();

      expect((await chatsRepository.getChatUserSettings(42)).mute, NotificationMute.none);
      expect((await smsRepository.getConversationUserSettings(7)).mute, NotificationMute.none);
    });
  });
}
