import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockChatsRepository extends Mock implements ChatsRepository {}

class _MockSmsRepository extends Mock implements SmsRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockSession extends Mock implements Session {}

class _MockUserSettingsCubit extends MockCubit<ConversationUserSettingsState>
    implements ConversationUserSettingsCubit {}

void main() {
  late _MockChatsRepository chatsRepository;
  late _MockSmsRepository smsRepository;
  late _MockUserSettingsCubit userSettings;
  late _MockSessionRepository sessionRepository;
  late UnreadCountCubit cubit;

  UnreadCountCubit createCubit({bool chats = true, bool sms = true}) {
    return cubit = UnreadCountCubit(
      chatsRepository: chatsRepository,
      smsRepository: smsRepository,
      sessionRepository: sessionRepository,
      userSettings: userSettings,
      messagingConfig: MessagingConfig(
        coreSmsSupport: sms,
        coreChatsSupport: chats,
        tabEnabled: true,
        groupChatSupport: false,
        contactInfoVideoCallSupport: false,
      ),
    );
  }

  void givenNoMutes() {
    whenListen(
      userSettings,
      const Stream<ConversationUserSettingsState>.empty(),
      initialState: const ConversationUserSettingsState(),
    );
  }

  setUp(() {
    chatsRepository = _MockChatsRepository();
    smsRepository = _MockSmsRepository();
    userSettings = _MockUserSettingsCubit();
    sessionRepository = _MockSessionRepository();
    final session = _MockSession();
    when(() => session.userId).thenReturn('user-1');
    when(() => sessionRepository.getCurrent()).thenReturn(session);
    when(() => chatsRepository.eventBus).thenAnswer((_) => const Stream.empty());
    when(() => smsRepository.eventBus).thenAnswer((_) => const Stream.empty());
    when(() => chatsRepository.unreadedCountPerChat('user-1')).thenAnswer((_) async => {1: 3, 2: 1});
    when(() => smsRepository.unreadedCountPerConversation('user-1')).thenAnswer((_) async => {7: 5, 8: 2});
  });

  tearDown(() => cubit.close());

  // The totals a tab or the bottom bar shows should not grow for a
  // conversation the user asked to hear nothing from, while the row's own
  // badge still counts - what was missed stays visible where the user looks
  // for it. The totals mean that here, once, so no reader has to know about
  // the mutes at all.
  test('the totals leave muted conversations out, the per-row counts do not', () async {
    whenListen(
      userSettings,
      const Stream<ConversationUserSettingsState>.empty(),
      initialState: const ConversationUserSettingsState(mutedChatIds: {2}, mutedSmsConversationIds: {7, 8}),
    );

    createCubit().init();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.chatsWithUnreadCount, 1);
    expect(cubit.state.smsConversationsWithUnreadCount, 0);
    expect(cubit.state.unreadCountForChatConversation(2), 1);
  });

  // A mute lapses on the settings cubit's clock, with no message arriving; the
  // totals have to follow without asking the database again.
  test('a change of the mutes moves the totals without another query', () async {
    whenListen(
      userSettings,
      Stream.fromIterable([
        const ConversationUserSettingsState(mutedChatIds: {2}),
      ]),
      initialState: const ConversationUserSettingsState(),
    );

    createCubit().init();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.chatsWithUnreadCount, 1);
    verify(() => chatsRepository.unreadedCountPerChat('user-1')).called(1);
  });

  // Switching SMS off stops its sync and hides its screens, but the rows
  // synced before stay in the local database. Counted, they would hold a
  // badge on the bar that no screen lets the user clear.
  test('with SMS off the stored SMS conversations are not counted', () async {
    givenNoMutes();

    createCubit(sms: false).init();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.chatsWithUnreadCount, 2);
    expect(cubit.state.smsConversationsWithUnreadCount, 0);
    expect(cubit.state.unreadCountForSmsConversation(7), 0);
    verifyNever(() => smsRepository.unreadedCountPerConversation(any()));
    verifyNever(() => smsRepository.eventBus);
  });

  test('with chats off the stored chats are not counted', () async {
    givenNoMutes();

    createCubit(chats: false).init();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.chatsWithUnreadCount, 0);
    expect(cubit.state.smsConversationsWithUnreadCount, 2);
    expect(cubit.state.unreadCountForChatConversation(1), 0);
    verifyNever(() => chatsRepository.unreadedCountPerChat(any()));
    verifyNever(() => chatsRepository.eventBus);
  });
}
