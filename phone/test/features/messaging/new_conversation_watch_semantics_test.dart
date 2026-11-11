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
import '../../helpers/semantics.dart';

class _MockChatBuilder extends MockCubit<ChatCBState> implements ChatConversationBuilderCubit {}

class _MockSmsBuilder extends MockCubit<SmsCBState> implements SmsConversationBuilderCubit {}

Contact _contact(int id, String name, {List<String> sms = const []}) => Contact(
  id: id,
  sourceType: ContactSourceType.external,
  sourceId: 'c$id',
  kind: ContactKind.visible,
  aliasName: name,
  phones: [
    for (final (index, number) in sms.indexed)
      ContactPhone(id: id * 10 + index, number: number, label: kContactSmsLabel, favorite: false),
  ],
);

/// The row or button holding [text]: the node assistive technology acts on.
Finder _control(String text) => find
    .ancestor(of: find.text(text), matching: find.byWidgetPredicate((w) => w is WatchListTile || w is OutlinedButton))
    .first;

/// New chat and new SMS on a watch, driven the way assistive technology does.
void main() {
  final agent = _contact(1, 'Agent Smith');
  final jane = _contact(2, 'Jane Smith', sms: ['+12025550143']);

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

  void smsIn(SmsCBState state) => whenListen(sms, const Stream<SmsCBState>.empty(), initialState: state);

  testWidgets('new chat: Create group and a contact are tapped through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    chatIn(ChatCBDialogContactSelection([agent]));
    await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

    await tapViaSemantics(tester, _control('Create group'));
    verify(() => chat.onGroupCreateStageChoosen()).called(1);

    await tapViaSemantics(tester, _control('Agent Smith'));
    verify(() => chat.onDialogCreateConfirm(agent)).called(1);
    semantics.dispose();
  });

  testWidgets('members: a contact is picked and Next is tapped through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    chatIn(ChatCBGroupContactsSelection([agent], selectedContacts: {agent}));
    await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

    await tapViaSemantics(tester, _control('Agent Smith'));
    verify(() => chat.onGroupContactDeselected(agent)).called(1);

    await tapViaSemantics(tester, _control('Next (1)'));
    verify(() => chat.onGroupFillInfoStageChoosen()).called(1);
    semantics.dispose();
  });

  testWidgets('the name: Create is tapped through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    chatIn(ChatCBGroupFillInfo([agent], {agent}, name: 'Sales'));
    await tester.pumpWidget(app(const ChatConversationBuilderWatch()));

    await tapViaSemantics(tester, _control('Create'));
    verify(() => chat.onGroupCreateConfirm()).called(1);
    semantics.dispose();
  });

  testWidgets('new SMS: the typed number and a contact\'s number are tapped through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    smsIn(SmsCBCommon([jane], parsedNumber: '+12025550100'));
    await tester.pumpWidget(app(const SmsConversationBuilderWatch()));

    await tapViaSemantics(tester, _control('+12025550100'));
    verify(() => sms.onConfirmByParsedNumber()).called(1);

    await tester.scrollUntilVisible(
      find.text('+12025550143'),
      40,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical).first,
    );
    await tapViaSemantics(tester, _control('+12025550143'));
    verify(() => sms.onConfirm('+12025550143', 'c2')).called(1);
    semantics.dispose();
  });

  testWidgets('the user\'s own number is picked through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
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

    await tapViaSemantics(tester, _control('+380442222222'));
    await tester.pumpAndSettle();
    verify(() => sms.onConfirmUserNumber('+380442222222')).called(1);
    semantics.dispose();
  });
}
