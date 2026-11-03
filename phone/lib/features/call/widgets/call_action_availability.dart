import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

import '../models/models.dart';
import 'call_controls.dart';

/// Which of the call's actions the focused call allows now, and what each
/// does - decided once for every layout that offers them: the phone's action
/// area and the watch's call face and menus.
///
/// A null callback is an action that exists but cannot be taken now; the
/// layouts show it disabled. Whether an action is there at all is decided
/// by the getters that say so.
class CallActionAvailability {
  CallActionAvailability(this.params);

  final CallControlsParams params;

  ActiveCall get _call => params.focusedCall;
  CallCapabilitiesConfig get _config => params.callConfig;

  /// A leg of the room is not a call the controls can act on: the server
  /// refuses a hold or a transfer of one, and the microphone it would mute is
  /// the room's - one track shared by every call - so the controls act on the
  /// room instead.
  bool get focusedIsLeg => params.conference.isLeg(_call.callId);

  /// What the microphone control shows: the room's mute for a leg. What it
  /// does is the ordinary mute of the focused call, which the bloc routes to
  /// the room for a leg - keeping the operating system's own mute state in
  /// step with the room.
  bool get muted => focusedIsLeg ? params.conference.selfMuted : _call.muted;

  /// Hold pauses just the focused call; Resume brings it back as the only
  /// live one. Not for a leg.
  ValueChanged<bool>? get onHeldChanged => focusedIsLeg ? null : params.onHeldChanged;

  /// Whether video calls are on at all; the camera control is shown off
  /// otherwise.
  bool get cameraOffered => _config.isVideoCallEnabled;

  ValueChanged<bool>? get onCameraChanged => cameraOffered ? params.onCameraChanged : null;

  /// The call was answered without video because the camera was refused:
  /// the camera control opens the settings instead.
  bool get cameraPermissionDenied => cameraOffered && _call.videoPermissionDenied;

  /// The calls a hand-over connects this one with, as the state decides it;
  /// never for a leg, from whichever side.
  List<ActiveCall> get transferableCalls => focusedIsLeg ? const [] : params.handOver?.listedCalls ?? const [];

  VoidCallback? get onBlindTransfer => _config.isBlindTransferEnabled && !focusedIsLeg
      ? (!_call.wasAccepted || _call.transfer != null ? null : params.onBlindTransferInitiated)
      : null;

  VoidCallback? get onAttendedTransferStart =>
      _config.isAttendedTransferEnabled && params.canStartAttendedTransfer ? params.onAttendedTransferInitiated : null;

  /// Sends the transfer of a listed call's entry, read from the same
  /// hand-over the list was built from, never guessed from which call happens
  /// to be live.
  ValueChanged<ActiveCall>? get onHandOver =>
      _config.isAttendedTransferEnabled && params.handOver != null && _call.transfer == null ? _submitHandOver : null;

  void _submitHandOver(ActiveCall listedCall) {
    final entry = params.handOver?.entryOf(listedCall);
    if (entry != null) params.onAttendedTransferSubmitted(entry.referorCall, entry.replaceCall);
  }

  /// Who is being called in while that call still rings.
  String? get pendingInvite => params.addParticipantPendingName;

  /// Whether the menu offers inviting somebody, or giving up on an invite.
  bool get inviteOffered =>
      pendingInvite != null ||
      params.addParticipantAvailability == AddParticipantAvailability.available ||
      params.addParticipantAvailability == AddParticipantAvailability.noFreeLine;

  /// Whether the transfer menu is there: a leg has nothing to transfer, only
  /// somebody to invite.
  bool get transferMenuOffered => !focusedIsLeg || inviteOffered;

  /// Whether anything in the transfer menu can be taken now.
  bool get transferMenuEnabled =>
      onBlindTransfer != null ||
      onAttendedTransferStart != null ||
      (transferableCalls.isNotEmpty && onHandOver != null) ||
      inviteOffered;

  /// The calls a ringing focus affects when answered: the live ones.
  List<ActiveCall> get othersOnAnswer => params.activeCalls.nonIncomingRinging;

  /// The live calls answering puts on hold; when none can be held, answering
  /// ends [othersOnAnswer] instead.
  List<ActiveCall> get heldOnAnswer => [
    for (final call in othersOnAnswer)
      if (call.wasAccepted) call,
  ];

  /// Answering with other calls present changes them, so it waits for the
  /// server like any action that does.
  VoidCallback? get onAccept => othersOnAnswer.isNotEmpty && !params.interactionsEnabled ? null : params.onAccept;
}
