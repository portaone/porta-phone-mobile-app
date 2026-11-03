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
        onAttendedTransferSubmitted: (_, _) {},
        onHeldChanged: (_) {},
        onKeyPressed: (_) {},
        onHangup: () {},
        onAccept: () {},
        conference: conference,
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
    expect(actions.transferMenuOffered, isFalse, reason: 'nothing to transfer and nobody to invite');
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
}
