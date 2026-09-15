import 'dart:async';

import 'package:flutter/material.dart';

import 'package:clock/clock.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';
import '../view/call_screen_style.dart';
import 'call_action_button.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.call_ConferencePanel_header(legs.length).toUpperCase(),
                  style: statusStyle.copyWith(fontSize: 11, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
        ),
        _PanelRow(
          name: context.l10n.call_ConferencePanel_you,
          status: context.l10n.call_ConferencePanel_hostStatus,
          style: style,
          listStyle: listStyle,
          focused: true,
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
class _ParticipantRow extends StatefulWidget {
  const _ParticipantRow({
    super.key,
    required this.index,
    required this.call,
    required this.callId,
    required this.ready,
    required this.muted,
    required this.onMutedChanged,
    required this.onHangup,
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
  final CallInfoStyle? style;
  final CallListStyle? listStyle;
  final ButtonStyle? hangupStyle;

  @override
  State<_ParticipantRow> createState() => _ParticipantRowState();
}

class _ParticipantRowState extends State<_ParticipantRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _ParticipantRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  /// Ticks only while there is a duration to tick; a leg the server lists but
  /// this client has no call for shows none.
  void _syncTicker() {
    final wanted = widget.call?.acceptedTime != null;
    if (wanted && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (!wanted) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final statusStyle = widget.style?.callStatus ?? const TextStyle();
    final acceptedTime = call?.acceptedTime;

    final name = call?.displayName ?? call?.handle.value ?? widget.callId;
    final status = widget.muted
        ? context.l10n.call_ConferencePanel_participantMuted
        : context.l10n.call_ConferencePanel_participantStatus;

    return _PanelRow(
      name: name,
      // The duration stands with the status rather than beside the controls:
      // past an hour it grows to HH:MM:SS, and on a narrow screen at a large
      // text scale a trailing group of that width has nowhere to go.
      status: acceptedTime == null ? status : '$status  ${clock.now().difference(acceptedTime).format()}',
      style: widget.style,
      listStyle: widget.listStyle,
      trailing: [
        _MuteToggle(
          muted: widget.muted,
          identifier: numberedId(conferenceParticipantMuteId, widget.index),
          // Named, not "this participant": four rows of identical
          // destructive controls say nothing about which one they act on
          // (docs/accessibility.md, naming a control that is one of many).
          label: widget.muted
              ? context.l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
              : context.l10n.call_SemanticsLabel_conferenceParticipantMute(name),
          onPressed: widget.ready ? () => widget.onMutedChanged(!widget.muted) : null,
          style: statusStyle,
        ),
        CallActionButton(
          label: context.l10n.call_SemanticsLabel_conferenceParticipantHangup(name),
          identifier: numberedId(conferenceParticipantHangupId, widget.index),
          onPressed: widget.onHangup,
          style: (widget.hangupStyle ?? _fallbackHangupStyle(context)).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          child: const Icon(Icons.call_end, size: 20),
        ),
      ],
    );
  }
}

/// The shape every row of the panel shares with a call roster row, so the
/// room does not read as a different screen.
class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.name,
    required this.status,
    required this.trailing,
    required this.style,
    required this.listStyle,
    this.focused = false,
  });

  final String name;
  final String status;
  final List<Widget> trailing;
  final CallInfoStyle? style;
  final CallListStyle? listStyle;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final nameStyle = style?.number ?? const TextStyle();
    final statusStyle = style?.callStatus ?? const TextStyle();
    final base = statusStyle.color ?? Theme.of(context).colorScheme.surface;
    final rowColor = focused
        ? (listStyle?.rowFocusedBackground ?? base.withValues(alpha: 0.26))
        : (listStyle?.rowBackground ?? base.withValues(alpha: 0.10));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status, style: statusStyle.copyWith(fontSize: 10, letterSpacing: 1.1)),
                    Text(name, style: nameStyle.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              ...trailing,
            ],
          ),
        ),
      ),
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
