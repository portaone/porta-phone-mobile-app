import 'package:flutter/material.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class MockMessagingBloc extends MockBloc<MessagingEvent, MessagingState> implements MessagingBloc {}

class MockConversationCubit extends MockCubit<ConversationState> implements ConversationCubit {}

class MockSmsConversationCubit extends MockCubit<SmsConversationState> implements SmsConversationCubit {}

class MockPhoenixSocket extends Mock implements PhoenixSocket {}

class MockSmsRepository extends Mock implements SmsRepository {}

class MockContactsRepository extends Mock implements ContactsRepository {}

final _created = DateTime(2026, 9, 1);

/// A direct chat between the signed-in user and one other person.
Chat dialogChat({required int id}) => Chat(
  id: id,
  type: ChatType.direct,
  name: null,
  createdAt: _created,
  updatedAt: _created,
  members: [
    ChatMember(id: 1, chatId: id, userId: 'user-1', groupAuthorities: null),
    ChatMember(id: 2, chatId: id, userId: 'user-2', groupAuthorities: null),
  ],
);

/// A group of two, owned by the signed-in user.
Chat groupChat({required int id, String? name}) => Chat(
  id: id,
  type: ChatType.group,
  name: name,
  createdAt: _created,
  updatedAt: _created,
  members: [
    ChatMember(id: 1, chatId: id, userId: 'user-1', groupAuthorities: GroupAuthorities.owner),
    ChatMember(id: 2, chatId: id, userId: 'user-2', groupAuthorities: null),
  ],
);

/// Everything the two conversation screens read from around them.
///
/// The screens are pumped in a state that is not ready yet: the app bar - the
/// menu and the screen anchor this covers - is built in every state, while the
/// body of a ready conversation would pull in the whole message list.
class ConversationScreenHarness {
  ConversationScreenHarness() {
    when(() => messagingBloc.state).thenReturn(
      MessagingState.initial(
        'user-1',
        socket,
        const MessagingConfig(
          coreSmsSupport: true,
          coreChatsSupport: true,
          tabEnabled: true,
          groupChatSupport: true,
          contactInfoVideoCallSupport: true,
        ),
      ),
    );
    when(() => smsRepository.watchUserSmsNumbers()).thenAnswer((_) => const Stream<List<String>>.empty());
  }

  final messagingBloc = MockMessagingBloc();
  final conversationCubit = MockConversationCubit();
  final smsConversationCubit = MockSmsConversationCubit();
  final socket = MockPhoenixSocket();
  final smsRepository = MockSmsRepository();
  final contactsRepository = MockContactsRepository();

  /// A dialog with one other person, still loading: the menu has somewhere to
  /// go (the person's card) from the first frame.
  void withDialogLoading() {
    when(() => conversationCubit.state).thenReturn(const CVSInit((chatId: null, participantId: 'user-2')));
  }

  /// A conversation the app knows nothing about yet - not a dialog, and not
  /// known to be a group either, so the menu has nothing to open.
  void withUnknownConversationLoading() {
    when(() => conversationCubit.state).thenReturn(const CVSInit((chatId: 1, participantId: null)));
  }

  /// A loaded dialog with one other person, whose contact card is still on
  /// its way (the repository answers with nothing yet).
  void withDialogReady({int chatId = 6}) {
    when(() => conversationCubit.state)
        .thenReturn(CVSReady((chatId: chatId, participantId: 'user-2'), chat: dialogChat(id: chatId)));
    withNoContactCards();
  }

  /// A loaded group of two, owned by the signed-in user.
  void withGroupReady({int chatId = 42, String? name = 'Team'}) {
    when(() => conversationCubit.state)
        .thenReturn(CVSReady((chatId: chatId, participantId: null), chat: groupChat(id: chatId, name: name)));
    withNoContactCards();
  }

  /// Every member's card is asked for and none arrives - the screens name
  /// the members as unknown and stay put.
  void withNoContactCards() {
    when(
      () => contactsRepository.watchContactBySourceWithPhonesAndEmails(
        any(),
        any(),
        fetchIfMissing: any(named: 'fetchIfMissing'),
      ),
    ).thenAnswer((_) => Stream<Contact?>.value(null));
  }

  void withSmsConversation() {
    when(() => smsConversationCubit.state)
        .thenReturn(const SCSInit((firstNumber: '111', secondNumber: '222', recipientId: null)));
  }

  Widget wrap(Widget screen) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SmsRepository>.value(value: smsRepository),
          RepositoryProvider<ContactsRepository>.value(value: contactsRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<MessagingBloc>.value(value: messagingBloc),
            BlocProvider<ConversationCubit>.value(value: conversationCubit),
            BlocProvider<SmsConversationCubit>.value(value: smsConversationCubit),
          ],
          child: screen,
        ),
      ),
    );
  }
}
