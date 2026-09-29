import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockUnreadCountCubit extends MockCubit<UnreadCountState> implements UnreadCountCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

/// The last message under a chat row is a preview of the conversation, not a message to act on:
/// a tap anywhere on the row, the link included, opens the conversation.
void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  late List<String> launched;
  late StackRouter router;

  setUpAll(() {
    registerFallbackValue(ChatConversationScreenPageRoute());
    registerFallbackValue(ContactSourceType.external);
  });

  setUp(() {
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'canLaunch':
          return true;
        case 'launch':
          launched.add((call.arguments as Map)['url'] as String);
          return true;
      }
      return null;
    });

    router = _MockStackRouter();
    when(() => router.navigate(any(), onFailure: any(named: 'onFailure'))).thenAnswer((_) async {});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpTile(WidgetTester tester, String lastMessage) async {
    final contacts = _MockContactsRepository();
    when(
      () =>
          contacts.watchContactBySourceWithPhonesAndEmails(any(), any(), fetchIfMissing: any(named: 'fetchIfMissing')),
    ).thenAnswer((_) => Stream.value(null));

    final unreadCount = _MockUnreadCountCubit();
    when(() => unreadCount.state).thenReturn(UnreadCountState.initial());

    final now = DateTime(2026, 9, 29, 12);

    await tester.pumpWidget(
      MaterialApp(
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
                child: BlocProvider<UnreadCountCubit>.value(
                  value: unreadCount,
                  child: Scaffold(
                    body: ChatConversationsTile(
                      conversation: Chat(
                        id: 1,
                        type: ChatType.direct,
                        name: null,
                        createdAt: now,
                        updatedAt: now,
                        members: const [
                          ChatMember(id: 1, chatId: 1, userId: 'me', groupAuthorities: null),
                          ChatMember(id: 2, chatId: 1, userId: 'peer', groupAuthorities: null),
                        ],
                      ),
                      lastMessage: ChatMessage(
                        id: 1,
                        idKey: 'k1',
                        senderId: 'peer',
                        chatId: 1,
                        replyToId: null,
                        forwardFromId: null,
                        authorId: null,
                        content: lastMessage,
                        createdAt: now,
                        updatedAt: now,
                        editedAt: null,
                        deletedAt: null,
                      ),
                      userId: 'me',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a tap on a link in the last message opens the conversation', (tester) async {
    await pumpTile(tester, 'see https://example.com');

    await tester.tapOnText(find.textRange.ofSubstring('https://example.com'));
    await tester.pumpAndSettle();

    expect(launched, isEmpty);
    verify(() => router.navigate(any(), onFailure: any(named: 'onFailure'))).called(1);
  });

  testWidgets('a tap on plain text in the last message opens the conversation', (tester) async {
    await pumpTile(tester, 'see you tomorrow');

    await tester.tapOnText(find.textRange.ofSubstring('see you'));
    await tester.pumpAndSettle();

    verify(() => router.navigate(any(), onFailure: any(named: 'onFailure'))).called(1);
  });

  testWidgets('the link is still drawn in the preview, markers removed', (tester) async {
    await pumpTile(tester, '*see* https://example.com');

    expect(find.textContaining('see https://example.com', findRichText: true), findsOneWidget);
  });
}
