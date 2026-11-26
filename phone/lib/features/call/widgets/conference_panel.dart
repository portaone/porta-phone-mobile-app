import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';
import '../view/call_screen_style.dart';
import '../utils/contact_resolver.dart';
import 'call_action_button.dart';
import 'call_row_frame.dart';
import 'conference_participant_camera.dart';
import 'popup_menu.dart';
import 'speaking_frame.dart';

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
///
/// The host has no row of his own: the screen around the list is his, and
/// his microphone is the call screen's own mute, which reaches the room the
/// same way. What only a row of his could say - that the room is standing
/// aside - is a line under the header.
class ConferencePanel extends StatelessWidget {
  const ConferencePanel({
    super.key,
    required this.conference,
    required this.calls,
    required this.roomParked,
    required this.onSwitchToConference,
    required this.onParticipantMutedChanged,
    required this.onParticipantHangup,
    this.onFullScreen,
    this.contactResolver,
    this.style,
    this.listStyle,
    this.actionsStyle,
  });

  final ConferenceState conference;

  /// Every call the bloc holds; the legs are looked up here for their name and
  /// the moment they were answered.
  final List<ActiveCall> calls;

  /// Whether the room has stood aside for a call the host took outside it
  /// ([CallState.conferenceMustPark]): it neither hears him nor is heard, so
  /// the header says so and the participants' controls step back.
  final bool roomParked;

  /// Takes the user back into the room from a call they took outside it: any
  /// row of the room is that way in while the room stands aside. `null` where
  /// there is nothing to come back from.
  final ValueChanged<String>? onSwitchToConference;

  /// Mutes a participant for everyone in the room. The outcome arrives as the
  /// server's next participant list, so nothing is assumed here.
  final void Function(String callId, bool muted) onParticipantMutedChanged;

  /// Ends one participant's call, which takes them out of the room.
  final ValueChanged<String> onParticipantHangup;

  /// Opens the room in full screen, the participants as video tiles: the
  /// header's control, and a tap on a row while the room is in use; `null`
  /// leaves the header without the control.
  final VoidCallback? onFullScreen;

  /// Resolves who a leg is with, for the picture on its row.
  final ContactResolver? contactResolver;

  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  /// The screen's own button styles; ending a participant's call takes the
  /// hangup's colour, so it reads as what it is and stays themeable.
  final CallScreenActionsStyle? actionsStyle;

  @override
  Widget build(BuildContext context) {
    final legs = conference.legs.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final opensFullScreen = !roomParked && onFullScreen != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CallRowHeader(
          label: context.l10n.call_ConferencePanel_header(legs.length),
          note: roomParked ? context.l10n.call_ConferencePanel_parkedNote : null,
          noteIdentifier: conferenceParkedNoteId,
          trailing: onFullScreen == null ? null : _FullScreenButton(onPressed: onFullScreen!, style: style),
          style: style,
        ),
        for (final (index, leg) in legs.indexed)
          _ParticipantRow(
            key: ValueKey('ConferenceParticipant-${leg.key}'),
            index: index,
            call: calls.firstWhereOrNull((call) => call.callId == leg.key),
            callId: leg.key,
            camera: conference.videoOfLine(leg.value),
            // Core answers a mute for a participant it has not finished
            // wiring with line_not_ready, so the control waits for the
            // participant to appear in a list of its own.
            ready: conference.isReady(leg.key),
            muted: conference.participantMuted(leg.key),
            speaking: conference.speaks(leg.value),
            // In use, a row is the big way into the tiles; standing aside, the way back into the room.
            onTap: opensFullScreen
                ? onFullScreen
                : onSwitchToConference == null
                ? null
                : () => onSwitchToConference!(leg.key),
            tapHint: opensFullScreen ? context.l10n.call_SemanticsLabel_conferenceFullScreen : null,
            // The room is not the conversation in use, so its own controls step
            // back rather than shout from it.
            dimmed: roomParked,
            onMutedChanged: (muted) => onParticipantMutedChanged(leg.key, muted),
            onHangup: () => onParticipantHangup(leg.key),
            endColor: actionsStyle?.hangup?.backgroundColor?.resolve(const {}),
            contactResolver: contactResolver,
            style: style,
            listStyle: listStyle,
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
    required this.camera,
    required this.ready,
    required this.muted,
    required this.speaking,
    required this.onTap,
    this.tapHint,
    required this.dimmed,
    required this.onMutedChanged,
    required this.onHangup,
    this.endColor,
    required this.contactResolver,
    required this.style,
    required this.listStyle,
  });

