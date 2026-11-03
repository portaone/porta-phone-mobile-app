import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../extensions/extensions.dart';
import '../../models/models.dart';
import '../../view/call_screen_style.dart';
import '../../view/call_screen_styles.dart';
import '../call_controls.dart';
import '../call_action_availability.dart';
import '../call_toolbar_status.dart';
import '../remote_video_view_overlay.dart';
import 'call_watch_menus.dart';
import 'call_watch_parts.dart';

/// How the remote picture is shown, and the camera switch: what the phone
/// offers in its toolbar menu and its preview, which the watch offers under
/// More. The screen owns all of it.
class CallWatchVideoOptions {
  const CallWatchVideoOptions({
    required this.fit,
    required this.onFitToggled,
    required this.backgroundMode,
    required this.onBackgroundToggled,
    this.onCameraSwitched,
  });

  final RTCVideoViewObjectFit fit;
  final VoidCallback onFitToggled;
  final VideoBackgroundMode backgroundMode;
  final VoidCallback onBackgroundToggled;

  /// Switches the front and the rear camera; null while the camera is off or
  /// its side is not known yet.
  final VoidCallback? onCameraSwitched;
}

/// The pages a watch call opens from its face. Each is the whole face, and
/// going back returns to the call.
enum CallWatchPage { call, more, audio, transfer, calls, conference }

/// The call on a watch face.
///
/// The phone's call screen holds about seventy functions; a face holds a
/// name, a line under it, three controls and the end button. So the face
/// keeps what a call needs every minute - mute, the audio route, more - and
/// moves the rest one tap away: a grid of the call's other actions, the audio
/// devices, the transfer menu, the calls, the room. A ringing call takes the
/// face with its two choices, and the in-call keypad takes it while open.
///
/// Like [CallControls] it only presents: what each control does arrives in
/// [params] from the screen, which keeps the state, the remote picture and
/// the hiding of the controls over it.
class CallControlsWatch extends StatefulWidget {
  const CallControlsWatch({super.key, required this.callStatus, required this.params, required this.video});

  final CallStatus callStatus;
  final CallControlsParams params;
  final CallWatchVideoOptions video;

  @override
  State<CallControlsWatch> createState() => _CallControlsWatchState();
}

class _CallControlsWatchState extends State<CallControlsWatch> {
  CallWatchPage _page = CallWatchPage.call;

  /// The room's participant whose actions are open, on the room's page.
  String? _participant;

  @override
  void didUpdateWidget(covariant CallControlsWatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page is about the call it was opened for: when the focus moves - a
    // ringing call taking it, the call ending - the face shows the new one.
    if (oldWidget.params.focusedCall.callId != widget.params.focusedCall.callId) {
      _page = CallWatchPage.call;
      _participant = null;
      return;
    }
    _page = _stillOpen(_page);
    // A participant is open only on the room's page, and only while they are
    // still in it.
    final participant = _participant;
    if (_page != CallWatchPage.conference || (participant != null && !widget.params.conference.isLeg(participant))) {
      _participant = null;
    }
  }

  /// [page] as the calls stand now: the calls become the room once they are
  /// merged, as on the phone, and a page that no longer applies - the calls
  /// with one call left, the room once it has ended - gives way to the call.
  CallWatchPage _stillOpen(CallWatchPage page) {
    final params = widget.params;
    return switch (page) {
      CallWatchPage.calls when params.conference.isPresent => CallWatchPage.conference,
      CallWatchPage.calls when params.activeCalls.length < 2 => CallWatchPage.call,
      CallWatchPage.conference when !params.conference.isPresent => CallWatchPage.call,
      _ => page,
    };
  }

  void _open(CallWatchPage page) => setState(() => _page = page);

  void _back() => setState(() {
    if (_participant != null) {
      _participant = null;
    } else {
      _page = CallWatchPage.call;
    }
  });

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final ringing = params.focusedCall.isIncomingRinging;
    final keypad = params.keypadShown && !ringing;
    final page = ringing ? CallWatchPage.call : _page;
    final atRoot = !keypad && page == CallWatchPage.call && _participant == null;

    final Widget face;
    if (keypad) {
      face = CallWatchKeypad(params: params);
    } else if (page != CallWatchPage.call) {
      face = switch (page) {
        CallWatchPage.more => CallWatchMore(params: params, video: widget.video, onOpen: _open),
        CallWatchPage.audio => CallWatchAudio(params: params, onDone: _back),
        CallWatchPage.transfer => CallWatchTransfer(params: params, onDone: _back),
        CallWatchPage.calls => CallWatchCalls(params: params, onDone: _back),
        CallWatchPage.conference => CallWatchConference(
          params: params,
          participant: _participant,
          onParticipantOpened: _openParticipant,
          onDone: _back,
        ),
        CallWatchPage.call => const SizedBox.shrink(),
      };
    } else if (ringing) {
      face = _Incoming(params: params);
    } else if (!params.focusedCall.wasAccepted) {
      face = _Outgoing(params: params);
    } else {
      face = _Active(params: params, callStatus: widget.callStatus, onOpen: _open);
    }

