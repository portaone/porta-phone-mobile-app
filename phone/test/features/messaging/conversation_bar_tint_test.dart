import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/messaging/features/chat_conversation/view/conversation_screen.dart';
import 'package:webtrit_phone/features/messaging/features/conversations/view/conversations_screen_style.dart';
import 'package:webtrit_phone/features/messaging/features/conversations/view/conversations_screen_styles.dart';
import 'package:webtrit_phone/features/messaging/features/sms_conversation/view/sms_conversation_screen.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'conversation_screen_harness.dart';

void main() {
  late ConversationScreenHarness harness;

  setUp(() => harness = ConversationScreenHarness());

  const tint = Color(0x96123456);

  ThemeData themeWith(BlurredSurfaceStyle? appBarBlurredSurface) => ThemeData(
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xCA50173F)),
    extensions: [
      ConversationsScreenStyles(primary: ConversationsScreenStyle(appBarBlurredSurface: appBarBlurredSurface)),
    ],
  );

  Finder barSurface() => find.descendant(of: find.byType(AppBar), matching: find.byType(BlurredSurface));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // A thread belongs to the conversations section. Its bar used to lay a
  // fixed surface tint over any bar that was not opaque, whatever the theme
  // gave the section - a brand that took the tint off the conversations list
  // still got it on every thread, and the brand's bar colour washed out there.
  for (final (name, screen, arrange) in [
    ('a chat', const ChatConversationScreen() as Widget, (ConversationScreenHarness h) => h.withDialogLoading()),
    (
      'an SMS thread',
      const SmsConversationScreen() as Widget,
      (ConversationScreenHarness h) => h.withSmsConversation(),
    ),
  ]) {
    group(name, () {
      testWidgets('frosts its bar with the tint of the conversations page', (tester) async {
        arrange(harness);
        await tester.pumpWidget(harness.wrap(screen, theme: themeWith(const BlurredSurfaceStyle(color: tint))));
        await settle(tester);

        expect(tester.widget<BlurredSurface>(barSurface()).color, tint);
      });

      testWidgets('lays nothing over the bar when that page style has no tint', (tester) async {
        arrange(harness);
        await tester.pumpWidget(harness.wrap(screen, theme: themeWith(null)));
        await settle(tester);

        expect(barSurface(), findsNothing);
      });
    });
  }
}