  final int index;

  /// The call behind the leg; `null` for the moment between the server taking
  /// it out of the room and the bloc dropping the leg.
  final ActiveCall? call;
  final String callId;

  /// The participant's camera as the video room sends it; `null` without one.
  final ParticipantCamera? camera;
  final bool ready;
  final bool muted;

  /// Whether the room shows the participant as speaking: a thin border in the theme's accent round
  /// the row, and nothing else of it changes.
  final bool speaking;
  final VoidCallback? onTap;

  /// What a tap on the row does, for a screen reader, where its name alone does not say.
  final String? tapHint;

  /// Whether the room is standing aside, so this row's controls are not what
  /// the user is acting through. They keep working - a room-wide mute and
  /// ending a call still reach the room while the host is elsewhere - they
  /// simply stop competing with the conversation he is actually in.
  final bool dimmed;

  final ValueChanged<bool> onMutedChanged;
  final VoidCallback onHangup;

  /// The colour of ending a call, the screen's hangup one; the theme's error
  /// colour where the screen sets none.
  final Color? endColor;
  final ContactResolver? contactResolver;
  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  @override
  Widget build(BuildContext context) {
    final call = this.call;
    final statusStyle = style?.callStatus ?? const TextStyle();
    final acceptedTime = call?.acceptedTime;

    final name = call?.nameOrNumber ?? callId;
    final status = muted
        ? context.l10n.call_ConferencePanel_participantMuted
        : context.l10n.call_ConferencePanel_participantStatus;

    final onTap = this.onTap;
    final row = CallRowFrame(
      name: name,
      onTap: onTap,
      // The picture of whoever this leg is with, the same as a roster row -
      // a leg of a room is still a call with somebody. No state badge: the
      // row says in words whether they are muted for everyone.
      // A leg whose call is not known yet, or gone, has no picture - and no
      // camera either, which would otherwise make a picture of its own.
      leading: call == null
          ? null
          : _ParticipantPicture(index: index, call: call, camera: camera, contactResolver: contactResolver),
      // The duration stands with the status rather than beside the controls:
      // past an hour it grows to HH:MM:SS, and on a narrow screen at a large
      // text scale a trailing group of that width has nowhere to go.
      statusBuilder: (context, elapsed) => elapsed == null ? status : '$status  ${elapsed.format()}',
      since: acceptedTime,
      style: style,
      listStyle: listStyle,
      trailing: [
        // Dimmed, never disabled: the semantics are untouched, so a screen
        // reader still offers both controls with their own names.
        Opacity(
          opacity: dimmed ? _dimmedControls : 1,
          // One group, with no gap of the row's between: the menu's glyph is
          // thin, and the row's spacing on top of both tap targets would set
          // it far from the mute it belongs with.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MuteToggle(
                muted: muted,
                identifier: numberedId(conferenceParticipantMuteId, index),
                // Named, not "this participant": four rows of identical
                // destructive controls say nothing about which one they act on
                // (docs/guides/accessibility.md, naming a control that is one of many).
                label: muted
                    ? context.l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
                    : context.l10n.call_SemanticsLabel_conferenceParticipantMute(name),
                onPressed: ready ? () => onMutedChanged(!muted) : null,
                style: statusStyle,
              ),
              // End their call lives in a menu: mute and end are never side by
              // side, so a slip on one does not drop a person from the room.
              ConferenceParticipantMenu(
                name: name,
                index: index,
                onHangup: onHangup,
                style: statusStyle,
                endColor: endColor,
              ),
            ],
          ),
        ),
      ],
    );
    // Always in the stack, so that the row keeps its state when the border comes and goes; the border
    // over the row's own shape, which CallRowFrame insets by 16 and 6 dp in its box.
    final frame = Stack(
      children: [
        row,
        if (speaking)
          Positioned.fill(
            child: SpeakingFrame(
              identifier: numberedId(conferenceParticipantSpeakingId, index),
              radius: 16,
              width: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
          ),
      ],
    );
    if (onTap == null) return frame;
    // The row's own node, with its tap: the mute and the menu inside keep nodes and taps of their
    // own, which a merge of the row would swallow.
    return Semantics(
      container: true,
      button: true,
      identifier: numberedId(conferenceParticipantRowId, index),
      label: name,
      hint: tapHint,
      onTap: onTap,
      child: frame,
    );
  }
}

