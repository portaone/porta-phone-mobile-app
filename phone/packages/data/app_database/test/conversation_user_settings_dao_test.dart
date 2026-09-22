import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:app_database/app_database.dart';

// The settings tables are named for the category, not for the mute that is
// their only occupant today, and the next per-user setting is meant to arrive
// as a column here rather than as a table of its own. These pin the two
// properties that make that possible: a row can be created by a writer that
// knows nothing of the mute, and a mute write touches only its own columns.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.chatsDao.upsertChat(
      ChatData(
        id: 42,
        type: ChatTypeEnum.group,
        name: 'engineering',
        createdAtRemote: DateTime.utc(2026, 9, 1),
        updatedAtRemote: DateTime.utc(2026, 9, 1),
      ),
    );
  });

  tearDown(() => database.close());

  test('a row created without the mute is not muted', () async {
    await database.into(database.chatUserSettingsTable).insert(const ChatUserSettingsDataCompanion(chatId: Value(42)));

    final settings = await database.chatsDao.getChatUserSettings(42);
    expect(settings?.muted, isFalse);
    expect(settings?.mutedUntilUsec, null);
  });

  test('muting writes the pair, and unmuting clears the expiration', () async {
    await database.chatsDao.upsertChatNotificationMute(42, muted: true, mutedUntilUsec: 1789550078000000);
    expect((await database.chatsDao.getChatUserSettings(42))?.mutedUntilUsec, 1789550078000000);

    await database.chatsDao.upsertChatNotificationMute(42, muted: false);

    final settings = await database.chatsDao.getChatUserSettings(42);
    expect(settings?.muted, isFalse);
    expect(settings?.mutedUntilUsec, null);
  });

  test('the same value written twice reports no change', () async {
    // The device that made the change is told about it on the personal topic
    // too, and a reconnect re-reads every conversation: most writes repeat
    // what is already stored, and a caller has to be able to tell.
    expect(await database.chatsDao.upsertChatNotificationMute(42, muted: true), isTrue);
    expect(await database.chatsDao.upsertChatNotificationMute(42, muted: true), isFalse);

    expect(await database.chatsDao.upsertChatNotificationMute(42, muted: true, mutedUntilUsec: 1), isTrue);
    expect(await database.chatsDao.upsertChatNotificationMute(42, muted: true, mutedUntilUsec: 1), isFalse);
    expect(await database.chatsDao.upsertChatNotificationMute(42, muted: true, mutedUntilUsec: null), isTrue);
  });

  test('a mute leaves the rest of the row alone', () async {
    // Stands in for a setting added later: whatever else the row holds, a
    // mute arriving from the socket must not be an update of the whole row.
    await database.customStatement('ALTER TABLE chat_user_settings ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0');
    await database.customStatement('INSERT INTO chat_user_settings (chat_id, pinned) VALUES (42, 1)');

    await database.chatsDao.upsertChatNotificationMute(42, muted: true);

    final row = await database.customSelect('SELECT muted, pinned FROM chat_user_settings').getSingle();
    expect(row.read<bool>('muted'), isTrue);
    expect(row.read<int>('pinned'), 1);
  });
}
