// The conference in full screen: every participant as a video tile, the host
// as one more tile "You", and the controls that act on the room.
//
// Two pages of the call screen's routes on a phone
// (view/conference_full_screen_pages.dart): the tiles, opened by the round
// button of the conference panel's header, and one participant, opened by a
// tap on his tile - the same toolbar and control bar, with [callId] naming
// the participant. CallScreenHandset closes them when they stop applying;
// back - the arrow or the system Back - is the router's. The page on top says
// who left. What each control does arrives in CallScreenParams, as for the
// default screen; the colours are the call screen's style (CallScreenStyles).
import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';
import '../view/call_screen_style.dart';
import '../view/call_screen_styles.dart';
import 'call_action_button.dart';
import 'call_controls.dart';
import 'call_row_frame.dart';
import 'conference_panel.dart';
import 'conference_participant_camera.dart';
import 'popup_menu.dart';

class ConferenceFullScreen extends StatefulWidget {
  const ConferenceFullScreen({
    super.key,
    required this.params,
    required this.onBack,
    required this.onParticipantOpened,
    required this.onKeypad,
    this.callId,
    this.covered = false,
  });

  final CallScreenParams params;

  /// Whether a participant's page lies over these tiles: they are not seen,
  /// and hold no cameras - each would keep a renderer decoding for nothing.
  final bool covered;

  /// The participant this page is about, by call id; `null` for the tiles.
  final String? callId;

  /// Back: to the tiles from a participant, to the default screen from them.
  final VoidCallback onBack;

  /// A tap on a participant's tile.
  final ValueChanged<String> onParticipantOpened;

  /// The keypad of More: shown on the default screen.
  final VoidCallback onKeypad;

  @override
  State<ConferenceFullScreen> createState() => _ConferenceFullScreenState();
}

class _ConferenceFullScreenState extends State<ConferenceFullScreen> {
  /// The short notice of who left, shown over the tiles for a while.
  String? _notice;
  int _noticeSerial = 0;

  static const _noticeDuration = Duration(seconds: 3);

  /// A tile keeps its picture when a participant before it leaves and it
  /// moves to another row: its renderer goes with it rather than being made
  /// again, which would show the avatar until the next frame.
  final _tileKeys = <String, GlobalKey>{};
  final _selfTileKey = GlobalKey();

  GlobalKey _tileKey(String callId) => _tileKeys.putIfAbsent(callId, GlobalKey.new);

  /// The participant this page was last built for, kept for the moment the
  /// page leaves after him: it shows him to the end of its transition rather
  /// than the tiles.
  _OpenParticipant? _lastOpen;

  @override
  void didUpdateWidget(covariant ConferenceFullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.params.conference.legs.keys.toSet();
    final now = widget.params.conference.legs.keys.toSet();
    final left = before.difference(now);
    _tileKeys.removeWhere((callId, _) => !now.contains(callId));
    if (left.isEmpty || !_onTop(left)) return;
    final names = [
      for (final callId in left)
        oldWidget.params.activeCalls.firstWhereOrNull((call) => call.callId == callId)?.nameOrNumber ?? callId,
    ];
    _showNotice(names.map((name) => context.l10n.call_ConferenceFullScreen_participantLeft(name)).join('\n'));
  }

  /// Whether this page is the one seen once [left] have gone: a participant's
  /// page unless it is his own, leaving with him; the tiles unless a page is
  /// over them.
  bool _onTop(Set<String> left) {
    final callId = widget.callId;
    return callId == null ? !widget.covered : !left.contains(callId);
  }

