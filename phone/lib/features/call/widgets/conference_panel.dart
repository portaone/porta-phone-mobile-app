import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';
import '../view/call_screen_style.dart';
import '../utils/contact_resolver.dart';
import 'call_action_button.dart';
import 'call_row_frame.dart';

/// The conference room: who is in it, who is muted for everyone, and the way
/// out of it.
///
/// It takes the place of the call roster while a room is up, because the legs
/// are no longer calls to choose between - they are one mixed conversation,
/// and the controls that act on a single call do not apply to them. Calls
/// outside the room keep their rows below this block.
///
/// The membership is the client's record of what it merged, ordered by line
/// so the rows do not move about; whether the server has the participant
/// ready is a separate question and only gates the room-wide mute.
class ConferencePanel extends StatelessWidget {
  const ConferencePanel({
    super.key,
    required this.conference,
    required this.calls,
    required this.onSelfMutedChanged,
    required this.onParticipantMutedChanged,
    required this.onParticipantHangup,
    this.contactResolver,
    this.style,
    this.listStyle,
    this.actionsStyle,
  });

  final ConferenceState conference;

  /// Every call the bloc holds; the legs are looked up here for their name and
  /// the moment they were answered.
  final List<ActiveCall> calls;

  /// Mutes the host's own microphone towards the room. Nobody in the room is
  /// told; it is the local microphone, not a room-wide mute.
  final ValueChanged<bool> onSelfMutedChanged;

  /// Mutes a participant for everyone in the room. The outcome arrives as the
  /// server's next participant list, so nothing is assumed here.
  final void Function(String callId, bool muted) onParticipantMutedChanged;

  /// Ends one participant's call, which takes them out of the room.
  final ValueChanged<String> onParticipantHangup;

  /// Resolves who a leg is with, for the picture on its row.
  final ContactResolver? contactResolver;

  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  /// The screen's own button styles; the room's destructive controls take the
  /// hangup one so they read as what they are and stay themeable.
  final CallScreenActionsStyle? actionsStyle;

  @override
  Widget build(BuildContext context) {
    final statusStyle = style?.callStatus ?? const TextStyle();
    final legs = conference.legs.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CallRowHeader(label: context.l10n.call_ConferencePanel_header(legs.length), style: style),
        CallRowFrame(
          name: context.l10n.call_ConferencePanel_you,
          status: context.l10n.call_ConferencePanel_hostStatus,
          style: style,
          listStyle: listStyle,
          focused: true,
          leading: CallRowSelfAvatar(style: style),
          trailing: [
            _MuteToggle(
              muted: conference.selfMuted,
              identifier: conferenceSelfMuteId,
              label: conference.selfMuted
                  ? context.l10n.call_SemanticsLabel_conferenceSelfUnmute
                  : context.l10n.call_SemanticsLabel_conferenceSelfMute,
              onPressed: () => onSelfMutedChanged(!conference.selfMuted),
              style: statusStyle,
            ),
          ],
        ),
        for (final (index, leg) in legs.indexed)
          _ParticipantRow(
            key: ValueKey('ConferenceParticipant-${leg.key}'),
            index: index,
            call: calls.firstWhereOrNull((call) => call.callId == leg.key),
            callId: leg.key,
            // Core answers a mute for a participant it has not finished
            // wiring with line_not_ready, so the control waits for the
            // participant to appear in a list of its own.
            ready: conference.isReady(leg.key),
            muted: conference.participantMuted(leg.key),
            onMutedChanged: (muted) => onParticipantMutedChanged(leg.key, muted),
            onHangup: () => onParticipantHangup(leg.key),
            contactResolver: contactResolver,
            style: style,
            listStyle: listStyle,
            hangupStyle: actionsStyle?.hangup,
          ),
      ],
    );
  }
}

/// One participant of the room: who they are, how long their call has been
/// up, the room-wide mute and the way to drop them.
class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    super.key,
    required this.index,
    required this.call,
    required this.callId,
    required this.ready,
    required this.muted,
    required this.onMutedChanged,
    required this.onHangup,
    required this.contactResolver,
    required this.style,
    required this.listStyle,
    required this.hangupStyle,
  });

  final int index;

  /// The call behind the leg; `null` for the moment between the server taking
  /// it out of the room and the bloc dropping the leg.
  final ActiveCall? call;
  final String callId;
  final bool ready;
  final bool muted;
  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onHangup;
  final ContactResolver? contactResolver;
  final CallInfoStyle? style;
  final CallListStyle? listStyle;
  final ButtonStyle? hangupStyle;

  Widget? _leading() {
    final call = this.call;
    return call == null ? null : CallRowAvatar(call: call, contactResolver: contactResolver);
  }

  @override
  Widget build(BuildContext context) {
    final call = this.call;
    final statusStyle = style?.callStatus ?? const TextStyle();
    final acceptedTime = call?.acceptedTime;

    final name = call?.displayName ?? call?.handle.value ?? callId;
    final status = muted
        ? context.l10n.call_ConferencePanel_participantMuted
        : context.l10n.call_ConferencePanel_participantStatus;

    return CallRowFrame(
      name: name,
      // The picture of whoever this leg is with, the same as a roster row -
      // a leg of a room is still a call with somebody. No state badge: the
      // row says in words whether they are muted for everyone.
      leading: _leading(),
      // The duration stands with the status rather than beside the controls:
      // past an hour it grows to HH:MM:SS, and on a narrow screen at a large
      // text scale a trailing group of that width has nowhere to go.
      statusBuilder: (context, elapsed) => elapsed == null ? status : '$status  ${elapsed.format()}',
      since: acceptedTime,
      style: style,
      listStyle: listStyle,
      trailing: [
        _MuteToggle(
          muted: muted,
          identifier: numberedId(conferenceParticipantMuteId, index),
          // Named, not "this participant": four rows of identical
          // destructive controls say nothing about which one they act on
          // (docs/accessibility.md, naming a control that is one of many).
          label: muted
              ? context.l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
              : context.l10n.call_SemanticsLabel_conferenceParticipantMute(name),
          onPressed: ready ? () => onMutedChanged(!muted) : null,
          style: statusStyle,
        ),
        CallActionButton(
          label: context.l10n.call_SemanticsLabel_conferenceParticipantHangup(name),
          identifier: numberedId(conferenceParticipantHangupId, index),
          onPressed: onHangup,
          style: (hangupStyle ?? _fallbackHangupStyle(context)).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          child: const Icon(Icons.call_end, size: 20),
        ),
      ],
    );
  }
}

/// A microphone toggle: on for a live microphone, struck through for a muted
/// one. Disabled while the server would refuse the request.
class _MuteToggle extends StatelessWidget {
  const _MuteToggle({
    required this.muted,
    required this.identifier,
    required this.label,
    required this.onPressed,
    required this.style,
  });

  final bool muted;
  final String identifier;
  final String label;
  final VoidCallback? onPressed;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final color = style.color ?? Theme.of(context).colorScheme.onSurface;
    return CallActionButton(
      label: label,
      identifier: identifier,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.3),
      ),
      child: Icon(muted ? Icons.mic_off : Icons.mic, size: 20),
    );
  }
}

/// The style the screen gives its hangup, for a deployment that themes none
/// of this: a filled control rather than red lettering, which is what every
/// other destructive control on the call screen is and what keeps it legible
/// on the screen's own dark ground.
ButtonStyle _fallbackHangupStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return TextButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError);
}
