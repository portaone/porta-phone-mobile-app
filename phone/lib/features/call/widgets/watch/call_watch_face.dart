// The call on a watch face: the face itself (CallWatchFace) - ringing, being
// placed or answered - the in-call keypad, and what the call screen's watch
// pages read (CallWatchScope, CallWatchVideoOptions). Hosted by
// CallScreenWatch (view/call_screen_watch.dart); the other pages are in
// call_watch_menus.dart.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../extensions/extensions.dart';
import '../../models/models.dart';
import '../../view/call_screen_style.dart';
import '../../view/call_screen_styles.dart';
import '../call_action_availability.dart';
import '../call_controls.dart';
import '../call_toolbar_status.dart';
import '../remote_video_view_overlay.dart';
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

/// What the call screen's watch pages read: the controls the screen hands
/// over, rebuilt with every change of the calls.
class CallWatchScope extends InheritedWidget {
  const CallWatchScope({
    super.key,
    required this.params,
    required this.video,
    required this.callStatus,
    required super.child,
  });

  final CallScreenParams params;
  final CallWatchVideoOptions video;
  final CallStatus callStatus;

  static CallWatchScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CallWatchScope>()!;

  @override
  bool updateShouldNotify(CallWatchScope oldWidget) =>
      params != oldWidget.params || video != oldWidget.video || callStatus != oldWidget.callStatus;
}

/// The call itself: ringing, being placed, or answered.
class CallWatchFace extends StatelessWidget {
  const CallWatchFace({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CallWatchScope.of(context);
    final params = scope.params;
    if (params.focusedCall.isIncomingRinging) return _Incoming(params: params);
    if (!params.focusedCall.wasAccepted) return _Outgoing(params: params);
    return _Active(params: params, callStatus: scope.callStatus, onOpen: (route) => context.router.push(route));
  }
}

/// A ringing call: who it is, and Decline and Answer - two equal choices,
/// decline on the left as on Wear OS, and no edge button, since neither is
/// the safe default. With another call live, a line says what answering does
/// to it.
class _Incoming extends StatelessWidget {
  const _Incoming({required this.params});

  final CallScreenParams params;

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

  final CallScreenParams params;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final call = params.focusedCall;
    final onCall = Theme.of(context).colorScheme.surface;
    final side = context.isSmallWatch ? 44.0 : 52.0;

    return WatchEdgeLayout(
      padding: context.watchContentPadding(),
      edge: (context, overlay) =>
          CallWatchHangupButton(overlay: overlay, onPressed: params.onHangup, style: style?.actions?.hangup),
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

  final CallScreenParams params;
  final CallStatus callStatus;
  final ValueChanged<PageRouteInfo> onOpen;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final actions = CallActionAvailability(params);
    final call = params.focusedCall;
    final muted = actions.muted;
    final onMutedChanged = actions.onMutedChanged;
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
      edge: (context, overlay) => CallWatchHangupButton(
        overlay: overlay,
        onPressed: params.onHangup,
        style: style?.actions?.hangup,
        // While a room stands its hangup ends the room, and says so.
        label: actions.focusedIsLeg ? context.l10n.call_SemanticsLabel_conferenceEnd : null,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CallToolbarStatus(
            voiceNoiseReductionFailed: params.voiceNoiseReductionFailed,
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
                onPressed: onMutedChanged == null ? null : () => onMutedChanged(!muted),
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
                  onPressed: () => onOpen(const CallWatchAudioScreenPageRoute()),
                ),
              WatchRoundButton(
                icon: const Icon(Icons.more_horiz),
                caption: context.l10n.call_Watch_more,
                label: context.l10n.call_settings_additional_options,
                identifier: callActionsOptionsId,
                tone: WatchRoundTone.onDark,
                onPressed: () => onOpen(const CallWatchMoreScreenPageRoute()),
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

  final CallScreenParams params;

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
            CallWatchHangupButton(overlay: overlay, onPressed: params.onHangup, style: style?.actions?.hangup),
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