  void _showNotice(String text) {
    final serial = ++_noticeSerial;
    _notice = text;
    Future<void>.delayed(_noticeDuration, () {
      if (mounted && serial == _noticeSerial) setState(() => _notice = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final infoStyle = style?.callInfo;
    final themeData = Theme.of(context);
    final colors = themeData.colorScheme;
    final foreground = infoStyle?.callStatus?.color ?? colors.onSurface;
    // What sits on a picture - the corner controls, the names - keeps clear
    // of it on the theme's scrim.
    final overlay = colors.scrim.withValues(alpha: 0.38);
    final textStyle = infoStyle?.callStatus ?? themeData.textTheme.bodyMedium;
    final conference = params.conference;
    final legs = conference.legs.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final covered = widget.covered;

    _OpenParticipant participantOf(int index, MapEntry<String, int> leg) => _OpenParticipant(
      index: index,
      callId: leg.key,
      call: params.activeCalls.firstWhereOrNull((call) => call.callId == leg.key),
      video: covered ? null : conference.videoOfLine(leg.value),
      muted: conference.participantMuted(leg.key),
      ready: conference.isReady(leg.key),
    );

    _ParticipantTile tileOf(_OpenParticipant participant, {bool large = false}) => _ParticipantTile(
      key: _tileKey(participant.callId),
      participant: participant,
      params: params,
      foreground: foreground,
      overlay: overlay,
      textStyle: textStyle,
      large: large,
      onTap: large ? null : () => widget.onParticipantOpened(participant.callId),
    );

    final callId = widget.callId;
    final openIndex = callId == null ? -1 : legs.indexWhere((leg) => leg.key == callId);
    if (openIndex >= 0) _lastOpen = participantOf(openIndex, legs[openIndex]);
    // The participant left: the page leaves after him, showing him to the end.
    final open = callId == null ? null : (openIndex >= 0 ? _lastOpen : _lastOpen?.gone());
    final Widget body;
    final String title;
    if (open != null) {
      title = open.call?.nameOrNumber ?? open.callId;
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gap),
        child: SemanticId(identifier: conferenceParticipantPageId, child: tileOf(open, large: true)),
      );
    } else {
      title = context.l10n.call_ConferencePanel_header(legs.length).toUpperCase();
      final tiles = <Widget>[
        for (final (index, leg) in legs.indexed) tileOf(participantOf(index, leg)),
        _SelfTile(
          key: _selfTileKey,
          video: covered ? null : conference.selfVideo,
          // The room's camera faces the way the legs that share it show; the
          // front one, as it is published first, where none says.
          mirror:
              params.activeCalls.firstWhereOrNull((call) => conference.isLeg(call.callId) && call.video)?.frontCamera ??
              true,
          muted: conference.selfMuted,
          foreground: foreground,
          overlay: overlay,
          textStyle: textStyle,
          onSwitchCamera: conference.selfVideo == null ? null : params.onConferenceCameraSwitched,
        ),
      ];
      body = _TileGrid(tiles: tiles);
    }

    final notice = _notice;
    // No safe area of its own: the call screen's layer already keeps the
    // controls clear of the system bars, as for the default screen.
    return Column(
      children: [
        // The call screen's own toolbar: back where it always is, the room
        // in the title, and everything under it for the video.
        AppBar(
          primary: false,
          automaticallyImplyLeading: false,
          backgroundColor: style?.appBar?.backgroundColor,
          foregroundColor: style?.appBar?.foregroundColor ?? foreground,
          leading: CallActionButton(
            label: MaterialLocalizations.of(context).backButtonTooltip,
            identifier: conferenceFullScreenBackId,
            onPressed: widget.onBack,
            style: TextButton.styleFrom(foregroundColor: foreground, shape: const CircleBorder()),
            child: const Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(fontSize: 13, letterSpacing: 1.2),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (notice != null)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 12,
                  child: Semantics(
                    liveRegion: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colors.inverseSurface, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          notice,
                          textAlign: TextAlign.center,
                          style: themeData.textTheme.bodyMedium?.copyWith(color: colors.onInverseSurface),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _ControlBar(params: params, actionsStyle: style?.actions, foreground: foreground, onKeypad: widget.onKeypad),
        const SizedBox(height: 12),
      ],
    );
  }
}

const _gap = 8.0;

/// The lowest a row of tiles may get before the grid scrolls instead of
/// squeezing the pictures further.
const _minRowHeight = 160.0;
const _tileRadius = 16.0;
const _shadows = [Shadow(blurRadius: 4)];

/// The tiles in two columns, an odd last one across the width, the rows
/// sharing all the height there is; past what fits they keep [_minRowHeight]
/// and scroll.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var i = 0; i < tiles.length; i += 2)
        Row(
          spacing: _gap,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: tiles[i]),
            if (i + 1 < tiles.length) Expanded(child: tiles[i + 1]),
          ],
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = (constraints.maxHeight - _gap * (rows.length - 1)) / rows.length;
        final rowHeight = fitted < _minRowHeight ? _minRowHeight : fitted;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: _gap),
          physics: fitted < _minRowHeight ? null : const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: _gap),
          itemBuilder: (context, index) => SizedBox(height: rowHeight, child: rows[index]),
        );
      },
    );
  }
}

/// One participant as a page of the room shows him: his leg, his call and his
/// camera, what the room says of his microphone.
@immutable
class _OpenParticipant {
  const _OpenParticipant({
    required this.index,
    required this.callId,
    required this.call,
    required this.video,
    required this.muted,
    required this.ready,
  });

  final int index;
  final String callId;
  final ActiveCall? call;
  final ParticipantCamera? video;
  final bool muted;
  final bool ready;

