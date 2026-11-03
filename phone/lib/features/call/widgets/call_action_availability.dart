import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

import '../models/models.dart';
import 'call_controls.dart';

/// Which of the call's actions the focused call allows now, and what each
/// does - decided once for every layout that offers them, starting with the
/// phone's action area.
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

  /// Turns the camera on or off; null where video calls are off.
  ValueChanged<bool>? get onCameraChanged => cameraOffered ? params.onCameraChanged : null;

  /// The call was answered without video because the camera was refused:
  /// the camera control opens the settings instead.
  bool get cameraPermissionDenied => cameraOffered && _call.videoPermissionDenied;

  /// The calls a hand-over connects this one with, as the state decides it;
  /// never for a leg, from whichever side.
  List<ActiveCall> get transferableCalls => focusedIsLeg ? const [] : params.handOver?.listedCalls ?? const [];

  /// Starts a transfer without talking first: only for an answered call
  /// with no transfer under way, never for a leg.
  VoidCallback? get onBlindTransfer => _config.isBlindTransferEnabled && !focusedIsLeg
      ? (!_call.wasAccepted || _call.transfer != null ? null : params.onBlindTransferInitiated)
      : null;

  /// Starts choosing whom to consult before handing the call over, where the
  /// state says a consultation call can be placed for it.
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

  /// Whether the transfer menu says it invites too: an invite is under way,
  /// or the deployment offers one at all.
  bool get inviteShown => inviteShownFor(pendingInvite, params.addParticipantAvailability);

  /// Whether the menu's invite entry acts, or says why it cannot.
  bool get inviteOffered => inviteOfferedFor(pendingInvite, params.addParticipantAvailability);

  /// Whether anything in the transfer menu can be taken now; the menu is
  /// always there, disabled otherwise.
  bool get transferMenuEnabled => transferMenuEnabledFor(
    hasTransferableCalls: transferableCalls.isNotEmpty,
    blind: onBlindTransfer != null,
    attendedStart: onAttendedTransferStart != null,
    handOver: onHandOver != null,
    inviteOffered: inviteOffered,
  );

  /// [inviteShown] for a layout that holds the values apart.
  static bool inviteShownFor(String? pendingInvite, AddParticipantAvailability availability) =>
      pendingInvite != null || availability.shown;

  /// [inviteOffered] for a layout that holds the values apart. The menu opens
  /// only for an entry that acts, or that says why it cannot (every line
  /// taken): a menu of one inert entry with no reason is a dead end.
  static bool inviteOfferedFor(String? pendingInvite, AddParticipantAvailability availability) =>
      pendingInvite != null ||
      availability == AddParticipantAvailability.available ||
      availability == AddParticipantAvailability.noFreeLine;

  /// [transferMenuEnabled] for a layout that holds the values apart. A
  /// hand-over counts only where there are calls to hand over to.
  static bool transferMenuEnabledFor({
    required bool hasTransferableCalls,
    required bool blind,
    required bool attendedStart,
    required bool handOver,
    required bool inviteOffered,
  }) => blind || attendedStart || inviteOffered || (hasTransferableCalls && handOver);

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
