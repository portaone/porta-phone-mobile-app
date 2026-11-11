import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/features/messaging/features/chat_conversation_builder/chat_conversation_builder.dart';
import 'package:webtrit_phone/features/messaging/features/sms_conversation_builder/sms_conversation_builder.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';

class _MockChatBuilder extends MockCubit<ChatCBState> implements ChatConversationBuilderCubit {}

class _MockSmsBuilder extends MockCubit<SmsCBState> implements SmsConversationBuilderCubit {}

Contact _contact(int id, String name, {String? extension, List<String> sms = const []}) => Contact(
  id: id,
  sourceType: ContactSourceType.external,
  sourceId: 'c$id',
  kind: ContactKind.visible,
  aliasName: name,
  phones: [
    if (extension != null) ContactPhone(id: id * 10 + 9, number: extension, label: kContactExtLabel, favorite: false),
    for (final (index, number) in sms.indexed)
      ContactPhone(id: id * 10 + index, number: number, label: kContactSmsLabel, favorite: false),
  ],
);

/// The page's list, not the scrollable inside the search row's hidden field.
Finder _list() => find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).first;

void main() {
  final agent = _contact(1, 'Agent Smith', extension: '1001');
  final jane = _contact(2, 'Jane Smith', sms: ['+12025550143', '+12025550144']);

  late _MockChatBuilder chat;
  late _MockSmsBuilder sms;

  setUpAll(() => registerFallbackValue(agent));

  setUp(() {
    chat = _MockChatBuilder();
    sms = _MockSmsBuilder();
  });

  Widget app(Widget page) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ChatConversationBuilderCubit>.value(value: chat),
        BlocProvider<SmsConversationBuilderCubit>.value(value: sms),
      ],
      child: page,
    ),
  );

  void chatIn(ChatCBState state) => whenListen(chat, const Stream<ChatCBState>.empty(), initialState: state);

  group('New chat', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the search pill, Create group, the contacts with their extension', (tester) async {
        preset.apply(tester);
        chatIn(ChatCBDialogContactSelection([agent]));
        expect(await pumpCollectingOverflows(tester, app(const ChatConversationBuilderWatch())), isEmpty);

        expect(find.text('New chat'), findsOneWidget);
        expect(find.byType(WatchSearchRow), findsOneWidget);
        expect(find.text('Create group'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Agent Smith'), 40, scrollable: _list());
        expect(find.text('Ext: 1001'), findsOneWidget);
      });
    }

    testWidgets('a contact opens the chat; Create group goes to the members', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBDialogContactSelection([agent]));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

      await tester.tap(find.text('Create group'));
      verify(() => chat.onGroupCreateStageChoosen()).called(1);
      await tester.scrollUntilVisible(find.text('Agent Smith'), 40, scrollable: _list());
      await tester.tap(find.text('Agent Smith'));
      verify(() => chat.onDialogCreateConfirm(agent)).called(1);
    });

    testWidgets('members: a picked one is tinted with a tick, Next counts them; Back steps back', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupContactsSelection([agent, jane], selectedContacts: {agent}));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

      expect(find.text('Create group'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Agent Smith'), 40, scrollable: _list());
      expect(tester.widget<WatchListTile>(find.widgetWithText(WatchListTile, 'Agent Smith')).selected, isTrue);
      expect(find.textContaining('Next (1)'), findsOneWidget);

      await tester.tap(find.textContaining('Next (1)'));
      verify(() => chat.onGroupFillInfoStageChoosen()).called(1);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      verify(() => chat.onBackToPrevStage()).called(1);
    });

    testWidgets('no member picked: no Next', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupContactsSelection([agent]));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

      expect(find.byType(WatchEdgeButton), findsNothing);
    });

    testWidgets('the name: Create waits for three characters', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupFillInfo([agent], {agent}, name: 'Ab'));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));
      expect(find.widgetWithText(WatchPillButton, 'Ab'), findsOneWidget);
      final create = tester.widget<OutlinedButton>(
        find.descendant(of: find.byType(WatchEdgeButton), matching: find.byType(OutlinedButton)),
      );
      expect(create.onPressed, isNull);
    });

    testWidgets('the name is counted as the phone counts it, spaces and all', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupFillInfo([agent], {agent}, name: 'Ab '));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));
      final create = tester.widget<OutlinedButton>(
        find.descendant(of: find.byType(WatchEdgeButton), matching: find.byType(OutlinedButton)),
      );
      expect(create.onPressed, isNotNull);
    });

    testWidgets('while the group is made: a spinner over the stage, Back waits', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupFillInfo([agent], {agent}, name: 'Sales', processing: true));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

      expect(find.byType(WatchSpinner), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      verifyNever(() => chat.onBackToPrevStage());
    });

    testWidgets('a name long enough lets Create make the group', (tester) async {
      watchPresets.last.apply(tester);
      chatIn(ChatCBGroupFillInfo([agent], {agent}, name: 'Sales'));
      await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

      await tester.tap(find.text('Create'));
      verify(() => chat.onGroupCreateConfirm()).called(1);
    });
  });

  group('New SMS', () {
    void smsIn(SmsCBState state) => whenListen(sms, const Stream<SmsCBState>.empty(), initialState: state);

    for (final preset in watchPresets) {
      testWidgets('on $preset a typed number first, then a row per SMS number of each contact', (tester) async {
        preset.apply(tester);
        smsIn(SmsCBCommon([jane], searchFilter: '+1202555', parsedNumber: '+12025550100'));
        expect(await pumpCollectingOverflows(tester, app(const SmsConversationBuilderWatch())), isEmpty);

        expect(find.text('New chat'), findsOneWidget);
        expect(find.text('+12025550100'), findsOneWidget);
        final list = _list();
        await tester.scrollUntilVisible(find.text('+12025550143'), 40, scrollable: list);
        await tester.scrollUntilVisible(find.text('+12025550144'), 40, scrollable: list);
      });
    }

    testWidgets('the typed number and a contact\'s number start the conversation', (tester) async {
      watchPresets.last.apply(tester);
      smsIn(SmsCBCommon([jane], parsedNumber: '+12025550100'));
      await tester.pumpWidget(app(const SmsConversationBuilderWatch()));

      await tester.tap(find.text('+12025550100'));
      verify(() => sms.onConfirmByParsedNumber()).called(1);
      await tester.scrollUntilVisible(find.text('+12025550143'), 40, scrollable: _list());
      await tester.tap(find.text('+12025550143'));
      verify(() => sms.onConfirm('+12025550143', 'c2')).called(1);
    });

    testWidgets('several numbers of the user\'s own: a page to pick one', (tester) async {
      watchPresets.last.apply(tester);
      final common = SmsCBCommon([jane]);
      whenListen(
        sms,
        Stream<SmsCBState>.value(
          SmsCBUserNumberConfirmationNeeded(
            common,
            (number: '+12025550143', id: 'c2'),
            ['+380441111111', '+380442222222'],
          ),
        ),
        initialState: common,
      );
      await tester.pumpWidget(app(const SmsConversationBuilderWatch()));
      await tester.pumpAndSettle();

      expect(find.text('+380441111111'), findsOneWidget);
      await tester.tap(find.text('+380442222222'));
      await tester.pumpAndSettle();
      verify(() => sms.onConfirmUserNumber('+380442222222')).called(1);
    });

    testWidgets('digits that are no number: the format it takes', (tester) async {
      watchPresets.last.apply(tester);
      smsIn(SmsCBCommon(const [], searchFilter: '1234567'));
      await tester.pumpWidget(app(const SmsConversationBuilderWatch()));

      expect(find.textContaining('The entered phone number is invalid'), findsOneWidget);
    });

    testWidgets('no contacts and no number: a line says so', (tester) async {
      watchPresets.last.apply(tester);
      smsIn(SmsCBCommon(const []));
      await tester.pumpWidget(app(const SmsConversationBuilderWatch()));

      expect(find.text('There are no contacts matching the search result'), findsOneWidget);
    });
  });
}
