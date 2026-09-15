import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../view/call_active_scaffold_harness.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  final active = makeCall(callId: 'active', acceptedTime: DateTime(2024), displayName: 'Boris Klein');
  final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');

  testWidgets('a single call gets the central info block', (tester) async {
    await tester.pumpWidget(wrap(CallInfoBlock(activeCalls: [active], focusedCall: active, onCallSelected: (_) {})));

    expect(find.byType(CallInfo), findsOneWidget);
    expect(find.byType(CallList), findsNothing);
    expect(find.text('Boris Klein'), findsOneWidget);
    expect(find.text(kHandle.value), findsOneWidget);
  });

  testWidgets('several calls get the roster instead, and a row tap reports its call', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      wrap(CallInfoBlock(activeCalls: [active, held], focusedCall: active, onCallSelected: selected.add)),
    );

    expect(find.byType(CallList), findsOneWidget);
    expect(find.byType(CallRow), findsNWidgets(2));
    expect(find.byType(CallInfo), findsNothing);

    await tester.tap(find.byKey(const ValueKey('CallRow-held')));
    expect(selected, ['held']);
  });

  testWidgets('a room takes the roster\'s place, and calls outside it keep their rows', (tester) async {
    final outside = makeCall(callId: 'outside', acceptedTime: DateTime(2024), displayName: 'Dana Ruiz');
    const room = ConferenceState(room: 7, phase: ConferencePhase.active, legs: {'active': 0, 'held': 1});

    await tester.pumpWidget(
      wrap(
        CallInfoBlock(
          activeCalls: [active, held, outside],
          focusedCall: active,
          onCallSelected: (_) {},
          conference: room,
        ),
      ),
    );

    // The legs are one conversation now, not calls to choose between.
    expect(find.byType(ConferencePanel), findsOneWidget);
    expect(find.byKey(const ValueKey('CallRow-active')), findsNothing);
    expect(find.byKey(const ValueKey('CallRow-held')), findsNothing);
    expect(find.byKey(const ValueKey('CallRow-outside')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the calls outside a room are offered to it, and say they are outside', (tester) async {
    final outside = makeCall(callId: 'outside', acceptedTime: DateTime(2024), displayName: 'Dana Ruiz');
    const room = ConferenceState(room: 7, phase: ConferencePhase.active, legs: {'active': 0, 'held': 1});
    var added = 0;

    await tester.pumpWidget(
      wrap(
        CallInfoBlock(
          activeCalls: [active, held, outside],
          focusedCall: active,
          onCallSelected: (_) {},
          conference: room,
          onAddPressed: () => added++,
        ),
      ),
    );
    final context = tester.element(find.byType(CallInfoBlock));

    expect(find.text(context.l10n.call_CallList_outsideHeader(1).toUpperCase()), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier(callAddToConferenceButtonId));
    expect(added, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the control is disabled while nothing outside the room can join it', (tester) async {
    final ringing = makeCall(callId: 'outside', processingStatus: CallProcessingStatus.incomingFromOffer);
    const room = ConferenceState(room: 7, phase: ConferencePhase.active, legs: {'active': 0, 'held': 1});

    await tester.pumpWidget(
      wrap(
        CallInfoBlock(
          activeCalls: [active, held, ringing],
          focusedCall: active,
          onCallSelected: (_) {},
          conference: room,
        ),
      ),
    );

    // Visible so the control does not come and go as the call is answered.
    final context = tester.element(find.byType(CallInfoBlock));
    expect(find.bySemanticsIdentifier(callAddToConferenceButtonId), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, context.l10n.call_CallList_add)).onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a room with nothing outside it shows no roster at all', (tester) async {
    const room = ConferenceState(room: 7, phase: ConferencePhase.active, legs: {'active': 0, 'held': 1});
    await tester.pumpWidget(
      wrap(CallInfoBlock(activeCalls: [active, held], focusedCall: active, onCallSelected: (_) {}, conference: room)),
    );

    expect(find.byType(ConferencePanel), findsOneWidget);
    expect(find.byType(CallList), findsNothing);
    expect(find.byType(CallInfo), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the info lines keep their explicit center by default and range to the start on demand', (tester) async {
    await tester.pumpWidget(wrap(CallInfoBlock(activeCalls: [active], focusedCall: active, onCallSelected: (_) {})));

    // The name and number were always explicitly centered - wrapped lines
    // included - and must stay that way on the default path.
    expect(tester.widget<Text>(find.text('Boris Klein')).textAlign, TextAlign.center);
    expect(tester.widget<Text>(find.text(kHandle.value)).textAlign, TextAlign.center);

    await tester.pumpWidget(
      wrap(
        CallInfoBlock(activeCalls: [active], focusedCall: active, onCallSelected: (_) {}, textAlign: TextAlign.start),
      ),
    );

    expect(tester.widget<Text>(find.text('Boris Klein')).textAlign, TextAlign.start);
  });
}
