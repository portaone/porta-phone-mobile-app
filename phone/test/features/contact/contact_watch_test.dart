import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/contact/contact.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';
import 'contact_screen_harness.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const CallControlEvent.started(video: false));
    registerFallbackValue(CallLogScreenPageRoute(number: ''));
  });

  final contact = buildContact(
    numbers: [
      ContactPhone(id: 1, number: '1001', label: 'ext', favorite: false),
      ContactPhone(id: 2, number: '+380441234567', label: 'mobile', favorite: false),
    ],
    emails: [ContactEmail(id: 1, address: 'anna@example.com', label: 'work')],
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset the name, a row per number, the actions and the addresses above the call', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      final harness = ContactScreenHarness();

      await harness.pump(tester, contact: contact);

      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ContactWatchView), findsOneWidget);
      final name = tester.getRect(find.text('Anna Marchenko'));
      final first = tester.getRect(find.text('1001'));
      expect(name.bottom, lessThanOrEqualTo(first.top));
      expect(find.bySemanticsIdentifier(contactWatchCallId), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsIdentifier(contactWatchCallId)).getSemanticsData().label, 'Call 1001');

      final list = find.byType(Scrollable).last;
      for (final label in ['+380441234567', 'Video call', 'Message', 'History', 'Favorites', 'anna@example.com']) {
        await tester.scrollUntilVisible(find.text(label), 40, scrollable: list);
        expect(find.text(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });

    testWidgets('on $preset the edge calls the first number', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      final harness = ContactScreenHarness();
      await harness.pump(tester, contact: contact);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(contactWatchCallId));
      verify(
        () => harness.callBloc.add(
          const CallControlEvent.started(number: '1001', displayName: 'Anna Marchenko', video: false),
        ),
      ).called(1);

      handle.dispose();
    });

    testWidgets('on $preset a row of another number calls that number', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      final harness = ContactScreenHarness();
      await harness.pump(tester, contact: contact);

      final second = find.text('+380441234567');
      await tester.scrollUntilVisible(second, 40, scrollable: find.byType(Scrollable).last);
      await tester.ensureVisible(second);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsIdentifier(numberedId(contactPhoneVoiceCallId, 1)))
            .getSemanticsData()
            .label,
        'Call +380441234567',
      );
      await tester.tap(second);
      await tester.pump();
      verify(
        () => harness.callBloc.add(
          const CallControlEvent.started(number: '+380441234567', displayName: 'Anna Marchenko', video: false),
        ),
      ).called(1);
      handle.dispose();
    });
  }

  testWidgets('History opens the main number\'s calls and the favourite is filed for it', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    final harness = ContactScreenHarness();
    await harness.pump(tester, contact: contact);
    final list = find.byType(Scrollable).last;

    await tester.scrollUntilVisible(find.text('History'), 40, scrollable: list);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactWatchCallLogId));
    final route = verify(() => harness.router.navigate(captureAny())).captured.single as CallLogScreenPageRoute;
    expect(route.args?.number, '1001');

    await tester.scrollUntilVisible(find.text('Favorites'), 40, scrollable: list);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactPhoneTileFavIconId));
    verify(() => harness.contactBloc.add(ContactAddedToFavorites(contact.phones.first, contact))).called(1);
    handle.dispose();
  });

  testWidgets('while somebody is being chosen the numbers choose and the call actions are gone', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    final harness = ContactScreenHarness()..withBlindTransferUnderWay();
    await harness.pump(tester, contact: contact);

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(contactWatchCallId)).getSemanticsData().label,
      'Transfer current call to 1001',
    );
    expect(find.text('Video call'), findsNothing);
    expect(find.text('Message'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(contactPhoneTransferId)).getSemanticsData().label,
      'Transfer current call to 1001',
    );

    // Each number is named by what choosing it does, not by the main one.
    await tester.scrollUntilVisible(find.text('+380441234567'), 40, scrollable: find.byType(Scrollable).last);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(numberedId(contactPhoneTransferId, 1))).getSemanticsData().label,
      'Transfer current call to +380441234567',
    );
    handle.dispose();
  });
}
