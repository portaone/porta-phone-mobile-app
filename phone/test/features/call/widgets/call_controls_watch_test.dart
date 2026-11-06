import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../helpers/screen_presets.dart';
import '../view/call_active_scaffold_harness.dart';
import 'call_watch_harness.dart';

void main() {
  const speaker = watchSpeaker;
  const earpiece = watchEarpiece;
  const buds = watchBuds;

  final active = watchActiveCall();
  final held = watchActiveCall(callId: 'held', name: 'Anna Ross', held: true);
  final ringing = makeCall(
    callId: 'ringing',
    processingStatus: CallProcessingStatus.incomingFromOffer,
    displayName: 'Thomas Anderson',
  );
  final outgoing = makeCall(
    callId: 'outgoing',
    direction: CallDirection.outgoing,
    processingStatus: CallProcessingStatus.outgoingRinging,
    displayName: 'Thomas Anderson',
  );

  late CallWatchSent sent;

  Widget face({
    required List<ActiveCall> calls,
    ActiveCall? focused,
    List<CallAudioDevice> devices = const [speaker, earpiece],
    CallAudioDevice? audioDevice = earpiece,
    bool keypadShown = false,
    CallCapabilitiesConfig callConfig = const CallCapabilitiesConfig(),
    ConferenceState conference = const ConferenceState(),
    bool conferenceParked = false,
    ValueChanged<bool>? onPageOpenChanged,
  }) {
    sent = CallWatchSent();
    return callWatchApp(
      callWatchFace(
        calls: calls,
        sent: sent,
        focused: focused,
        devices: devices,
        audioDevice: audioDevice,
        keypadShown: keypadShown,
        callConfig: callConfig,
        conference: conference,
        conferenceParked: conferenceParked,
        onPageOpenChanged: onPageOpenChanged,
      ),
    );
  }

  /// Puts [widget] on [preset] and says nothing overflows.
  Future<void> show(WidgetTester tester, ScreenPreset preset, Widget widget) async {
    preset.apply(tester);
    expect(await pumpCallWatch(tester, widget), isEmpty, reason: '$preset');
  }

  /// Whether the control fits the face whole.
  void onFace(WidgetTester tester, ScreenPreset preset, Finder finder) {
    final rect = tester.getRect(finder);
    final face = Offset.zero & preset.size;
    expect(
      face.contains(rect.topLeft) && face.contains(rect.bottomRight - const Offset(1, 1)),
      isTrue,
      reason: '$rect',
    );
  }

  Future<void> tapSemantics(WidgetTester tester, String identifier) async {
    await tester.tap(find.bySemanticsIdentifier(identifier));
    await tester.pumpAndSettle();
  }

  for (final preset in watchPresets) {
    group('on $preset', () {
      testWidgets('a ringing call is two equal choices', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [ringing]));

        expect(find.text('Thomas Anderson'), findsOneWidget);
        onFace(tester, preset, find.bySemanticsIdentifier(callActionsHangupId));
        onFace(tester, preset, find.bySemanticsIdentifier(callActionsAcceptId));
        expect(find.byType(WatchEdgeButton), findsNothing);

        await tapSemantics(tester, callActionsAcceptId);
        expect(sent.events, ['accept']);
        handle.dispose();
      });

      testWidgets('a ringing call over a live one says what answering does', (tester) async {
        await show(tester, preset, face(calls: [active, ringing], focused: ringing));
        expect(find.text('Thomas Anderson will be put on hold'), findsOneWidget);
      });

      testWidgets('an outgoing call is ended with the edge button', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [outgoing]));

        expect(find.text('Ringing'), findsOneWidget);
        await tapSemantics(tester, callActionsHangupId);
        expect(sent.events, ['hangup']);
        handle.dispose();
      });

      testWidgets('an answered call keeps mute, the speaker and more on the face', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [active]));

        for (final id in [callActionsMuteId, callActionsSpeakerId, callActionsOptionsId, callActionsHangupId]) {
          onFace(tester, preset, find.bySemanticsIdentifier(id));
        }
        await tapSemantics(tester, callActionsMuteId);
        await tapSemantics(tester, callActionsSpeakerId);
        expect(sent.events, ['muted true', 'audio speaker']);
        handle.dispose();
      });

      testWidgets('More is the call\'s other actions, and back returns to the call', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [active]));

        await tapSemantics(tester, callActionsOptionsId);
        for (final id in [callActionsKeypadId, callActionsHoldId, callActionsTransferMenuId, callActionsVideoCallId]) {
          onFace(tester, preset, find.bySemanticsIdentifier(id));
        }
        await tapSemantics(tester, callActionsHoldId);
        expect(sent.events, ['held true']);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.bySemanticsIdentifier(callActionsMuteId), findsOneWidget);
        handle.dispose();
      });

      testWidgets('a headset puts the devices one tap away', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [active], devices: const [buds, earpiece, speaker], audioDevice: buds));

        await tapSemantics(tester, callActionsAudioDeviceId);
        expect(find.text('Pixel Buds'), findsOneWidget);
        await tester.tap(find.text('Earpiece'));
        await tester.pumpAndSettle();
        expect(sent.events, ['audio earpiece']);
        expect(find.bySemanticsIdentifier(callActionsMuteId), findsOneWidget, reason: 'back on the call');
        handle.dispose();
      });

      testWidgets('the transfer menu sends the person to choose', (tester) async {
        final handle = tester.ensureSemantics();
        await show(tester, preset, face(calls: [active]));

        await tapSemantics(tester, callActionsOptionsId);
        await tapSemantics(tester, callActionsTransferMenuId);
        await tester.scrollUntilVisible(find.bySemanticsIdentifier(callActionsTransferMenuBlindInitId), 40);
        await tapSemantics(tester, callActionsTransferMenuBlindInitId);
        expect(sent.events, ['blind']);
        handle.dispose();
      });

      testWidgets('with two calls More lists them, and choosing one acts on it', (tester) async {
        await show(tester, preset, face(calls: [active, held]));

        await tapSemantics(tester, callActionsOptionsId);
        await tester.tap(find.byIcon(Icons.call_split));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Anna Ross'));
        await tester.pumpAndSettle();
        expect(sent.events, ['select held']);
      });

      testWidgets('the open keypad takes the face and sends tones', (tester) async {
        await show(tester, preset, face(calls: [active], keypadShown: true));

        for (final key in ['1', '5', '0', '#']) {
          onFace(tester, preset, find.text(key));
        }
        expect(find.text('205'), findsOneWidget);
        await tester.tap(find.text('5'));
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(sent.events, ['dtmf 5', 'keypad false']);
      });

      testWidgets('a room lists its participants and ends as a whole', (tester) async {
        final handle = tester.ensureSemantics();
        final legA = makeCall(callId: 'a', acceptedTime: DateTime.now(), displayName: 'Thomas Anderson');
        final legB = makeCall(callId: 'b', acceptedTime: DateTime.now(), displayName: 'Anna Ross');
        await show(
          tester,
          preset,
          face(
            calls: [legA, legB],
            callConfig: const CallCapabilitiesConfig(isConferenceEnabled: true),
            conference: const ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1}),
          ),
        );

        await tapSemantics(tester, callActionsOptionsId);
        await tester.ensureVisible(find.byIcon(Icons.groups));
        await tester.tap(find.byIcon(Icons.groups));
        await tester.pumpAndSettle();
        // Clear of the end button, as a finger would scroll it.
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Anna Ross'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel(RegExp('End the call with Anna Ross')));
        await tester.pumpAndSettle();
        expect(sent.events, ['drop b']);
        handle.dispose();
      });
    });
  }

  group('the face follows the calls', () {
    final preset = watchPresets.first;
    const room = ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1});
    const conferences = CallCapabilitiesConfig(isConferenceEnabled: true);
    final legA = makeCall(callId: 'a', acceptedTime: DateTime.now(), displayName: 'Thomas Anderson');
    final legB = makeCall(callId: 'b', acceptedTime: DateTime.now(), displayName: 'Anna Ross');
    final outside = watchActiveCall(callId: 'outside', name: 'Mary Shaw');

    Future<void> openRoom(WidgetTester tester) async {
      await tapSemantics(tester, callActionsOptionsId);
      await tester.ensureVisible(find.byIcon(Icons.groups));
      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();
    }

    testWidgets('a room standing aside is gone back to from You, a call outside it from its row', (tester) async {
      final handle = tester.ensureSemantics();
      await show(
        tester,
        preset,
        face(
          calls: [legA, legB, outside],
          focused: outside,
          callConfig: conferences,
          conference: room,
          conferenceParked: true,
        ),
      );

      await openRoom(tester);
      await tester.scrollUntilVisible(find.text('Mary Shaw'), 40, scrollable: find.byType(Scrollable).last);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mary Shaw'));
      await tester.pumpAndSettle();
      expect(sent.events, ['switch outside']);

      await openRoom(tester);
      await tapSemantics(tester, conferenceSelfMuteId);
      expect(sent.events, ['switch outside', 'switch a']);
      handle.dispose();
    });

    testWidgets('an invitation to a transfer is said while the call rings', (tester) async {
      final invited =
          makeCall(
            callId: 'invited',
            processingStatus: CallProcessingStatus.incomingFromOffer,
            displayName: 'Thomas Anderson',
          ).copyWith(
            transfer: const Transfer.inviteToAttendedTransfer(replaceCallId: 'x', referredBy: 'Anna Ross'),
          );
      await show(tester, preset, face(calls: [invited]));
      expect(find.text("You've been invited to join an attended transfer call"), findsOneWidget);
    });

    testWidgets('answering names only the calls it puts on hold', (tester) async {
      final anna = watchActiveCall(callId: 'anna', name: 'Anna Ross', held: true);
      final mary = watchActiveCall(callId: 'mary', name: 'Mary Shaw');
      final ringing = makeCall(
        callId: 'ringing',
        processingStatus: CallProcessingStatus.incomingFromOffer,
        displayName: 'Thomas Anderson',
      );
      await show(tester, preset, face(calls: [anna, mary, ringing], focused: ringing));
      expect(find.text('Mary Shaw will be put on hold'), findsOneWidget);
    });

    testWidgets('a page over the call is told to the screen, which keeps it from hiding', (tester) async {
      final open = <bool>[];
      await show(tester, preset, face(calls: [active], onPageOpenChanged: open.add));
      await tapSemantics(tester, callActionsOptionsId);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(open, [false, true, false]);
    });

    testWidgets('the calls become the room even when the merge moves the focus', (tester) async {
      await show(tester, preset, face(calls: [legA, legB], callConfig: conferences));
      await tapSemantics(tester, callActionsOptionsId);
      await tester.tap(find.byIcon(Icons.call_split));
      await tester.pumpAndSettle();

      await tester.pumpWidget(face(calls: [legA, legB], focused: legB, callConfig: conferences, conference: room));
      await tester.pumpAndSettle();

      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('a participant\'s actions carry the phone\'s numbered ids', (tester) async {
      await show(tester, preset, face(calls: [legA, legB], callConfig: conferences, conference: room));
      await openRoom(tester);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anna Ross'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(RegExp('^conferenceParticipantMute')), findsOneWidget);
      expect(find.bySemanticsIdentifier(RegExp('^conferenceParticipantHangup')), findsOneWidget);
    });

    testWidgets('a call that rings takes the face from an open page', (tester) async {
      await show(tester, preset, face(calls: [active]));
      await tapSemantics(tester, callActionsOptionsId);
      expect(find.bySemanticsIdentifier(callActionsHoldId), findsOneWidget);

      await tester.pumpWidget(face(calls: [active, ringing], focused: ringing));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(callActionsAcceptId), findsOneWidget);
      expect(find.bySemanticsIdentifier(callActionsHoldId), findsNothing);
    });

    testWidgets('back from a page opened from More returns to More', (tester) async {
      await show(tester, preset, face(calls: [active, held]));
      await tapSemantics(tester, callActionsOptionsId);
      await tester.tap(find.byIcon(Icons.call_split));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(callActionsHoldId), findsOneWidget);
    });

    testWidgets('a room that ends takes its open participant with it', (tester) async {
      await show(tester, preset, face(calls: [legA, legB], callConfig: conferences, conference: room));
      await openRoom(tester);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anna Ross'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(face(calls: [legA, legB], callConfig: conferences));
      await tester.pumpWidget(face(calls: [legA, legB], callConfig: conferences, conference: room));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(callActionsMuteId), findsOneWidget, reason: 'the call, not the participant');
    });

    testWidgets('the calls become the room once merged', (tester) async {
      await show(tester, preset, face(calls: [legA, legB], callConfig: conferences));
      await tapSemantics(tester, callActionsOptionsId);
      await tester.tap(find.byIcon(Icons.call_split));
      await tester.pumpAndSettle();

      await tester.pumpWidget(face(calls: [legA, legB], callConfig: conferences, conference: room));
      await tester.pumpAndSettle();
      expect(find.text('You'), findsOneWidget);
      expect(find.bySemanticsIdentifier(callMergeButtonId), findsNothing);
    });

    testWidgets('the calls carry the phone\'s numbered ids', (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester, preset, face(calls: [active, held]));
      await tapSemantics(tester, callActionsOptionsId);
      await tester.tap(find.byIcon(Icons.call_split));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(callRowId), findsOneWidget);
      expect(find.bySemanticsIdentifier('${callRowId}2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a transfer the deployment does not offer is left out', (tester) async {
      final handle = tester.ensureSemantics();
      await show(
        tester,
        preset,
        face(calls: [active], callConfig: const CallCapabilitiesConfig(isBlindTransferEnabled: false)),
      );
      await tapSemantics(tester, callActionsOptionsId);
      await tapSemantics(tester, callActionsTransferMenuId);
      expect(find.bySemanticsIdentifier(callActionsTransferMenuBlindInitId), findsNothing);
      expect(find.bySemanticsIdentifier(callActionsTransferMenuAttendedInitId), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a watch with a speaker only keeps its speaker control', (tester) async {
      await show(tester, preset, face(calls: [active], devices: const [speaker], audioDevice: speaker));
      final button = tester.widget<WatchRoundButton>(
        find.ancestor(of: find.byIcon(Icons.volume_up), matching: find.byType(WatchRoundButton)),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
