import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../../../helpers/helpers.dart';
import 'sessions_auto_terminate_harness.dart';

void main() {
  const sessions = [
    ActiveSession(id: 'a', current: true, userAgent: 'PortaPhone/1.18.0+0 (Google Pixel 9; Android: 17)'),
    ActiveSession(id: 'b', current: false, userAgent: 'PortaPhone/1.18.0+0 (Redmi 9A; Android: 10)'),
    ActiveSession(id: 'c', current: false, userAgent: 'PortaPhone/1.18.0+0 (iPhone 12 mini; iOS: 27.0.1)'),
  ];

  testWidgets('every device is a row told apart by its place, and every other device by its sign-out', (tester) async {
    await SessionsAutoTerminateHarness(null, sessions: sessions).pump(tester);
    final handle = tester.ensureSemantics();

    expect(find.bySemanticsIdentifier(sessionsCurrentTileId), findsOneWidget);
    expect(find.bySemanticsIdentifier(sessionsTileId), findsOneWidget);
    expect(find.bySemanticsIdentifier(numberedId(sessionsTileId, 1)), findsOneWidget);
    for (final index in [0, 1]) {
      final id = numberedId(sessionsTileRevokeButtonId, index);
      expectTapTargetSemantics(tester, find.bySemanticsIdentifier(id), label: 'Sign out', identifier: id);
    }
    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(sessionsRevokeAllOthersButtonId),
      label: 'Sign out other sessions',
      identifier: sessionsRevokeAllOthersButtonId,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('signing a device out through semantics asks first and then drops its row', (tester) async {
    final harness = SessionsAutoTerminateHarness(null, sessions: sessions);
    await harness.pump(tester);
    final handle = tester.ensureSemantics();

    await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsTileRevokeButtonId));
    await tester.pumpAndSettle();
    expect(find.text('Sign out this session?'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Redmi 9A'), findsNothing);
    expect(find.text('iPhone 12 mini'), findsOneWidget);

    handle.dispose();
  });
}
