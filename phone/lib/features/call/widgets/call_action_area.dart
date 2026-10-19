import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';
import '../view/call_screen_styles.dart';
import 'active_call_actions.dart';
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
    final callConfig = params.callConfig;
    final interactionsEnabled = params.interactionsEnabled;

    final heldCalls = activeCalls.nonCurrent;

    final nonIncomingRingingCalls = activeCalls.nonIncomingRinging;
    final nonIncomingRingingCanBeHolded = nonIncomingRingingCalls.where((call) => call.wasAccepted == true).toList();

    final focusedIsRinging = focusedCall.isIncomingRinging;
    final focusedTransfer = focusedCall.transfer;

    // A leg of the room is not a call the grid can act on: the server refuses
    // a hold or a transfer of one, and the microphone it would mute is the
    // room's - one track shared by every call - so muting it there would
    // silence the whole conference. The grid acts on the room instead.
    final focusedIsLeg = params.conference.isLeg(focusedCall.callId);

    // The calls a transfer can go to, and the one it would replace, are never
    // legs of the room: the server refuses a transfer that involves one.
    //
    // The hand-over is of the call the attended transfer was started for, to
    // the call placed to consult, and there is one to offer only while such
    // a call is up and answered. Every held call used to be listed, and a
    // third call answered meanwhile was offered as a target too, which
    // handed people over to a stranger.
    final attendedTransferCall = params.attendedTransferCall;
    final transferAnchorId = attendedTransferCall == null ? null : params.linkedCall?.anchorCallId;
    final transferTargets = [
      for (final call in heldCalls)
        if (call.callId == transferAnchorId && !params.conference.isLeg(call.callId)) call,
    ];
    final transferCallIsLeg = attendedTransferCall != null && params.conference.isLeg(attendedTransferCall.callId);

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
        cameraPermissionDenied: callConfig.isVideoCallEnabled && focusedCall.videoPermissionDenied,
        onCameraPermissionDeniedPressed: params.onCameraPermissionDeniedPressed,
        onCameraChanged: callConfig.isVideoCallEnabled ? params.onCameraChanged : null,
        // What it shows is the room's mute; what it does is the ordinary
        // mute of the focused call, which the bloc routes to the room for a
        // leg. That keeps the operating system's own mute state in step with
        // the room instead of leaving the two to disagree.
        mutedValue: focusedIsLeg ? params.conference.selfMuted : focusedCall.muted,
        onMutedChanged: params.onMutedChanged,
        audioDevice: params.audioDevice,
        availableAudioDevices: params.availableAudioDevices,
        onAudioDeviceChanged: params.onAudioDeviceChanged,
        // A leg is neither a call to hand over nor one to hand a call to: the
        // server refuses a transfer of one, from whichever side. For a leg the
        // menu is only the way to invite somebody into the room.
        transferableCalls: focusedIsLeg ? const [] : transferTargets,
        onBlindTransferInitiated: callConfig.isBlindTransferEnabled && !focusedIsLeg
            ? (!focusedCall.wasAccepted || focusedTransfer != null ? null : params.onBlindTransferInitiated)
            : null,
        // TODO (Serdun): Simplify complex condition in the widget tree.
        onAttendedTransferInitiated: callConfig.isAttendedTransferEnabled && params.canStartAttendedTransfer
            ? params.onAttendedTransferInitiated
            : null,
        // TODO (Serdun): Simplify complex condition in the widget tree.
        // The submit hands the call named in the menu over to the call placed
        // for it; which call that is comes from the link, not from which call
        // happens to be live (see [CallControlsParams.attendedTransferCall]).
        // Gated on the link the submit acts on, not on which call is live.
        onAttendedTransferSubmitted:
            callConfig.isAttendedTransferEnabled &&
                attendedTransferCall != null &&
                !transferCallIsLeg &&
                focusedTransfer == null
            ? params.onAttendedTransferSubmitted
            : null,
        heldValue: focusedCall.held,
        // Hold pauses just the focused call; Resume brings it
        // back as the only live one (the other live calls are
        // put on hold first). Switching lines = focus the other
        // row and press Resume - there is no separate swap.
        onHeldChanged: focusedIsLeg ? null : params.onHeldChanged,
        onHangupPressed: params.onHangup,
        // It is the room the hangup ends while one stands, and it is the only
        // control that ends it, so it says so rather than "hang up".
        hangupLabel: focusedIsLeg ? context.l10n.call_SemanticsLabel_conferenceEnd : null,

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
          onAcceptPressed: nonIncomingRingingCalls.isNotEmpty && !interactionsEnabled ? null : params.onAccept,
        ),
      ],
    );
  }
}
