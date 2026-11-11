import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/features/messaging/widgets/message_list_view/conversation_layout.dart';
import 'package:webtrit_phone/features/messaging/widgets/message_list_view/message_text_field.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import 'conversation_screen_harness.dart';

const _newest = Key('newest message');
const _bar = Key('bar');
const _above = Key('above the field');

/// Counts how many times a message of the list was built.
class _Message extends StatelessWidget {
  const _Message(this.text, {required this.builds, super.key});

  final String text;
  final ValueNotifier<int> builds;

  @override
  Widget build(BuildContext context) {
    builds.value++;
    return SizedBox(height: 40, child: Text(text));
  }
}

/// A conversation as the two message lists build it: the newest message at
/// the bottom of a reversed list that sets no padding of its own.
Widget _list(ValueNotifier<int> builds) {
  return ListView(
    reverse: true,
    children: [
      _Message('newest', builds: builds, key: _newest),
      for (var i = 0; i < 30; i++) _Message('older $i', builds: builds),
    ],
  );
}

void main() {
  late MockMessagingBloc messagingBloc;
  late TextEditingController controller;
  late ValueNotifier<double> above;
  late ValueNotifier<int> builds;
  late Widget list;

  setUp(() {
    messagingBloc = MockMessagingBloc();
    when(() => messagingBloc.state).thenReturn(
      MessagingState.initial(
        'user-1',
        MockPhoenixSocket(),
        const MessagingConfig(
          coreSmsSupport: true,
          coreChatsSupport: true,
          tabEnabled: true,
          groupChatSupport: true,
          contactInfoVideoCallSupport: true,
        ),
        // Connected, so the notice of a connection under way - which never
        // stops moving - is not shown.
      ).copyWith(status: ConnectionStatus.connected),
    );
    controller = TextEditingController();
    above = ValueNotifier(0);
    builds = ValueNotifier(0);
    // Built once, as a message list builds its own on a change of its state.
    list = _list(builds);
  });

  tearDown(() {
    builds.dispose();
    above.dispose();
    controller.dispose();
  });

  /// The layout inside a screen's scaffold, on a phone with [systemBottom] of
  /// system navigation under it. The bar is the real message field with a box
  /// of the height in [above] over it - the place of a quoted message.
  Future<void> pump(
    WidgetTester tester, {
    double systemBottom = 0,
    double keyboard = 0,
    bool scrolledAway = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: systemBottom),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: BlocProvider<MessagingBloc>.value(
            value: messagingBloc,
            child: Scaffold(
              // With a keyboard up, a screen that does not move for it: what
              // the layout does about the keyboard then shows as its own.
              resizeToAvoidBottomInset: keyboard == 0,
              body: ConversationLayout(
                list: list,
                scrolledAway: scrolledAway,
                onScrollToBottom: () {},
                bar: Column(
                  key: _bar,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: above,
                      builder: (context, height, _) => SizedBox(key: _above, height: height),
                    ),
                    MessageTextField(controller: controller, onSend: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double barTop(WidgetTester tester) => tester.getTopLeft(find.byKey(_bar)).dy;
  double newestBottom(WidgetTester tester) => tester.getBottomLeft(find.byKey(_newest)).dy;

  testWidgets('the newest message sits right above an empty field', (tester) async {
    await pump(tester);

    expect(newestBottom(tester), barTop(tester));
  });

  testWidgets('the newest message moves up as the field grows by lines', (tester) async {
    await pump(tester);
    final oneLine = barTop(tester);

    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pumpAndSettle();

    // The field did grow - otherwise the line below would hold for nothing.
    expect(barTop(tester), lessThan(oneLine));
    expect(newestBottom(tester), barTop(tester));
  });

  testWidgets('the newest message comes back down once the text is gone', (tester) async {
    await pump(tester);
    final oneLine = barTop(tester);
    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pumpAndSettle();

    controller.text = '';
    await tester.pumpAndSettle();

    expect(barTop(tester), oneLine);
    expect(newestBottom(tester), oneLine);
  });

  testWidgets('the newest message clears what a conversation puts above the field', (tester) async {
    await pump(tester);
    final oneLine = barTop(tester);

    above.value = 56;
    await tester.pumpAndSettle();

    expect(barTop(tester), oneLine - 56);
    expect(newestBottom(tester), barTop(tester));
  });

  testWidgets('the bar stands above the system navigation and the list above the bar', (tester) async {
    await pump(tester, systemBottom: 34);

    expect(tester.getBottomLeft(find.byKey(_bar)).dy, tester.getSize(find.byType(ConversationLayout)).height - 34);
    expect(newestBottom(tester), barTop(tester));
  });

  testWidgets('the way back to the newest message stays above a grown bar', (tester) async {
    await pump(tester, scrolledAway: true);
    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pumpAndSettle();

    final button = tester.getRect(find.byIcon(Icons.expand_circle_down_outlined));
    expect(button.bottom, lessThan(barTop(tester)));
  });
  testWidgets('a bar that changes height does not build the messages again', (tester) async {
    // The list holds every loaded message, and the bar changes height on
    // each frame of the quoted message sliding in above the field.
    await pump(tester);
    final built = builds.value;
    expect(built, greaterThan(0));

    above.value = 56;
    await tester.pumpAndSettle();
    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pumpAndSettle();

    expect(newestBottom(tester), barTop(tester));
    expect(builds.value, built);
  });

  testWidgets('the keyboard is left to the screen the layout is on', (tester) async {
    // The screen's scaffold is what moves a conversation above the keyboard.
    // A layout that made room for the keyboard as well would lift the bar a
    // second time - seen here on a screen that does not move at all.
    await pump(tester, keyboard: 300);

    final layout = tester.getRect(find.byType(ConversationLayout));
    expect(tester.getBottomLeft(find.byKey(_bar)).dy, layout.bottom);
    expect(newestBottom(tester), barTop(tester));
  });
}
