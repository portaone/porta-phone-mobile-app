import 'dart:async';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

class ChatsRepository with ChatsDriftMapper {
  ChatsRepository({required AppDatabase appDatabase}) : _appDatabase = appDatabase;

  final AppDatabase _appDatabase;

  ChatsDao get _chatsDao => _appDatabase.chatsDao;

  final StreamController<ChatsEvent> _eventBus = StreamController.broadcast();

  Stream<ChatsEvent> get eventBus => _eventBus.stream;

  void _addEvent(ChatsEvent event) => _eventBus.add(event);

  Future<Chat?> getChat(int chatId) async {
    final chatData = await _chatsDao.getChatWithMembers(chatId);
    if (chatData == null) return null;
    return chatFromDrift(chatData);
  }

  Future<List<Chat>> getChats() async {
    final chatsData = await _chatsDao.getAllChatsWithMembers();
    return chatsData.map(chatFromDrift).toList();
  }

  Future<List<(Chat, ChatMessage?)>> getChatsWithLastMessages() async {
    final chatsData = await _chatsDao.getAllChatsWithMembersAndLastMessage();
    return chatsData.map((data) => chatWithLastMessageFromDrift(data)).toList();
  }

  Future<List<int>> getChatIds() async {
    return _chatsDao.getChatIds();
  }

  Future<int?> findDialogId(String participantId) {
    return _chatsDao.findDialogId(participantId);
  }

  Future<void> upsertChat(Chat chat) async {
    final chatData = chatToDrift(chat);
    final membersData = chat.members.map(chatMemberToDrift).toList();
    final chatDataWithMembers = ChatDataWithMembers(chatData, membersData);
    await _chatsDao.upsertChatWithMembers(chatDataWithMembers);
    _addEvent(ChatUpdate(chat));
  }

  Future<void> deleteChatById(int chatId) async {
    await _chatsDao.deleteChatById(chatId);
    _addEvent(ChatRemove(chatId));
  }

  /// What the user holds about [chatId], or [ConversationUserSettings.none]
  /// when this client has not been told of anything.
  ///
  /// Nothing distinguishes "nothing set" from "not known yet": a core that
  /// does not carry the mute never mutes anything either.
  Future<ConversationUserSettings> getChatUserSettings(int chatId) async {
    final data = await _chatsDao.getChatUserSettings(chatId);
    return data != null ? userSettingsFromDrift(data) : ConversationUserSettings.none;
  }

  /// Every chat's user settings, keyed by chat, for readers that need them all
  /// at once - the list and the unread totals ask about chats they do not have
  /// open. One stream for the whole row, so a setting added later is watched
  /// by the same subscription rather than by a second one on the same table.
  Stream<Map<int, ConversationUserSettings>> watchChatUserSettings() {
    return _chatsDao.watchChatUserSettings().map((rows) {
      return {for (final row in rows) row.chatId: userSettingsFromDrift(row)};
    });
  }

  /// Stores the mute the core reported for [chatId]; nothing when this client
  /// holds no such chat.
  ///
  /// Kept out of [upsertChat] deliberately. A chat arrives by two routes -
  /// the reply to `chat:get`, which carries the mute, and `chat_info_update`,
  /// which is broadcast to the whole chat and carries none - and both end in a
  /// full-row upsert. Were the mute a column on that row, a group rename would
  /// wipe it.
  ///
  /// A mute for a chat that is not stored yet is dropped rather than written.
  /// It happens: another device creates a group and mutes it at once, and the
  /// join and the mute reach this one on the personal topic while chat:get is
  /// still in flight. The row the mute hangs off does not exist, the insert
  /// would fail, and chat:get carries the mute anyway.
  ///
  /// Nothing goes on the bus: no one there needs a mute, and every listener
  /// pays for an event, some with a database read. Readers watch the settings
  /// table instead, and the DAO writes only when the value differs, so the
  /// same value arriving twice - this device's own mute echoed on the
  /// personal topic, a reconnect re-reading every conversation - wakes no one.
  ///
  /// The existence check and the write share a transaction: the chat can be
  /// deleted between them by the personal-topic loop, and a bare insert would
  /// then fail on the foreign key instead of being skipped.
  Future<void> upsertChatMute(int chatId, NotificationMute mute) {
    return _chatsDao.transaction(() async {
      if (!await _chatsDao.chatExists(chatId)) return;

      await _chatsDao.upsertChatNotificationMute(
        chatId,
        muted: mute.muted,
        mutedUntilUsec: mute.mutedUntil?.microsecondsSinceEpoch,
      );
    });
  }

  Future<ChatMessage?> getMessageById(int messageId) async {
    final messageData = await _chatsDao.getMessageById(messageId);
    return messageData != null ? messageFromDrift(messageData) : null;
  }

  Future<List<ChatMessage>> getMessageHistory(int chatId, {DateTime? from, DateTime? to, int limit = 100}) async {
    final messagesData = await _chatsDao.getMessageHistory(chatId, from: from, to: to, limit: limit);
    return messagesData.map(messageFromDrift).toList();
  }

  Future<void> upsertMessage(ChatMessage message, {bool silent = false}) async {
    await _chatsDao.upsertChatMessage(messageToDrift(message));
    if (!silent) _addEvent(ChatMessageUpdate(message));
  }

  Future<void> upsertMessages(Iterable<ChatMessage> messages, {bool silent = false}) async {
    await _chatsDao.upsertChatMessages(messages.map(messageToDrift));
    if (!silent) {
      for (final message in messages) {
        _addEvent(ChatMessageUpdate(message));
      }
    }
  }

  Future<ChatMessageSyncCursor?> getChatMessageSyncCursor(int chatId, MessageSyncCursorType cursorType) async {
    final type = messageSyncCursorTypeToDrift(cursorType);
    final data = await _chatsDao.getChatMessageSyncCursor(chatId, type);
    if (data != null) return messageSyncCursorFromDrift(data);
    return null;
  }

  Future<void> upsertChatMessageSyncCursor(ChatMessageSyncCursor cursor) async {
    final data = messageSyncCursorToDrift(cursor);
    await _chatsDao.upsertChatMessageSyncCursor(data);
  }

  Future<ChatMessageReadCursor?> getChatMessageReadCursor(int chatId, String userId) async {
    final data = await _chatsDao.getChatMessageReadCursor(chatId, userId);
    if (data != null) return messageReadCursorFromDrift(data);
    return null;
  }

  Stream<List<ChatMessageReadCursor>> watchChatMessageReadCursors(int chatId) {
    return _chatsDao.watchChatMessageReadCursors(chatId).map((data) => data.map(messageReadCursorFromDrift).toList());
  }

  Future<void> upsertChatMessageReadCursor(ChatMessageReadCursor cursor) async {
    final data = ChatMessageReadCursorData(
      chatId: cursor.chatId,
      userId: cursor.userId,
      timestampUsec: cursor.time.microsecondsSinceEpoch,
    );
    final inserted = await _chatsDao.upsertChatMessageReadCursor(data);
    if (inserted != null) _addEvent(ChatReadCursorUpdate(cursor));
  }

  Future<Map<int, int>> unreadedCountPerChat(String userId) {
    return _chatsDao.unreadedCountPerChat(userId);
  }

  Future<void> wipeStaleDeletedData() async {
    await _chatsDao.wipeStaleDeletedChatMessagesData();
  }

  Future<void> wipeChatsData() async {
    await _chatsDao.wipeChatsData();
  }
}