  /// The same participant once he has left: nothing of him can be acted on,
  /// and his camera is gone with him.
  _OpenParticipant gone() =>
      _OpenParticipant(index: index, callId: callId, call: call, video: null, muted: muted, ready: false);
}

/// The frame every tile shares: the picture or the avatar, the name at the
/// bottom, the controls in the top corners. A tile that opens its participant
/// is one tap target (SemanticAction.button), the corner controls each their
/// own beside it; one that opens nothing is an anchor.
class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.name,
    required this.video,
    required this.placeholder,
    required this.foreground,
    required this.textStyle,
    required this.identifier,
    this.topLeft,
    this.topRight,
    this.onTap,
    this.fit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.mirror = false,
  });

  final String name;
  final ParticipantCamera? video;
  final Widget placeholder;
  final Color foreground;
  final TextStyle? textStyle;
  final String identifier;
  final Widget? topLeft;
  final Widget? topRight;
  final VoidCallback? onTap;
  final RTCVideoViewObjectFit fit;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    // Named once, by [name]: the avatar under the camera says nothing of its own.
    final picture = ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_tileRadius),
        child: ColoredBox(
          color: foreground.withValues(alpha: 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ParticipantVideo(camera: video, placeholder: placeholder, fit: fit, mirror: mirror),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: ExcludeSemantics(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle?.copyWith(color: foreground, fontWeight: FontWeight.w600, shadows: _shadows),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (onTap == null)
          SemanticId(
            identifier: identifier,
            child: Semantics(label: name, child: picture),
          )
        else
          SemanticAction.button(
            label: name,
            identifier: identifier,
            child: GestureDetector(onTap: onTap, child: picture),
          ),
        if (topLeft case final topLeft?) Positioned(left: 4, top: 4, child: topLeft),
        if (topRight case final topRight?) Positioned(right: 4, top: 4, child: topRight),
      ],
    );
  }
}

/// A participant: mute for everyone at the top left, a menu holding End their
/// call at the top right - mute and end are never side by side. A tap opens
/// his page; [large] is that page.
class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    super.key,
    required this.participant,
    required this.params,
    required this.foreground,
    required this.overlay,
    required this.textStyle,
    required this.large,
    required this.onTap,
  });

  final _OpenParticipant participant;
  final CallScreenParams params;
  final Color foreground;
  final Color overlay;
  final TextStyle? textStyle;
  final bool large;
  final VoidCallback? onTap;

  void _mute() => params.onConferenceParticipantMuted?.call(participant.callId, !participant.muted);

  void _hangup() => params.onConferenceParticipantHangup?.call(participant.callId);

  @override
  Widget build(BuildContext context) {
    final call = participant.call;
    final index = participant.index;
    final muted = participant.muted;
    final name = call?.nameOrNumber ?? participant.callId;
    return _TileFrame(
      identifier: numberedId(conferenceTileId, index),
      name: name,
      video: participant.video,
      foreground: foreground,
      textStyle: textStyle,
      onTap: onTap,
      fit: large
          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
          : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      placeholder: call == null
          ? const SizedBox.shrink()
          : Transform.scale(
              scale: large ? 4 : 2.5,
              child: CallRowAvatar(call: call, contactResolver: params.contactResolver),
            ),
      topLeft: _RoundIcon(
        label: muted
            ? context.l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
            : context.l10n.call_SemanticsLabel_conferenceParticipantMute(name),
        identifier: numberedId(conferenceTileMuteId, index),
        icon: muted ? Icons.mic_off : Icons.mic,
        foreground: foreground,
        overlay: overlay,
        onPressed: participant.ready ? _mute : null,
      ),
      topRight: DecoratedBox(
        decoration: BoxDecoration(color: overlay, shape: BoxShape.circle),
        child: ConferenceParticipantMenu(
          name: name,
          index: index,
          style: (textStyle ?? DefaultTextStyle.of(context).style).copyWith(color: foreground),
          endColor: Theme.of(context)
              .extension<CallScreenStyles>()
              ?.primary
              ?.actions
              ?.hangup
              ?.backgroundColor
              ?.resolve(const {}),
          shadows: _shadows,
          onHangup: _hangup,
        ),
      ),
    );
  }
}

/// The host: his own camera as the room gets it, with the camera switch, or a
/// plain tile without it.
class _SelfTile extends StatelessWidget {
  const _SelfTile({
    super.key,
    required this.video,
    required this.mirror,
    required this.muted,
    required this.foreground,
    required this.overlay,
    required this.textStyle,
    this.onSwitchCamera,
  });