/// Who a participant is, on their row: the picture of whoever the leg is
/// with, and their camera over it - round and of the picture's size - while
/// the room sends one.
class _ParticipantPicture extends StatelessWidget {
  const _ParticipantPicture({
    required this.index,
    required this.call,
    required this.camera,
    required this.contactResolver,
  });

  final int index;
  final ActiveCall call;
  final ParticipantCamera? camera;
  final ContactResolver? contactResolver;

  @override
  Widget build(BuildContext context) {
    return ConferenceParticipantCamera(
      camera: camera,
      diameter: CallRowAvatar.radius * 2,
      avatar: CallRowAvatar(call: call, contactResolver: contactResolver),
      identifier: numberedId(conferenceParticipantCameraId, index),
    );
  }
}

/// The menu of one participant: End their call, the destructive control kept
/// one tap away from the mute beside it. It opens under its trigger, so a
/// second tap on the trigger does not land on End, and closes when the
/// participant's row goes - the call it would end is gone or leaving. Shared
/// by the rows and the tiles.
class ConferenceParticipantMenu extends StatefulWidget {
  const ConferenceParticipantMenu({
    super.key,
    required this.name,
    required this.index,
    required this.onHangup,
    required this.style,
    this.endColor,
    this.shadows,
  });

  /// Who the participant is, in the names of the trigger and of End.
  final String name;

  /// The participant's place in the room, numbering the automation ids.
  final int index;

  /// Ends the participant's call.
  final VoidCallback onHangup;

  /// The row's status text style; its colour is the trigger's.
  final TextStyle style;

  /// The colour of End; the theme's error colour where none is given.
  final Color? endColor;

  /// Shadows of the trigger's glyph, where it sits over a picture.
  final List<Shadow>? shadows;

  @override
  State<ConferenceParticipantMenu> createState() => _ConferenceParticipantMenuState();
}

class _ConferenceParticipantMenuState extends State<ConferenceParticipantMenu> {
  bool _open = false;
  NavigatorState? _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.maybeOf(context);
  }

  @override
  void dispose() {
    final navigator = _navigator;
    if (_open && navigator != null) {
      // The row is gone with the menu still open: a navigator cannot be told
      // to pop while the tree is being torn down, so on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.popUntil((route) => route is! PopupRoute);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = widget.style.color ?? colors.onSurface;
    return CallActionMenuButton<void>(
      label: context.l10n.call_SemanticsLabel_conferenceParticipantMenu(widget.name),
      identifier: numberedId(conferenceParticipantMenuId, widget.index),
      position: PopupMenuPosition.under,
      onOpened: () => _open = true,
      onCanceled: () => _open = false,
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        foregroundColor: color,
      ),
      items: [
        CallPopupMenuItem<void>(
          identifier: numberedId(conferenceParticipantHangupId, widget.index),
          onTap: () {
            _open = false;
            widget.onHangup();
          },
          text: context.l10n.call_SemanticsLabel_conferenceParticipantHangup(widget.name),
          icon: Icon(Icons.call_end, size: 20, color: widget.endColor ?? colors.error),
          textStyle: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
      child: Icon(Icons.more_vert, size: 20, shadows: widget.shadows),
    );
  }
}

/// The control at the right of the header that opens the room in full screen:
/// a plain glyph without a word or a ring, in a tap target of 40 dp.
class _FullScreenButton extends StatelessWidget {
  const _FullScreenButton({required this.onPressed, required this.style});

  final VoidCallback onPressed;
  final CallInfoStyle? style;

  @override
  Widget build(BuildContext context) {
    final foreground = style?.callStatus?.color ?? Theme.of(context).colorScheme.onSurface;
    return CallActionButton(
      label: context.l10n.call_SemanticsLabel_conferenceFullScreen,
      identifier: conferenceFullScreenId,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        foregroundColor: foreground,
      ),
      child: const Icon(Icons.open_in_full, size: 20),
    );
  }
}

/// How far a participant's controls step back while the room is not the
/// conversation in use. Chosen to read as "not what you are acting through"
/// while staying legible - a disabled control here is 0.3, and these are not
/// disabled.
const _dimmedControls = 0.5;

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
