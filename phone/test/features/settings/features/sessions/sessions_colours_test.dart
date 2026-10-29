import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';

import 'sessions_auto_terminate_harness.dart';

void main() {
  const sessions = [
    ActiveSession(id: 'a', current: true, userAgent: 'PortaPhone/1.18.0+0 (Google Pixel 9; Android: 17)'),
    ActiveSession(id: 'b', current: false, userAgent: 'PortaPhone/1.18.0+0 (Redmi 9A; Android: 10)'),
  ];

  testWidgets('signing every other device out is drawn in the red of signing one out', (tester) async {
    // Both end sessions on other devices; a pale container tone for the one
    // that ends all of them read as a disabled button under the red icons.
    await SessionsAutoTerminateHarness(null, sessions: sessions).pump(tester);

    final all = find.descendant(
      of: find.bySemanticsIdentifier(sessionsRevokeAllOthersButtonId),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    final colorScheme = Theme.of(tester.element(all)).colorScheme;
    final style = tester.widget<FilledButton>(all).style!;
    final one = tester.widget<IconButton>(
      find.descendant(of: find.bySemanticsIdentifier(sessionsTileRevokeButtonId), matching: find.byType(IconButton)),
    );

    expect(one.color, colorScheme.error);
    expect(style.backgroundColor?.resolve({}), colorScheme.error);
    expect(style.foregroundColor?.resolve({}), colorScheme.onError);
  });

  testWidgets('signing every other device out waits while one is being signed out', (tester) async {
    // Pressed then, it would ask the core for that device a second time.
    final harness = SessionsAutoTerminateHarness(null, sessions: sessions);
    await harness.pump(tester);
    harness.repository.revokeGate = Completer<void>();

    await tester.tap(find.bySemanticsIdentifier(sessionsTileRevokeButtonId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pump();

    FilledButton all() => tester.widget<FilledButton>(
      find.descendant(
        of: find.bySemanticsIdentifier(sessionsRevokeAllOthersButtonId),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(all().onPressed, isNull);

    harness.repository.revokeGate!.complete();
    await tester.pumpAndSettle();
  });
}
