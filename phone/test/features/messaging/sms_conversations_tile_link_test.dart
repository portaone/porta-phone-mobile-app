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

class _MockSmsRepository extends Mock implements SmsRepository {}

class _MockUnreadCountCubit extends MockCubit<UnreadCountState> implements UnreadCountCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

/// The last message under a conversation row is a preview of the conversation, not a message to
/// act on: a tap anywhere on the row, the link included, opens the conversation.
void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  late List<String> launched;
  late StackRouter router;

  setUpAll(() => registerFallbackValue(SmsConversationScreenPageRoute(firstNumber: '', secondNumber: '')));

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
    final smsRepository = _MockSmsRepository();
    when(smsRepository.watchUserSmsNumbers).thenAnswer((_) => Stream.value(const ['+380000000001']));

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
            child: RepositoryProvider<SmsRepository>.value(
              value: smsRepository,
              child: BlocProvider<UnreadCountCubit>.value(
                value: unreadCount,
                child: Scaffold(
                  body: SmsConversationsTile(
                    conversation: SmsConversation(
                      id: 1,
                      firstPhoneNumber: '+380000000001',
                      secondPhoneNumber: '+380000000002',
                      createdAt: now,
                      updatedAt: now,
                    ),
                    lastMessage: SmsMessage(
                      id: 1,
                      idKey: 'k1',
                      externalId: null,
                      conversationId: 1,
                      fromPhoneNumber: '+380000000002',
                      toPhoneNumber: '+380000000001',
                      sendingStatus: SmsSendingStatus.delivered,
                      content: lastMessage,
                      createdAt: now,
                      updatedAt: now,
                      deletedAt: null,
                    ),
                    userId: 'u1',
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
}
