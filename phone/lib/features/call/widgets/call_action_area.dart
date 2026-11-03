import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../view/call_screen_styles.dart';
import 'active_call_actions.dart';
import 'call_action_availability.dart';
import 'call_controls.dart';
import 'focused_action_hint.dart';
import 'incoming_call_actions.dart';

/// Everything the user can press about the focused call: the control grid
/// while the call is live, or Decline/Answer - with the "Acting on" hint when
/// other calls are around - while it rings.
///
/// The area is shared by the orientation layouts: each of them decides where
/// it stands, none of them what is inside. What each control does keeps
/// arriving from the screen above as the callbacks in [params].
class CallActionArea extends StatelessWidget {
  const CallActionArea({super.key, required this.params, this.hangupRowShown = true, this.padded = true});

  final CallControlsParams params;

  /// Whether the control grid keeps its own hangup row (see
  /// [ActiveCallActions.hangupRowShown]); the landscape layout renders the
  /// hangup in a zone of its own instead.
  final bool hangupRowShown;

  /// Whether the ringing Decline/Answer pad themselves to sit centered on a
  /// full-width screen (see [IncomingCallActions.padded]).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;

    final activeCalls = params.activeCalls;
    final focusedCall = params.focusedCall;
    final interactionsEnabled = params.interactionsEnabled;
    // What the focused call allows, decided once for the phone and the watch.
    final actions = CallActionAvailability(params);

    final nonIncomingRingingCalls = actions.othersOnAnswer;
    final nonIncomingRingingCanBeHolded = actions.heldOnAnswer;

    final focusedIsRinging = focusedCall.isIncomingRinging;

    if (!focusedIsRinging) {
      return ActiveCallActions(
        style: style?.actions,
        hangupRowShown: hangupRowShown,
        padded: padded,
        keypadShown: params.keypadShown,
        dtmfInput: params.dtmfInput,
        onKeypadToggle: (shown) => params.onKeypadToggle(shown),
        // Blocks signaling-dependent actions (hold, transfer, camera).
        // False during: interaction debounce, signaling not ready, SDP renegotiation.
        enableInteractions: interactionsEnabled,
        cameraValue: focusedCall.isCameraActive,
        cameraPermissionDenied: actions.cameraPermissionDenied,
        onCameraPermissionDeniedPressed: params.onCameraPermissionDeniedPressed,
        onCameraChanged: actions.onCameraChanged,
        mutedValue: actions.muted,
        onMutedChanged: params.onMutedChanged,
        audioDevice: params.audioDevice,
        availableAudioDevices: params.availableAudioDevices,
        onAudioDeviceChanged: params.onAudioDeviceChanged,
        transferableCalls: actions.transferableCalls,
        onBlindTransferInitiated: actions.onBlindTransfer,
        onAttendedTransferInitiated: actions.onAttendedTransferStart,
        onAttendedTransferSubmitted: actions.onHandOver,
        heldValue: focusedCall.held,
        // Hold pauses just the focused call; Resume brings it
        // back as the only live one (the other live calls are
        // put on hold first). Switching lines = focus the other
        // row and press Resume - there is no separate swap.
        onHeldChanged: actions.onHeldChanged,
        onHangupPressed: params.onHangup,
        // It is the room the hangup ends while one stands, and it is the only
        // control that ends it, so it says so rather than "hang up".
        hangupLabel: actions.focusedIsLeg ? context.l10n.call_SemanticsLabel_conferenceEnd : null,

        onKeyPressed: params.onKeyPressed,
        addParticipantAvailability: params.addParticipantAvailability,
        addParticipantPendingName: params.addParticipantPendingName,
        onAddParticipant: params.onAddParticipant,
        onAddParticipantCancelled: params.onAddParticipantCancelled,
        addParticipantIntoRoom: params.addParticipantIntoRoom,
      );
    }

    // Decline / Answer for the focused ringing call -
    // always two buttons. Answering holds the answered
    // calls (or ends the non-holdable ones); the hint
    // names the focused call and spells the side effect.
    // The hint and the buttons are one column child so
    // the spaceBetween layout keeps them glued together
    // at the bottom.
    // Edge-cases (covered by the call list above):
    // - two incoming ringing calls
    // - one outgoing ringing + one incoming ringing
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activeCalls.length > 1)
          FocusedActionHint(
            focusedName: focusedCall.displayName ?? focusedCall.handle.value,
            willBeHeldNames: nonIncomingRingingCanBeHolded.isEmpty
                ? const []
                : [
                    for (final call in nonIncomingRingingCanBeHolded)
                      if (!call.held) call.displayName ?? call.handle.value,
                  ],
            willBeEndedNames: nonIncomingRingingCanBeHolded.isNotEmpty
                ? const []
                : [for (final call in nonIncomingRingingCalls) call.displayName ?? call.handle.value],
            style: style?.callInfo,
            hintStyle: style?.hint,
          ),
        IncomingCallActions(
          style: style?.actions,
          padded: padded,
          inviteToAttendedTransfer: false,
          remoteVideo: focusedCall.remoteVideo && focusedCall.held == false,
          onHangupPressed: params.onHangup,
          // Answering with other calls present mutates them
          // (hold/end), so it is gated by the interactions
          // debounce like any signaling-dependent action.
          onAcceptPressed: actions.onAccept,
        ),
      ],
    );
  }
}