  /// This client's own camera as the room gets it; `null` while it is not published.
  final MediaStream? video;

  /// Whether the camera is the front one, shown mirrored as the local preview is.
  final bool mirror;
  final bool muted;
  final Color foreground;
  final Color overlay;
  final TextStyle? textStyle;
  final VoidCallback? onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      identifier: conferenceSelfTileId,
      name: context.l10n.call_ConferencePanel_you,
      // This client's own camera: a local stream of one video track; a
      // stream without one has nothing to show.
      video: switch (video?.getVideoTracks().firstOrNull?.id) {
        final trackId? => ParticipantCamera(stream: video!, trackId: trackId),
        null => null,
      },
      mirror: mirror,
      foreground: foreground,
      textStyle: textStyle,
      placeholder: Icon(Icons.person, size: 48, color: foreground.withValues(alpha: 0.6)),
      topLeft: muted
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.mic_off, size: 20, color: foreground, shadows: _shadows),
            )
          : null,
      topRight: onSwitchCamera == null
          ? null
          : _RoundIcon(
              label: context.l10n.call_ConferenceFullScreen_switchCamera,
              identifier: conferenceSelfTileSwitchId,
              icon: Icons.cameraswitch_outlined,
              foreground: foreground,
              overlay: overlay,
              onPressed: onSwitchCamera,
            ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.label,
    required this.identifier,
    required this.icon,
    required this.foreground,
    required this.overlay,
    required this.onPressed,
  });

  final String label;
  final String identifier;
  final IconData icon;
  final Color foreground;
  final Color overlay;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CallActionButton(
      label: label,
      identifier: identifier,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        backgroundColor: overlay,
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.3),
      ),
      child: Icon(icon, size: 20),
    );
  }
}

/// The room's controls: mic, camera, speaker, add participant, More, end of
/// the conference. No hold, transfer or calls outside the room on the bar;
/// More holds the keypad, the camera switch and hold, disabled in a room. The
/// toggles take the default screen's styles (CallScreenActionsStyle), switched
/// on through the selected state as there.
class _ControlBar extends StatefulWidget {
  const _ControlBar({
    required this.params,
    required this.actionsStyle,
    required this.foreground,
    required this.onKeypad,
  });

  final CallScreenParams params;
  final CallScreenActionsStyle? actionsStyle;
  final Color foreground;
  final VoidCallback onKeypad;

