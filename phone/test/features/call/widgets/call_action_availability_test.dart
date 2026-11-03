import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../view/call_active_scaffold_harness.dart';

void main() {
  final active = makeCall(callId: 'active', acceptedTime: DateTime(2024), displayName: 'Thomas Anderson');
  final ringingOut = makeCall(
    callId: 'out',
    direction: CallDirection.outgoing,
    processingStatus: CallProcessingStatus.outgoingRinging,
  );
  final ringingIn = makeCall(callId: 'in', processingStatus: CallProcessingStatus.incomingFromOffer);

  CallActionAvailability availability({
    required List<ActiveCall> calls,
    ActiveCall? focused,
    CallCapabilitiesConfig config = const CallCapabilitiesConfig(),
    ConferenceState conference = const ConferenceState(),
    bool interactionsEnabled = true,
    bool canStartAttendedTransfer = false,
    HandOver? handOver,
    AddParticipantAvailability addParticipantAvailability = AddParticipantAvailability.hidden,
    void Function(ActiveCall referor, ActiveCall replace)? onAttendedTransferSubmitted,
  }) {
    return CallActionAvailability(
      CallControlsParams(
        activeCalls: calls,
        focusedCall: focused ?? calls.first,
        availableAudioDevices: const [],
        callConfig: config,
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
        onAttendedTransferSubmitted: onAttendedTransferSubmitted ?? (_, _) {},
        onHeldChanged: (_) {},
        onKeyPressed: (_) {},
        onHangup: () {},
        onAccept: () {},
        conference: conference,
        canStartAttendedTransfer: canStartAttendedTransfer,
        handOver: handOver,
        addParticipantAvailability: addParticipantAvailability,
      ),
    );
  }

  test('a blind transfer needs an answered call', () {
    expect(availability(calls: [active]).onBlindTransfer, isNotNull);
    expect(availability(calls: [ringingOut]).onBlindTransfer, isNull);
    expect(
      availability(
        calls: [active],
        config: const CallCapabilitiesConfig(isBlindTransferEnabled: false),
      ).onBlindTransfer,
      isNull,
    );
  });

  test('a leg of the room acts on the room: its mute, no hold, no transfer', () {
    const room = ConferenceState(phase: ConferencePhase.active, legs: {'active': 0}, selfMuted: true);
    final actions = availability(calls: [active], conference: room);

    expect(actions.focusedIsLeg, isTrue);
    expect(actions.muted, isTrue, reason: 'the room is muted, the call is not');
    expect(actions.onHeldChanged, isNull);
    expect(actions.onBlindTransfer, isNull);
    expect(actions.transferableCalls, isEmpty);
    expect(actions.transferMenuEnabled, isFalse, reason: 'nothing to transfer and nobody to invite');
  });

  test('the camera is offered only where video calls are on', () {
    expect(availability(calls: [active]).cameraOffered, isTrue);
    final off = availability(calls: [active], config: const CallCapabilitiesConfig(isVideoCallEnabled: false));
    expect(off.cameraOffered, isFalse);
    expect(off.onCameraChanged, isNull);
  });

  test('answering over a live call waits for the server', () {
    expect(availability(calls: [ringingIn]).onAccept, isNotNull);
    final over = availability(calls: [active, ringingIn], focused: ringingIn, interactionsEnabled: false);
    expect(over.onAccept, isNull);
    expect(over.othersOnAnswer.single.callId, 'active');
    expect(over.heldOnAnswer.single.callId, 'active');
  });

  test('an attended transfer starts only where the state says it can, and where it is on', () {
    expect(availability(calls: [active]).onAttendedTransferStart, isNull);
    expect(availability(calls: [active], canStartAttendedTransfer: true).onAttendedTransferStart, isNotNull);
    expect(
      availability(
        calls: [active],
        canStartAttendedTransfer: true,
        config: const CallCapabilitiesConfig(isAttendedTransferEnabled: false),
      ).onAttendedTransferStart,
      isNull,
    );
  });

  test('a hand-over connects the entry the state chose, and enables the menu only with calls to list', () {
    final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true);
    final state = CallState(linesCount: 3, activeCalls: [active, held]);
    final handOver = state.handOverFor('active');
    final sent = <(String, String)>[];
    final actions = availability(
      calls: [active, held],
      handOver: handOver,
      onAttendedTransferSubmitted: (referor, replace) => sent.add((referor.callId, replace.callId)),
      config: const CallCapabilitiesConfig(isBlindTransferEnabled: false),
    );

    expect(actions.transferableCalls.map((call) => call.callId), ['held']);
    actions.onHandOver!(held);
    final entry = handOver!.entryOf(held)!;
    expect(sent, [(entry.referorCall.callId, entry.replaceCall.callId)]);
    expect(actions.transferMenuEnabled, isTrue);
  });

  test('the transfer menu is the phone\'s rule: an invite under offer enables it on its own', () {
    final noTransfer = const CallCapabilitiesConfig(isBlindTransferEnabled: false, isAttendedTransferEnabled: false);
    expect(availability(calls: [active], config: noTransfer).transferMenuEnabled, isFalse);
    final inviting = availability(
      calls: [active],
      config: noTransfer,
      addParticipantAvailability: AddParticipantAvailability.noFreeLine,
    );
    expect(inviting.inviteShown, isTrue);
    expect(inviting.inviteOffered, isTrue, reason: 'it says why it cannot');
    expect(inviting.transferMenuEnabled, isTrue);
    final unavailable = availability(
      calls: [active],
      config: noTransfer,
      addParticipantAvailability: AddParticipantAvailability.unavailable,
    );
    expect(unavailable.inviteShown, isTrue, reason: 'the menu still says it invites');
    expect(unavailable.transferMenuEnabled, isFalse);
  });

  test('a refused camera opens the settings, only where video calls are on', () {
    final denied = makeCall(callId: 'denied', acceptedTime: DateTime(2024), videoPermissionDenied: true);
    expect(availability(calls: [denied]).cameraPermissionDenied, isTrue);
    expect(
      availability(
        calls: [denied],
        config: const CallCapabilitiesConfig(isVideoCallEnabled: false),
      ).cameraPermissionDenied,
      isFalse,
    );
  });
}
