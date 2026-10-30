import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../view/call_active_scaffold_harness.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Widget buildArea({
    required List<ActiveCall> activeCalls,
    required ActiveCall focusedCall,
    CallCapabilitiesConfig callConfig = const CallCapabilitiesConfig(),
    bool interactionsEnabled = true,
    VoidCallback? onHangup,
    VoidCallback? onAccept,
    ConferenceState conference = const ConferenceState(),
    LinkedCall? linkedCall,
    bool? canStartAttendedTransfer,
  }) {
    // As the screen reads it: from the state, unless a test says otherwise.
    final state = CallState(linesCount: 3, activeCalls: activeCalls, conference: conference, linkedCall: linkedCall);
    final canStart =
        canStartAttendedTransfer ??
        state.canLinkCallTo(focusedCall.callId, purpose: LinkedCallPurpose.attendedTransfer, isConferenceEnabled: true);
    return CallActionArea(
      params: CallControlsParams(
        activeCalls: activeCalls,
        focusedCall: focusedCall,
        availableAudioDevices: const [],
        callConfig: callConfig,
        interactionsEnabled: interactionsEnabled,
        remotePictureShown: false,
        dtmfInput: ValueNotifier(''),
        onCallSelected: (_) {},
        onKeypadToggle: (_) {},
        onCameraChanged: (_) {},
        onCameraPermissionDeniedPressed: () {},
        onMutedChanged: (_) {},
        onAudioDeviceChanged: (_) {},
        onBlindTransferInitiated: () {},
        onAttendedTransferInitiated: () {},
        onAttendedTransferSubmitted: (_, _) {},
        onHeldChanged: (_) {},
        onKeyPressed: (_) {},
        onHangup: onHangup ?? () {},
        onAccept: onAccept ?? () {},
        conference: conference,
        linkedCall: linkedCall,
        handOver: state.handOverFor(focusedCall.callId),
        canStartAttendedTransfer: canStart,
      ),
    );
  }

  /// The button that owns [icon] - the way to reach whether it is pressable.
  TextButton buttonWithIcon(WidgetTester tester, IconData icon) {
    return tester.widget<TextButton>(find.ancestor(of: find.byIcon(icon), matching: find.byType(TextButton)).first);
  }

  final active = makeCall(callId: 'active', acceptedTime: DateTime(2024), displayName: 'Boris Klein');
  final ringing = makeCall(
    callId: 'ringing',
    processingStatus: CallProcessingStatus.incomingFromOffer,
    displayName: 'Anna Marchenko',
  );
  final outgoingRinging = makeCall(
    callId: 'outgoing',
    direction: CallDirection.outgoing,
    processingStatus: CallProcessingStatus.outgoingCreated,
    displayName: 'Dana Weber',
  );

  group('CallActionArea - which actions are offered', () {
    testWidgets('a live focus gets the control grid, and its hangup fires the callback', (tester) async {
      var hangups = 0;
      await tester.pumpWidget(wrap(buildArea(activeCalls: [active], focusedCall: active, onHangup: () => hangups++)));

      expect(find.byType(ActiveCallActions), findsOneWidget);
      expect(find.byType(IncomingCallActions), findsNothing);

      await tester.tap(find.byIcon(Icons.call_end));
      expect(hangups, 1);
    });

    testWidgets('a ringing focus gets Decline/Answer only, with no hint while it is the only call', (tester) async {
      var accepts = 0;
      await tester.pumpWidget(wrap(buildArea(activeCalls: [ringing], focusedCall: ringing, onAccept: () => accepts++)));

      expect(find.byType(IncomingCallActions), findsOneWidget);
      expect(find.byType(ActiveCallActions), findsNothing);
      expect(find.byType(FocusedActionHint), findsNothing);

      await tester.tap(find.byIcon(Icons.call));
      expect(accepts, 1);
    });
  });

  group('CallActionArea - the hint spells the side effect of answering', () {
    testWidgets('an answered other call will be held', (tester) async {
      await tester.pumpWidget(wrap(buildArea(activeCalls: [active, ringing], focusedCall: ringing)));
      final context = tester.element(find.byType(CallActionArea));

      expect(
        find.text(context.l10n.call_FocusedActionHint_actingOn('Anna Marchenko'), findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(context.l10n.call_FocusedActionHint_willBeHeld('Boris Klein'), findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('an other call that cannot be held will be ended', (tester) async {
      // The only other call is still ringing itself - nothing to hold, so
      // answering ends it, and the hint has to say so.
      await tester.pumpWidget(wrap(buildArea(activeCalls: [outgoingRinging, ringing], focusedCall: ringing)));
      final context = tester.element(find.byType(CallActionArea));

      expect(
        find.text(context.l10n.call_FocusedActionHint_willBeEnded('Dana Weber'), findRichText: true),
        findsOneWidget,
      );
      expect(find.text(context.l10n.call_FocusedActionHint_willBeHeld('Dana Weber'), findRichText: true), findsNothing);
    });
  });

  group('CallActionArea - gating', () {
    testWidgets('answering that mutates other calls waits out the interaction debounce', (tester) async {
      await tester.pumpWidget(
        wrap(buildArea(activeCalls: [active, ringing], focusedCall: ringing, interactionsEnabled: false)),
      );

      // The button waits in place, greyed out - disappearing would shift
      // Decline into its spot at the worst possible moment.
      expect(buttonWithIcon(tester, Icons.call).onPressed, isNull);
      expect(buttonWithIcon(tester, Icons.call_end).onPressed, isNotNull);
    });

    testWidgets('answering the only call ignores the debounce - nothing else is mutated', (tester) async {
      await tester.pumpWidget(
        wrap(buildArea(activeCalls: [ringing], focusedCall: ringing, interactionsEnabled: false)),
      );

      expect(buttonWithIcon(tester, Icons.call).onPressed, isNotNull);
    });

    testWidgets('disabling video calls in the config disables the camera button', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [active],
            focusedCall: active,
            callConfig: const CallCapabilitiesConfig(isVideoCallEnabled: false),
          ),
        ),
      );

      expect(buttonWithIcon(tester, Icons.videocam_off).onPressed, isNull);
    });

    testWidgets('transfer is not offered while the focused call was never accepted', (tester) async {
      await tester.pumpWidget(wrap(buildArea(activeCalls: [outgoingRinging], focusedCall: outgoingRinging)));

      expect(buttonWithIcon(tester, Icons.phone_forwarded).onPressed, isNull);
    });

    testWidgets('a leg of the room is not offered for a transfer, nor as a target', (tester) async {
      // The other legs used to be listed as calls to hand this one to; the
      // server refuses a transfer of a leg either way.
      final other = makeCall(callId: 'other', acceptedTime: DateTime(2024), displayName: 'Clara Diaz');
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [active, other],
            focusedCall: active,
            callConfig: const CallCapabilitiesConfig(isAttendedTransferEnabled: true, isBlindTransferEnabled: true),
            conference: const ConferenceState(phase: ConferencePhase.active, legs: {'active': 0, 'other': 1}),
          ),
        ),
      );

      expect(buttonWithIcon(tester, Icons.phone_forwarded).onPressed, isNull);
    });

    testWidgets('a call next to the room is not offered the legs as transfer targets', (tester) async {
      // Focus on a call outside the room still listed the legs as calls to
      // hand it to, and the server refuses each of them.
      final legA = makeCall(callId: 'a', acceptedTime: DateTime(2024), displayName: 'Anna Leg');
      final legB = makeCall(callId: 'b', acceptedTime: DateTime(2024), displayName: 'Boris Leg');
      final outside = makeCall(callId: 'c', acceptedTime: DateTime(2024), displayName: 'Clara Outside');
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [legA, legB, outside],
            focusedCall: outside,
            callConfig: const CallCapabilitiesConfig(isAttendedTransferEnabled: true, isBlindTransferEnabled: true),
            conference: const ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1}),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.phone_forwarded));
      await tester.pumpAndSettle();

      expect(find.text('Anna Leg'), findsNothing);
      expect(find.text('Boris Leg'), findsNothing);
    });

    testWidgets('attended transfer is not offered while the call cannot have one placed for it', (tester) async {
      // Sent to the lists only to be refused on the choice - a video call,
      // every line taken, another linked call up - is worse than a disabled
      // entry; the one rule lives in the state and the screen reads it.
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [active],
            focusedCall: active,
            callConfig: const CallCapabilitiesConfig(isAttendedTransferEnabled: true, isBlindTransferEnabled: false),
            canStartAttendedTransfer: false,
          ),
        ),
      );

      expect(buttonWithIcon(tester, Icons.phone_forwarded).onPressed, isNull);
    });

    testWidgets('transfer is offered on an accepted focus', (tester) async {
      await tester.pumpWidget(wrap(buildArea(activeCalls: [active], focusedCall: active)));

      expect(buttonWithIcon(tester, Icons.phone_forwarded).onPressed, isNotNull);
    });

    testWidgets('a call to connect leaves the attended transfer to somebody else offered', (tester) async {
      // With a held call listed the menu used to drop the attended transfer,
      // so the live call could not be handed to a third person after asking.
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [held, active],
            focusedCall: active,
            callConfig: const CallCapabilitiesConfig(isAttendedTransferEnabled: true, isBlindTransferEnabled: true),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.phone_forwarded));
      await tester.pumpAndSettle();

      expect(find.byKey(callActionsTransferMenuNumberKey), findsOneWidget);
      expect(find.byKey(callActionsTransferMenuAttendedInitKey), findsOneWidget);
    });

    testWidgets('the attended transfer is left out beside a call to connect when none can start', (tester) async {
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(
        wrap(
          buildArea(
            activeCalls: [held, active],
            focusedCall: active,
            callConfig: const CallCapabilitiesConfig(isAttendedTransferEnabled: true, isBlindTransferEnabled: true),
            canStartAttendedTransfer: false,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.phone_forwarded));
      await tester.pumpAndSettle();

      expect(find.byKey(callActionsTransferMenuNumberKey), findsOneWidget);
      expect(find.byKey(callActionsTransferMenuAttendedInitKey), findsNothing);
    });
  });
}
