import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';

final _now = DateTime(2026, 11, 10, 12);

void main() {
  group('chats', () {
    final chats = <ChatWithMessageAndMemebers>[
      (
        chat: Chat(id: 1, type: ChatType.group, name: 'Team', createdAt: _now, updatedAt: _now, members: const []),
        message: null,
        contacts: const [],
      ),
      (
        chat: Chat(id: 2, type: ChatType.direct, name: null, createdAt: _now, updatedAt: _now, members: const []),
        message: ChatMessage(
          id: 2,
          idKey: 'k2',
          senderId: 'peer',
          chatId: 2,
          replyToId: null,
          forwardFromId: null,
          authorId: null,
          content: 'See you at Five',
          createdAt: _now,
          updatedAt: _now,
          editedAt: null,
          deletedAt: null,
        ),
        contacts: [
          Contact(
            id: 7,
            sourceType: ContactSourceType.external,
            sourceId: 'peer',
            kind: ContactKind.visible,
            firstName: 'Yaroslav',
            lastName: 'Zhuk',
            isCurrentUser: false,
          ),
        ],
      ),
    ];

    List<int> found(String search) =>
        ChatConversationsCubit.filterBySearch(search, chats).map((e) => e.chat.id).toList();

    test('a name is found whatever the case of the query, as a watch keyboard capitalises it', () {
      expect(found('Ya'), [2]);
      expect(found('ya'), [2]);
      expect(found('TEAM'), [1]);
    });

    test('a name the contact lacks is not searched as the word null', () {
      expect(found('null'), isEmpty);
      expect(found('Yaroslav Zhuk'), [2]);
    });

    test('the last message is found whatever its case or the query\'s', () {
      expect(found('five'), [2]);
      expect(found('See'), [2]);
      expect(found('nothing'), isEmpty);
    });
  });

  group('SMS', () {
    final conversations = <(SmsConversation, SmsMessage?)>[
      (
        SmsConversation(id: 1, firstPhoneNumber: '+1202', secondPhoneNumber: '+1303', createdAt: _now, updatedAt: _now),
        SmsMessage(
          id: 1,
          idKey: 'k1',
          externalId: null,
          conversationId: 1,
          fromPhoneNumber: '+1303',
          toPhoneNumber: '+1202',
          sendingStatus: SmsSendingStatus.values.first,
          content: 'Your Code is 4821',
          createdAt: _now,
          updatedAt: _now,
          deletedAt: null,
        ),
      ),
    ];

    test('the last message is found whatever the case of the query', () {
      expect(SmsConversationsCubit.filterBySearch('Code', conversations), hasLength(1));
      expect(SmsConversationsCubit.filterBySearch('code', conversations), hasLength(1));
      expect(SmsConversationsCubit.filterBySearch('Your', conversations), hasLength(1));
      expect(SmsConversationsCubit.filterBySearch('1303', conversations), hasLength(1));
      expect(SmsConversationsCubit.filterBySearch('nothing', conversations), isEmpty);
    });
  });
}
