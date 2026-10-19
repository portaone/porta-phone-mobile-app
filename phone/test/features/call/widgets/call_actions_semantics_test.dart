import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/keypad_key_button.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../../helpers/helpers.dart';

final _transferableCall = ActiveCall(
  callId: 'transferable',
  direction: CallDirection.incoming,
  line: 0,
  handle: const CallkeepHandle.number('1002'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2024),
);

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Widget buildActive({
    bool enableInteractions = true,
    ValueChanged<bool>? onMutedChanged,
    ValueChanged<bool>? onHeldChanged,
    VoidCallback? onHangupPressed,
    VoidCallback? onBlindTransferInitiated,
    VoidCallback? onAttendedTransferInitiated,
    List<ActiveCall> transferableCalls = const [],
    ValueChanged<ActiveCall>? onAttendedTransferSubmitted,
    void Function(String)? onKeyPressed,
    bool mutedValue = false,
    bool keypadShown = false,
    ValueChanged<bool>? onKeypadToggle,
    AddParticipantAvailability addParticipantAvailability = AddParticipantAvailability.hidden,
    String? addParticipantPendingName,
    VoidCallback? onAddParticipant,
    VoidCallback? onAddParticipantCancelled,
    bool addParticipantIntoRoom = false,
  }) {
    return ActiveCallActions(
      keypadShown: keypadShown,
      onKeypadToggle: onKeypadToggle,
      enableInteractions: enableInteractions,
      cameraValue: false,
      dtmfInput: ValueNotifier(''),
      mutedValue: mutedValue,
      onMutedChanged: onMutedChanged,
      audioDevice: const CallAudioDevice(type: CallAudioDeviceType.earpiece),
      availableAudioDevices: const [
        CallAudioDevice(type: CallAudioDeviceType.earpiece),
        CallAudioDevice(type: CallAudioDeviceType.speaker),
      ],
      onAudioDeviceChanged: (_) {},
      transferableCalls: transferableCalls,
      onBlindTransferInitiated: onBlindTransferInitiated,
      onAttendedTransferInitiated: onAttendedTransferInitiated,
      onAttendedTransferSubmitted: onAttendedTransferSubmitted,
      heldValue: false,
      onHeldChanged: onHeldChanged,
      onHangupPressed: onHangupPressed,
      onKeyPressed: onKeyPressed,
      addParticipantAvailability: addParticipantAvailability,
      addParticipantPendingName: addParticipantPendingName,
      onAddParticipant: onAddParticipant,
      onAddParticipantCancelled: onAddParticipantCancelled,
      addParticipantIntoRoom: addParticipantIntoRoom,
    );
  }

  group('ActiveCallActions accessibility', () {
    testWidgets('mute, hold and hangup announce themselves and activate through semantics', (tester) async {
      final handle = tester.ensureSemantics();

      bool? muted;
      bool? held;
      var hungUp = false;
      await tester.pumpWidget(
        wrap(
          buildActive(
            onMutedChanged: (v) => muted = v,
            onHeldChanged: (v) => held = v,
            onHangupPressed: () => hungUp = true,
          ),
        ),
      );

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsMuteId),
        label: 'Mute microphone',
        identifier: callActionsMuteId,
        isButton: true,
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsMuteId));
      expect(muted, isTrue);

      expectTapTargetSemantics(tester, find.bySemanticsIdentifier(callActionsHoldId), label: 'Hold call');
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsHoldId));
      expect(held, isTrue);

      expectTapTargetSemantics(tester, find.bySemanticsIdentifier(callActionsHangupId), label: 'Hangup');
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsHangupId));
      expect(hungUp, isTrue);

      handle.dispose();
    });

    testWidgets('muted state flips the spoken name', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(buildActive(mutedValue: true, onMutedChanged: (_) {})));

      expectTapTargetSemantics(tester, find.bySemanticsIdentifier(callActionsMuteId), label: 'Unmute microphone');

      handle.dispose();
    });

    testWidgets('transfer trigger opens its menu through semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(buildActive(onBlindTransferInitiated: () {}, onAttendedTransferInitiated: () {})));

      final transfer = find.bySemanticsIdentifier(callActionsTransferMenuId);
      expectTapTargetSemantics(tester, transfer, label: 'Transfer', isButton: true);

      await tapViaSemantics(tester, transfer);
      await tester.pumpAndSettle();

      expect(find.text('Unattended transfer'), findsOneWidget);
      expect(find.text('Attended transfer'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the second line of a disabled entry is fainter than its greyed name', (tester) async {
      // A fixed opacity drew it brighter than the name it explains.
      await tester.pumpWidget(
        wrap(
          buildActive(enableInteractions: false, onBlindTransferInitiated: () {}, onAttendedTransferInitiated: () {}),
        ),
      );
      await tester.tap(find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      final nameColor = DefaultTextStyle.of(tester.element(find.text('Unattended transfer'))).style.color!;
      final subtitleColor = tester.widget<Text>(find.text('Hand the call over without talking first')).style!.color!;
      expect(subtitleColor.a, lessThan(nameColor.a));
    });

    testWidgets('with conferences offered the menu is named for both and invites somebody', (tester) async {
      final handle = tester.ensureSemantics();
      var invited = 0;
      await tester.pumpWidget(
        wrap(
          buildActive(
            onBlindTransferInitiated: () {},
            onAttendedTransferInitiated: () {},
            addParticipantAvailability: AddParticipantAvailability.available,
            onAddParticipant: () => invited++,
          ),
        ),
      );

      final menu = find.bySemanticsIdentifier(callActionsTransferMenuId);
      expectTapTargetSemantics(tester, menu, label: 'Add or transfer', isButton: true);
      await tapViaSemantics(tester, menu);
      await tester.pumpAndSettle();

      // The transfers are still there; the invite comes after them.
      expect(find.text('Unattended transfer'), findsOneWidget);
      final add = find.bySemanticsIdentifier(callActionsTransferMenuAddParticipantId);
      expectTapTargetSemantics(
        tester,
        add,
        // Both lines are read: the name, then what it does.
        label: 'Add participant\nCall someone and bring them into this call',
        identifier: callActionsTransferMenuAddParticipantId,
      );
      await tapViaSemantics(tester, add);
      await tester.pumpAndSettle();
      expect(invited, 1);

      handle.dispose();
    });

    testWidgets('a leg of the room opens the menu for the invite alone', (tester) async {
      // No transfer callbacks: a leg is not a call to hand over.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          buildActive(
            addParticipantAvailability: AddParticipantAvailability.available,
            onAddParticipant: () {},
            addParticipantIntoRoom: true,
          ),
        ),
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(callActionsTransferMenuAddParticipantId), findsOneWidget);
      expect(find.text('Call someone and bring them into the conference'), findsOneWidget);
      expect(find.text('Unattended transfer'), findsNothing);

      handle.dispose();
    });

    testWidgets('with every line taken the invite stays, inert, and says why', (tester) async {
      final handle = tester.ensureSemantics();
      var invited = 0;
      await tester.pumpWidget(
        wrap(
          buildActive(
            onBlindTransferInitiated: () {},
            addParticipantAvailability: AddParticipantAvailability.noFreeLine,
            onAddParticipant: () => invited++,
          ),
        ),
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      final add = find.bySemanticsIdentifier(callActionsTransferMenuAddParticipantId);
      expect(tester.getSemantics(add).getSemanticsData().label, contains('All lines are busy'));
      await tester.tap(add, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(invited, 0);

      handle.dispose();
    });

    testWidgets('a menu that would hold only an inert entry is not opened', (tester) async {
      // A call still ringing or a video call: no transfer, and nobody can be
      // called in. The button stays disabled as the plain transfer did,
      // rather than open on one greyed entry with no reason.
      await tester.pumpWidget(wrap(buildActive(addParticipantAvailability: AddParticipantAvailability.unavailable)));

      expect(tester.widget<CallActionMenuButton>(find.byKey(callActionsTransferMenuKey)).enabled, isFalse);
      expect(find.byIcon(Icons.add_call), findsOneWidget, reason: 'still named for both where rooms are offered');
    });

    testWidgets('while an invite rings the same place gives it up, naming who is being called', (tester) async {
      final handle = tester.ensureSemantics();
      var cancelled = 0;
      await tester.pumpWidget(
        wrap(
          buildActive(
            onBlindTransferInitiated: () {},
            addParticipantAvailability: AddParticipantAvailability.unavailable,
            addParticipantPendingName: 'Anna Marchenko',
            onAddParticipantCancelled: () => cancelled++,
          ),
        ),
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(callActionsTransferMenuAddParticipantId), findsNothing);
      final cancel = find.bySemanticsIdentifier(callActionsTransferMenuCancelInviteId);
      expectTapTargetSemantics(
        tester,
        cancel,
        label: 'Cancel invite to Anna Marchenko\nStop calling and go back to the call',
        identifier: callActionsTransferMenuCancelInviteId,
      );
      await tapViaSemantics(tester, cancel);
      await tester.pumpAndSettle();
      expect(cancelled, 1);

      handle.dispose();
    });

    testWidgets('without conferences the button is the plain transfer it always was', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(buildActive(onBlindTransferInitiated: () {})));

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsTransferMenuId),
        label: 'Transfer',
        isButton: true,
      );
      expect(find.byIcon(Icons.phone_forwarded), findsOneWidget);

      handle.dispose();
    });

    testWidgets('each way of transferring can be told apart by id and pressed through it', (tester) async {
      final handle = tester.ensureSemantics();
      var blind = 0;
      var attended = 0;

      await tester.pumpWidget(
        wrap(buildActive(onBlindTransferInitiated: () => blind++, onAttendedTransferInitiated: () => attended++)),
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      // The entries are read out by what they say, so what they need is an id -
      // the two look alike and sit one under the other.
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsTransferMenuBlindInitId),
        label: 'Unattended transfer\nHand the call over without talking first',
        identifier: callActionsTransferMenuBlindInitId,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsTransferMenuAttendedInitId),
        label: 'Attended transfer\nTalk to them first, then hand the call over',
        identifier: callActionsTransferMenuAttendedInitId,
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuAttendedInitId));
      await tester.pumpAndSettle();
      expect(attended, 1);
      expect(blind, 0);

      handle.dispose();
    });

    testWidgets('the calls a transfer can go to are numbered by position', (tester) async {
      final handle = tester.ensureSemantics();
      final submitted = <ActiveCall>[];
      final secondCall = _transferableCall.copyWith(callId: 'second', handle: const CallkeepHandle.number('1003'));

      await tester.pumpWidget(
        wrap(
          buildActive(
            transferableCalls: [_transferableCall, secondCall],
            onAttendedTransferSubmitted: submitted.add,
            onBlindTransferInitiated: () {},
          ),
        ),
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsTransferMenuId));
      await tester.pumpAndSettle();

      // Two calls to hand over to: the first keeps the plain id and the second
      // is numbered from two, the way the call list numbers its rows.
      final second = numberedId(callActionsTransferMenuNumberId, 1);
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsTransferMenuNumberId),
        label: '${_transferableCall.handle.value}\nConnect them with this call',
        identifier: callActionsTransferMenuNumberId,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(second),
        label: '1003\nConnect them with this call',
        identifier: second,
      );

      // The second row hands the call to the second call, not to the first.
      await tapViaSemantics(tester, find.bySemanticsIdentifier(second));
      await tester.pumpAndSettle();
      expect(submitted, [secondCall]);

      handle.dispose();
    });

    testWidgets('in-call keypad: digits enter through semantics and hide button is named', (tester) async {
      final handle = tester.ensureSemantics();

      // The in-call keypad opens only in portrait orientation.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final entered = <String>[];
      // The keypad visibility is owned by the parent (the call screen); the
      // harness plays that role.
      var keypadShown = false;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => buildActive(
              onKeyPressed: entered.add,
              keypadShown: keypadShown,
              onKeypadToggle: (shown) => setState(() => keypadShown = shown),
            ),
          ),
        ),
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsKeypadId));
      await tester.pumpAndSettle();

      await tapViaSemantics(tester, find.bySemanticsIdentifier(keypadKeyId('5')));
      expect(entered, ['5']);

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsHideKeypadId),
        label: 'Hide keypad',
        isButton: true,
      );

      handle.dispose();
    });
  });

  group('ActiveCallActions while interactions are blocked', () {
    testWidgets('a keypad key press is ignored instead of crashing', (tester) async {
      final handle = tester.ensureSemantics();

      // The in-call keypad opens only in portrait orientation.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final entered = <String>[];
      // The keypad stays open across a renegotiation window: it is opened
      // while interactions are allowed and blocked right after.
      var enableInteractions = true;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => buildActive(
              enableInteractions: enableInteractions,
              onKeyPressed: entered.add,
              keypadShown: true,
              onKeypadToggle: (_) {},
            ),
          ),
        ),
      );

      await tapViaSemantics(tester, find.bySemanticsIdentifier(keypadKeyId('5')));
      expect(entered, ['5']);

      enableInteractions = false;
      await tester.pumpWidget(
        wrap(buildActive(enableInteractions: false, onKeyPressed: entered.add, keypadShown: true)),
      );

      await tester.tap(find.byType(KeypadKeyButton).first);
      await tester.pump();
      expect(entered, ['5'], reason: 'the blocked press must not reach the call');
      expect(tester.takeException(), isNull);

      handle.dispose();
    });

    testWidgets('transfer trigger is disabled when no transfer intent is wired', (tester) async {
      final handle = tester.ensureSemantics();

      // Two calls make the "transfer to a call" branch render, but with no
      // transfer callbacks its menu would be empty.
      await tester.pumpWidget(wrap(buildActive(transferableCalls: [_transferableCall])));

      final node = tester.getSemantics(find.bySemanticsIdentifier(callActionsTransferMenuId));
      expect(node, isSemantics(label: 'Transfer', hasTapAction: false));

      handle.dispose();
    });
  });

  group('IncomingCallActions accessibility', () {
    testWidgets('decline and accept are named and activate through semantics', (tester) async {
      final handle = tester.ensureSemantics();

      var declined = false;
      var accepted = false;
      await tester.pumpWidget(
        wrap(
          IncomingCallActions(
            remoteVideo: false,
            inviteToAttendedTransfer: false,
            onHangupPressed: () => declined = true,
            onAcceptPressed: () => accepted = true,
          ),
        ),
      );

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsHangupId),
        label: 'Hangup',
        identifier: callActionsHangupId,
        isButton: true,
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsHangupId));
      expect(declined, isTrue);

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsAcceptId),
        label: 'Accept',
        identifier: callActionsAcceptId,
        isButton: true,
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsAcceptId));
      expect(accepted, isTrue);

      handle.dispose();
    });
  });
}