    // Back from a page returns to the call; back from the call leaves the
    // screen, as on the phone, and the call goes on behind the hub.
    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _onBack(keypad),
      child: face,
    );
  }

  void _openParticipant(String callId) => setState(() => _participant = callId);

  void _onBack(bool keypad) => keypad ? widget.params.onKeypadToggle(false) : _back();
}

/// A ringing call: who it is, and Decline and Answer - two equal choices,
/// decline on the left as on Wear OS, and no edge button, since neither is
/// the safe default. With another call live, a line says what answering does
/// to it.
class _Incoming extends StatelessWidget {
  const _Incoming({required this.params});

  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final colorScheme = Theme.of(context).colorScheme;
    final actions = CallActionAvailability(params);
    final call = params.focusedCall;
    final others = actions.othersOnAnswer;
    final held = actions.heldOnAnswer;
    final side = context.isSmallWatch ? 48.0 : 56.0;
    // Answering changes only the calls still live: one already on hold stays
    // as it is, and the phone leaves it out too.
    final toHold = held.where((call) => !call.held).map((call) => call.nameOrNumber).toList();
    final hint = others.isEmpty
        ? null
        : held.isNotEmpty
        ? (toHold.isEmpty ? null : context.l10n.call_FocusedActionHint_willBeHeld(toHold.join(', ')))
        : context.l10n.call_FocusedActionHint_willBeEnded(others.map((call) => call.nameOrNumber).join(', '));

    return Padding(
      padding: EdgeInsets.only(top: context.watchContentPadding().top),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Sides(child: CallWatchHeader(call: call)),
          SizedBox(height: context.adaptiveMetrics.gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: side / 2,
            children: [
              WatchRoundButton(
                icon: const Icon(Icons.call_end),
                label: context.l10n.call_CallActionsTooltip_hangup,
                identifier: callActionsHangupId,
                buttonKey: callActionsHangupKey,
                tone: WatchRoundTone.onDark,
                size: side,
                style: _choice(style?.actions?.hangup, colorScheme.error, colorScheme.onError),
                onPressed: params.onHangup,
              ),
              WatchRoundButton(
                icon: Icon(call.remoteVideo && !call.held ? Icons.videocam : Icons.call),
                label: context.l10n.call_CallActionsTooltip_accept,
                identifier: callActionsAcceptId,
                tone: WatchRoundTone.onDark,
                size: side,
                style: _choice(style?.actions?.callStart, colorScheme.tertiary, colorScheme.onTertiary),
                onPressed: actions.onAccept,
              ),
            ],
          ),
          if (hint != null)
            _Sides(
              child: Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.surface),
              ),
            ),
        ],
      ),
    );
  }

  /// The theme's colours for the choice, or the scheme's the phone's theme
  /// falls back to: the face's light round style would make both choices
  /// look alike.
  ButtonStyle _choice(ButtonStyle? themed, Color background, Color foreground) {
    return IconButton.styleFrom(
      backgroundColor: themed?.backgroundColor?.resolve(const {}) ?? background,
      foregroundColor: themed?.foregroundColor?.resolve(const {}) ?? foreground,
    );
  }
}

/// An outgoing call until it is answered: who it is, the step under way, and
/// ending it - the only thing to do - as the edge button.
class _Outgoing extends StatelessWidget {
  const _Outgoing({required this.params});

  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final call = params.focusedCall;
    final onCall = Theme.of(context).colorScheme.surface;
    final side = context.isSmallWatch ? 44.0 : 52.0;

