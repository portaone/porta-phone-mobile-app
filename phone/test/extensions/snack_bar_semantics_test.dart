import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/call.dart';

void main() {
  testWidgets('a message carries the shared id, so an assertion does not depend on its wording', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                ElevatedButton(onPressed: () => context.showSnackBar('Wrong password'), child: const Text('show')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(appSnackBarId)),
      isSemantics(identifier: appSnackBarId, label: 'Wrong password'),
    );

    handle.dispose();
  });

  testWidgets('a message a flow must tell apart carries its own id instead of the shared one', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => context.showSnackBar('Declined', identifier: notificationLinkedCallDeclinedId),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(notificationLinkedCallDeclinedId)),
      isSemantics(identifier: notificationLinkedCallDeclinedId, label: 'Declined'),
    );
    expect(find.bySemanticsIdentifier(appSnackBarId), findsNothing);

    handle.dispose();
  });

  testWidgets('the full room bar carries its own id, so a flow finds it whatever its wording', (tester) async {
    final handle = tester.ensureSemantics();
    const notification = ConferenceRoomFullNotification(limit: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => context.showSnackBar('Room full', identifier: notification.identifier!),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(notification.identifier, notificationConferenceRoomFullId);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(notificationConferenceRoomFullId)),
      isSemantics(identifier: notificationConferenceRoomFullId, label: 'Room full'),
    );
    expect(find.bySemanticsIdentifier(appSnackBarId), findsNothing);

    handle.dispose();
  });

  testWidgets('the unable-to-complete bar carries its own id, so a flow tells it from any other message', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final notification = CallUnableToCompleteNotification();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => context.showSnackBar('Unable', identifier: notification.identifier!),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(notification.identifier, notificationCallUnableToCompleteId);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(notificationCallUnableToCompleteId)),
      isSemantics(identifier: notificationCallUnableToCompleteId, label: 'Unable'),
    );
    expect(find.bySemanticsIdentifier(appSnackBarId), findsNothing);

    handle.dispose();
  });

  test('only the decline of a linked call names its own bar', () {
    expect(const LinkedCallFailedNotification(LinkedCallFailure.declined).identifier, notificationLinkedCallDeclinedId);
    expect(const LinkedCallFailedNotification(LinkedCallFailure.unanswered).identifier, isNull);
  });
}
