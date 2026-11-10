import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockChatConversationsCubit extends MockCubit<ChatConversationsState> implements ChatConversationsCubit {}

class _MockMessagingBloc extends MockBloc<MessagingEvent, MessagingState> implements MessagingBloc {}

class _MockUnreadCountCubit extends MockCubit<UnreadCountState> implements UnreadCountCubit {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockPhoenixSocket extends Mock implements PhoenixSocket {}

class _MockStackRouter extends Mock implements StackRouter {}

final _now = DateTime(2026, 11, 10, 12);

Chat _chat(int id, {ChatType type = ChatType.direct, String? name}) => Chat(
  id: id,
  type: type,
  name: name,
  createdAt: _now,
  updatedAt: _now,
  members: [
    ChatMember(id: id * 10, chatId: id, userId: 'me', groupAuthorities: null),
    ChatMember(id: id * 10 + 1, chatId: id, userId: 'peer$id', groupAuthorities: null),
  ],
);

ChatMessage _message(int chatId, String content) => ChatMessage(
  id: chatId,
  idKey: 'k$chatId',
  senderId: 'peer$chatId',
  chatId: chatId,
  replyToId: null,
  forwardFromId: null,
  authorId: null,
  content: content,
  createdAt: _now,
  updatedAt: _now,
  editedAt: null,
  deletedAt: null,
);

void main() {
  late _MockChatConversationsCubit chats;
  late _MockMessagingBloc messaging;
  late _MockUnreadCountCubit unread;
  late _MockContactsRepository contacts;
  late _MockStackRouter router;

  void connection(ConnectionStatus status) {
    final state = MessagingState.initial(
      'me',
      _MockPhoenixSocket(),
      const MessagingConfig(
        coreSmsSupport: true,
        coreChatsSupport: true,
        tabEnabled: true,
        groupChatSupport: true,
        contactInfoVideoCallSupport: false,
      ),
    ).copyWith(status: status);
    whenListen(messaging, const Stream<MessagingState>.empty(), initialState: state);
  }

  setUpAll(() {
    registerFallbackValue(ChatConversationScreenPageRoute());
    registerFallbackValue(ContactSourceType.external);
  });

  setUp(() {
    chats = _MockChatConversationsCubit();
    messaging = _MockMessagingBloc();
    unread = _MockUnreadCountCubit();
    contacts = _MockContactsRepository();
    router = _MockStackRouter();
    when(() => router.navigate(any(), onFailure: any(named: 'onFailure'))).thenAnswer((_) async {});
    when(
      () =>
          contacts.watchContactBySourceWithPhonesAndEmails(any(), any(), fetchIfMissing: any(named: 'fetchIfMissing')),
    ).thenAnswer((_) => Stream.value(null));
    when(() => unread.state).thenReturn(UnreadCountState.initial());
    connection(ConnectionStatus.connected);
  });

  void shown(
    List<ChatWithMessageAndMemebers> list, {
    List<ChatWithMessageAndMemebers>? toShow,
    bool initialising = false,
  }) {
    whenListen(
      chats,
      const Stream<ChatConversationsState>.empty(),
      initialState: ChatConversationsState(list, toShow ?? list, initialising),
    );
  }

  final list = <ChatWithMessageAndMemebers>[
    (chat: _chat(1, type: ChatType.group, name: 'Team'), message: _message(1, 'See you at five'), contacts: const []),
    (chat: _chat(2), message: null, contacts: const []),
  ];

  Widget app({
    String query = '',
    ValueChanged<ConversationsTab>? onSelected,
    VoidCallback? onNew,
    List<ConversationsTab> tabs = const [ConversationsTab.chat, ConversationsTab.sms],
  }) {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: PresenceViewParams(
              hybridPresenceSupport: false,
              blfViaSipSupport: false,
              presenceViaSipSupport: false,
              child: RepositoryProvider<ContactsRepository>.value(
                value: contacts,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<ChatConversationsCubit>.value(value: chats),
                    BlocProvider<MessagingBloc>.value(value: messaging),
                    BlocProvider<UnreadCountCubit>.value(value: unread),
                  ],
                  child: Scaffold(
                    body: ConversationsWatchBody(
                      section: WatchSection(
                        title: 'Chats',
                        options: tabs,
                        selected: ConversationsTab.chat,
                        onSelected: onSelected ?? (_) {},
                      ),
                      query: query,
                      onSearch: (_) {},
                      onNew: onNew ?? () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the chats are rows under one row of search and the list pill', (tester) async {
      preset.apply(tester);
      shown(list);
      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.text('Chats'), findsOneWidget);
      expect(find.bySemanticsIdentifier(conversationsSearchInputId), findsOneWidget);
      expect(find.bySemanticsIdentifier(conversationsWatchListId), findsOneWidget);
      expect(find.byType(WatchSeparator), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('See you at five'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('on $preset no conversations is a state page with the pill and New chat on the edge', (tester) async {
      preset.apply(tester);
      shown(const []);
      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.text('No conversations started yet'), findsOneWidget);
      expect(find.bySemanticsIdentifier(conversationsWatchListId), findsOneWidget);
      expect(find.bySemanticsIdentifier(conversationsNewId), findsOneWidget);
    });
  }

  testWidgets('the unread count is the row end mark and is said after the row', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(list);
    when(() => unread.state).thenReturn(UnreadCountState.fromCountPerChat({1: 3}, {}));
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byType(CountBadge), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Team, See you at five, .*3')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a tap on a row opens the conversation', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(list);
    await tester.pumpWidget(app());
    await tester.pump();

    await tapViaSemantics(tester, find.bySemanticsLabel('Team, See you at five'));

    verify(() => router.navigate(ChatConversationScreenPageRoute(chatId: 1), onFailure: any(named: 'onFailure')))
        .called(1);
    handle.dispose();
  });

  testWidgets('New chat closes the list, and the pill shows the other list', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(list);
    var started = 0;
    ConversationsTab? selected;
    await tester.pumpWidget(app(onNew: () => started++, onSelected: (tab) => selected = tab));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.bySemanticsIdentifier(conversationsNewId),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tapViaSemantics(tester, find.bySemanticsIdentifier(conversationsNewId));
    expect(started, 1);

    await tester.scrollUntilVisible(
      find.bySemanticsIdentifier(conversationsWatchListId),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    // Said as what it is, as the contacts' source pill.
    expect(find.bySemanticsLabel('List: Messages'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(conversationsWatchListId));
    expect(selected, ConversationsTab.sms);
    handle.dispose();
  });

  testWidgets('with one list there is no pill: the search takes the row', (tester) async {
    watchPresets.first.apply(tester);
    shown(list);
    await tester.pumpWidget(app(tabs: const [ConversationsTab.chat]));
    await tester.pump();

    expect(find.bySemanticsIdentifier(conversationsWatchListId), findsNothing);
    expect(find.text('Search chats'), findsOneWidget);
  });

  testWidgets('on its way the list says how the chat connection stands', (tester) async {
    watchPresets.first.apply(tester);
    shown(const [], initialising: true);
    connection(ConnectionStatus.connecting);
    await tester.pumpWidget(app());

    expect(find.byType(WatchSpinner), findsOneWidget);
    expect(find.text('Connecting to chats'), findsOneWidget);
  });

  testWidgets('a search that finds nothing stays the list, a line saying so', (tester) async {
    watchPresets.first.apply(tester);
    shown(list, toShow: const []);
    await tester.pumpWidget(app(query: 'zz'));
    await tester.pump();

    expect(find.text('No conversations found'), findsOneWidget);
    expect(find.bySemanticsIdentifier(conversationsSearchInputId), findsOneWidget);
    expect(find.bySemanticsIdentifier(conversationsNewId), findsNothing);
  });

  testWidgets('the query cleared before the lists narrow back stays the list, not the empty page', (tester) async {
    watchPresets.first.apply(tester);
    // The lists narrow a moment after the query changes: the query is gone,
    // the rows the last search left are still none.
    shown(list, toShow: const []);
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('No conversations started yet'), findsNothing);
    expect(find.bySemanticsIdentifier(conversationsSearchInputId), findsOneWidget);
    expect(find.text('No conversations found'), findsOneWidget);
  });
}