    return WatchEdgeLayout(
      padding: context.watchContentPadding(),
      edge: (context, overlay) =>
          callWatchHangupButton(context, overlay, onPressed: params.onHangup, style: style?.actions?.hangup),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallWatchHeader(call: call),
          SizedBox(height: context.adaptiveMetrics.gap * 2),
          ExcludeSemantics(
            child: CircleAvatar(
              radius: side / 2,
              backgroundColor: onCall.withValues(alpha: 0.25),
              foregroundColor: onCall,
              child: Text(
                _initials(call.nameOrNumber),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onCall, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(2);
    return words.map((word) => word.characters.first.toUpperCase()).join();
  }
}

/// The answered call: the connection, who it is and for how long, then
/// Mute, the audio route and More, and the end button along the bottom.
class _Active extends StatelessWidget {
  const _Active({required this.params, required this.callStatus, required this.onOpen});

  final CallControlsParams params;
  final CallStatus callStatus;
  final ValueChanged<CallWatchPage> onOpen;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final actions = CallActionAvailability(params);
    final call = params.focusedCall;
    final muted = actions.muted;
    final speakerOn = params.audioDevice?.type == CallAudioDeviceType.speaker;

    return WatchEdgeLayout(
      // Only the top: the controls sit across the middle, where a round face
      // is widest; the lines above them keep to the content's sides.
      padding: EdgeInsets.only(top: context.watchContentPadding().top),
      // Over a picture, a scrim keeps the name and the controls legible.
      backdrop: params.remotePictureShown
          ? const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C000000), Color(0x00000000), Color(0x00000000), Color(0x73000000)],
                  stops: [0, 0.34, 0.52, 1],
                ),
              ),
            )
          : null,
      edge: (context, overlay) => callWatchHangupButton(
        context,
        overlay,
        onPressed: params.onHangup,
        style: style?.actions?.hangup,
        // While a room stands its hangup ends the room, and says so.
        label: actions.focusedIsLeg ? context.l10n.call_SemanticsLabel_conferenceEnd : null,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallToolbarStatus(
            callStatus: callStatus,
            networkQuality: params.activeCalls.worstNetworkQuality,
            iceConnectionIssue: params.activeCalls.firstIceConnectionIssue,
            // The phone's status line, at the face's size.
            style: CallInfoStyle(
              callStatus: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w600),
            ),
          ),
          _Sides(child: CallWatchHeader(call: call)),
          SizedBox(height: context.adaptiveMetrics.gap * 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: context.isSmallWatch ? 2 : 8,
            children: [
              WatchRoundButton(
                icon: Icon(muted ? Icons.mic_off : Icons.mic),
                caption: context.l10n.call_Watch_mute,
                label: muted ? context.l10n.call_CallActionsTooltip_unmute : context.l10n.call_CallActionsTooltip_mute,
                identifier: callActionsMuteId,
                buttonKey: callActionsMuteKey,
                tone: WatchRoundTone.onDark,
                emphasis: muted ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
                onPressed: () => params.onMutedChanged(!muted),
              ),
              if (params.availableAudioDevices.onlyBuiltIn)
                WatchRoundButton(
                  icon: Icon(speakerOn ? Icons.volume_up : Icons.phone_in_talk),
                  caption: context.l10n.call_Watch_speaker,
                  label: speakerOn
                      ? context.l10n.call_CallActionsTooltip_disableSpeaker
                      : context.l10n.call_CallActionsTooltip_enableSpeaker,
                  identifier: callActionsSpeakerId,
                  buttonKey: callActionsSpeakerKey,
                  tone: WatchRoundTone.onDark,
                  emphasis: speakerOn ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
                  onPressed: _toggleSpeaker,
                )
              else
                WatchRoundButton(
                  icon: Icon(params.audioDevice?.type.icon ?? Icons.volume_off),
                  caption: context.l10n.call_Watch_audio,
                  label: context.l10n.call_CallActionsTooltip_changeAudioDevice,
                  identifier: callActionsAudioDeviceId,
                  tone: WatchRoundTone.onDark,
                  onPressed: () => onOpen(CallWatchPage.audio),
                ),
              WatchRoundButton(
                icon: const Icon(Icons.more_horiz),
                caption: context.l10n.call_Watch_more,
                label: context.l10n.call_settings_additional_options,
                identifier: callActionsOptionsId,
                tone: WatchRoundTone.onDark,
                onPressed: () => onOpen(CallWatchPage.more),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Moves the sound between the speaker and the earpiece. The button stays
  /// enabled when the other device is missing, as on the phone: a watch with
  /// a speaker only would otherwise lose one of its three controls for good.
  void _toggleSpeaker() {
    final speakerOn = params.audioDevice?.type == CallAudioDeviceType.speaker;
    final target = speakerOn ? params.availableAudioDevices.getEarpiece : params.availableAudioDevices.getSpeaker;
    if (target != null) params.onAudioDeviceChanged(target);
  }
}

/// The in-call keypad: the digits sent so far on top, twelve keys filling
/// the face, and a thin end button. Back closes it.
class CallWatchKeypad extends StatelessWidget {
  const CallWatchKeypad({super.key, required this.params});

  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final style = themeData.extension<CallScreenStyles>()?.primary;

    return Material(
      color: themeData.scaffoldBackgroundColor,
      child: WatchEdgeLayout(
        compact: true,
        padding: context.watchContentPadding().copyWith(
          top: context.isRoundScreen ? MediaQuery.sizeOf(context).height * 0.09 : 8,
          bottom: 0,
        ),
        edge: (context, overlay) =>
            callWatchHangupButton(context, overlay, onPressed: params.onHangup, style: style?.actions?.hangup),
        body: Column(
          children: [
            ValueListenableBuilder<String>(
              valueListenable: params.dtmfInput,
              builder: (context, digits, _) => Text(
                digits,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.center,
                style: themeData.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Tones have no alternates: a held 0 sends 0, as on the phone.
            Expanded(
              child: WatchKeyGrid(
                keys: watchDialKeys,
                onPressed: params.interactionsEnabled ? params.onKeyPressed : null,
                alternates: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The content's sides of the face, for the lines of text above and below
/// the controls.
class _Sides extends StatelessWidget {
  const _Sides({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = context.watchContentPadding();
    return Padding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      child: child,
    );
  }
}