  @override
  State<_ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<_ControlBar> {
  static const _size = 56.0;

  final _mic = WidgetStatesController();
  final _camera = WidgetStatesController();
  final _speaker = WidgetStatesController();

  @override
  void dispose() {
    _mic.dispose();
    _camera.dispose();
    _speaker.dispose();
    super.dispose();
  }

  CallScreenParams get _params => widget.params;

  void _toggleSpeaker() {
    final speakerOn = _params.audioDevice?.type == CallAudioDeviceType.speaker;
    final target = speakerOn ? _params.availableAudioDevices.getEarpiece : _params.availableAudioDevices.getSpeaker;
    if (target != null) _params.onAudioDeviceChanged(target);
  }

  void _toggleSelfMute() => _params.onConferenceSelfMuted?.call(!_params.conference.selfMuted);

  void _toggleCamera() => _params.onConferenceCameraChanged?.call(_params.conference.selfVideo == null);

  /// A round button of the bar in [themed], the default screen's style of the
  /// same control; where the theme says nothing, the bar's own, from the
  /// screen's foreground and the palette.
  ButtonStyle _round(ButtonStyle? themed) {
    final foreground = widget.foreground;
    final colors = Theme.of(context).colorScheme;
    final fallback = ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? foreground.withValues(alpha: 0.3)
            : states.contains(WidgetState.selected)
            ? colors.surface
            : foreground,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? foreground : foreground.withValues(alpha: 0.12),
      ),
    );
    return (themed ?? fallback).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(_size, _size)),
      fixedSize: const WidgetStatePropertyAll(Size(_size, _size)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: const WidgetStatePropertyAll(CircleBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = _params;
    final actionsStyle = widget.actionsStyle;
    final themeData = Theme.of(context);
    final conference = params.conference;
    final selfMuted = conference.selfMuted;
    final cameraOn = conference.selfVideo != null;
    final enabled = params.interactionsEnabled;
    final speakerOn = params.audioDevice?.type == CallAudioDeviceType.speaker;
    final textStyle = themeData.textTheme.bodyMedium;
    final iconColor = textStyle?.color;
    final plain = _round(null).copyWith(
      foregroundColor: WidgetStatePropertyAll(widget.foreground),
      backgroundColor: WidgetStatePropertyAll(widget.foreground.withValues(alpha: 0.12)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CallActionButton(
            label: selfMuted ? context.l10n.call_CallActionsTooltip_unmute : context.l10n.call_CallActionsTooltip_mute,
            identifier: conferenceFullScreenMicId,
            onPressed: params.onConferenceSelfMuted == null || !enabled ? null : _toggleSelfMute,
            statesController: _mic..update(WidgetState.selected, selfMuted),
            style: _round(actionsStyle?.muted),
            child: Icon(selfMuted ? Icons.mic_off : Icons.mic),
          ),
          CallActionButton(
            label: cameraOn
                ? context.l10n.call_CallActionsTooltip_disableCamera
                : context.l10n.call_CallActionsTooltip_enableCamera,
            identifier: conferenceFullScreenCameraId,
            onPressed: params.onConferenceCameraChanged == null || !enabled ? null : _toggleCamera,
            statesController: _camera..update(WidgetState.selected, cameraOn),
            style: _round(actionsStyle?.camera),
            child: Icon(cameraOn ? Icons.videocam : Icons.videocam_off),
          ),
          if (params.availableAudioDevices.onlyBuiltIn)
            CallActionButton(
              label: speakerOn
                  ? context.l10n.call_CallActionsTooltip_disableSpeaker
                  : context.l10n.call_CallActionsTooltip_enableSpeaker,
              identifier: conferenceFullScreenSpeakerId,
              onPressed: _toggleSpeaker,
              statesController: _speaker..update(WidgetState.selected, speakerOn),
              style: _round(actionsStyle?.speaker),
              child: Icon(speakerOn ? Icons.volume_up : Icons.phone_in_talk),
            )
          else
            CallActionMenuButton<CallAudioDevice>(
              identifier: conferenceFullScreenSpeakerId,
              label: context.l10n.call_CallActionsTooltip_changeAudioDevice,
              statesController: _speaker
                ..update(WidgetState.selected, params.audioDevice?.type != CallAudioDeviceType.earpiece),
              style: _round(actionsStyle?.speaker),
              onSelected: params.onAudioDeviceChanged,
              items: [
                for (final device in params.availableAudioDevices)
                  CallPopupMenuItem<CallAudioDevice>(
                    value: device,
                    text: device.l10n(context),
                    icon: Icon(device.type.icon, size: 20, color: iconColor),
                    textStyle: textStyle,
                  ),
              ],
              child: Icon(params.audioDevice?.type.icon ?? Icons.volume_off),
            ),
          CallActionButton(
            label: context.l10n.call_CallActionsTooltip_addParticipant,
            identifier: conferenceFullScreenAddId,
            onPressed: params.addParticipantAvailability.enabled && enabled ? params.onAddParticipant : null,
            style: plain,
            child: const Icon(Icons.person_add_alt_1),
          ),
          CallActionMenuButton<void>(
            identifier: conferenceFullScreenMoreId,
            label: context.l10n.call_Watch_more,
            style: plain,
            items: [
              CallPopupMenuItem<void>(
                identifier: conferenceFullScreenKeypadId,
                onTap: widget.onKeypad,
                text: context.l10n.call_Watch_keypad,
                icon: Icon(Icons.dialpad, size: 20, color: iconColor),
                textStyle: textStyle,
              ),
              CallPopupMenuItem<void>(
                identifier: conferenceFullScreenSwitchCameraId,
                enabled: cameraOn && params.onConferenceCameraSwitched != null,
                onTap: params.onConferenceCameraSwitched,
                text: context.l10n.call_ConferenceFullScreen_switchCamera,
                icon: Icon(Icons.cameraswitch_outlined, size: 20, color: iconColor),
                textStyle: textStyle,
              ),
              // A room's legs are never held (docs/call-hold-policy): shown,
              // so the menu reads the same everywhere, and disabled.
              CallPopupMenuItem<void>(
                identifier: conferenceFullScreenHoldId,
                enabled: false,
                text: context.l10n.call_Watch_hold,
                icon: Icon(Icons.pause, size: 20, color: iconColor),
                textStyle: textStyle,
              ),
            ],
            child: const Icon(Icons.more_horiz),
          ),
          // It ends the room, as the default screen's hangup does while the
          // focused call is a leg, and says so.
          CallActionButton(
            label: context.l10n.call_SemanticsLabel_conferenceEnd,
            identifier: conferenceFullScreenEndId,
            onPressed: params.onHangup,
            style: _round(actionsStyle?.hangup),
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}
