import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../extensions/extensions.dart';
import '../../models/models.dart';
import '../../view/call_screen_styles.dart';
import '../call_action_availability.dart';
import '../call_controls.dart';
import 'call_controls_watch.dart';
import 'call_watch_parts.dart';

/// The call's other actions as a grid: those the call allows, a blocked one
/// dimmed while the server settles.
class CallWatchMore extends StatelessWidget {
  const CallWatchMore({super.key, required this.params, required this.video, required this.onOpen});

  final CallControlsParams params;
  final CallWatchVideoOptions video;
  final ValueChanged<CallWatchPage> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final call = params.focusedCall;
    final actions = CallActionAvailability(params);
    final onHeldChanged = actions.onHeldChanged;
    final onCameraChanged = actions.onCameraChanged;

    VoidCallback? gated(VoidCallback action) => params.interactionsEnabled ? action : null;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: WatchIconGrid(
        items: [
          WatchIconGridItem(
            icon: const Icon(Icons.dialpad),
            caption: l10n.call_Watch_keypad,
            semanticLabel: l10n.call_CallActionsTooltip_showKeypad,
            identifier: callActionsKeypadId,
            buttonKey: callActionsKeypadKey,
            onPressed: gated(() => params.onKeypadToggle(true)),
          ),
          if (onHeldChanged != null)
            WatchIconGridItem(
              icon: Icon(call.held ? Icons.play_arrow : Icons.pause),
              caption: call.held ? l10n.call_Watch_resume : l10n.call_Watch_hold,
              semanticLabel: call.held ? l10n.call_CallActionsTooltip_unhold : l10n.call_CallActionsTooltip_hold,
              identifier: callActionsHoldId,
              buttonKey: callActionsHoldKey,
              emphasis: call.held ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
              onPressed: gated(() => onHeldChanged(!call.held)),
            ),
          // Always there, as on the phone; disabled when nothing in it acts.
          WatchIconGridItem(
            icon: Icon(actions.inviteShown ? Icons.add_call : Icons.phone_forwarded),
            caption: l10n.call_Watch_transfer,
            semanticLabel: actions.inviteShown
                ? l10n.call_CallActionsTooltip_addOrTransfer
                : l10n.call_CallActionsTooltip_transfer,
            identifier: callActionsTransferMenuId,
            buttonKey: callActionsTransferMenuKey,
            onPressed: actions.transferMenuEnabled ? () => onOpen(CallWatchPage.transfer) : null,
          ),
          if (actions.cameraOffered)
            WatchIconGridItem(
              icon: Icon(call.isCameraActive ? Icons.videocam : Icons.videocam_off),
              caption: l10n.call_Watch_camera,
              semanticLabel: actions.cameraPermissionDenied
                  ? l10n.call_CallActionsTooltip_cameraPermissionDenied
                  : call.isCameraActive
                  ? l10n.call_CallActionsTooltip_disableCamera
                  : l10n.call_CallActionsTooltip_enableCamera,
              identifier: callActionsVideoCallId,
              buttonKey: callActionsVideoCallKey,
              emphasis: call.isCameraActive ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
              onPressed: actions.cameraPermissionDenied
                  ? gated(params.onCameraPermissionDeniedPressed)
                  : onCameraChanged == null
                  ? null
                  : gated(() => onCameraChanged(!call.isCameraActive)),
            ),
          if (video.onCameraSwitched case final onCameraSwitched?)
            WatchIconGridItem(
              icon: const Icon(Icons.flip_camera_ios),
              caption: l10n.call_Watch_switchCamera,
              semanticLabel: l10n.callCameraPreview_SemanticsLabel_switchCamera,
              onPressed: onCameraSwitched,
            ),
          if (params.activeCalls.length > 1 && !params.conference.isPresent)
            WatchIconGridItem(
              icon: Badge(label: Text('${params.activeCalls.length}'), child: const Icon(Icons.call_split)),
              caption: l10n.call_Watch_calls,
              onPressed: () => onOpen(CallWatchPage.calls),
            ),
          if (params.conference.isPresent)
            WatchIconGridItem(
              icon: const Icon(Icons.groups),
              caption: l10n.call_Watch_conference,
              onPressed: () => onOpen(CallWatchPage.conference),
            ),
          // How the picture is shown: only while there is one to show.
          if (params.activeCalls.shouldAutoCompact) ...[
            WatchIconGridItem(
              icon: Icon(video.fit.actionIcon),
              caption: video.fit.actionLabelL10n(context),
              onPressed: video.onFitToggled,
            ),
            if (video.fit.isContain)
              WatchIconGridItem(
                icon: Icon(video.backgroundMode.actionIcon),
                caption: l10n.call_Watch_blur,
                semanticLabel: video.backgroundMode.actionLabelL10n(context),
                onPressed: video.onBackgroundToggled,
              ),
          ],
        ],
      ),
    );
  }
}

/// The audio devices, the current one checked; choosing one returns to the
/// call.
class CallWatchAudio extends StatelessWidget {
  const CallWatchAudio({super.key, required this.params, required this.onDone});

  final CallControlsParams params;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final current = params.audioDevice;
    return WatchScrollList(
      opaque: true,
      title: context.l10n.call_Watch_audio,
      spacing: context.adaptiveMetrics.gap / 2,
      children: [
        for (final device in params.availableAudioDevices)
          WatchListTile(
            title: device.l10n(context),
            leading: Icon(device.type.icon),
            trailing: device == current ? const Icon(Icons.check) : null,
            selected: device == current,
            onTap: () => _choose(device),
          ),
      ],
    );
  }

  void _choose(CallAudioDevice device) {
    params.onAudioDeviceChanged(device);
    onDone();
  }
}

/// The phone's transfer menu as a list. Choosing whom to transfer to happens
/// in the sections, under the banner the hub already shows, as on the phone.
class CallWatchTransfer extends StatelessWidget {
  const CallWatchTransfer({super.key, required this.params, required this.onDone});

  final CallControlsParams params;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = CallActionAvailability(params);

    // Leaves the menu, then acts: starting a transfer takes the person to the
    // sections.
    VoidCallback? run(VoidCallback? action) =>
        action == null || !params.interactionsEnabled ? null : () => _leaveThen(action);

    final listed = actions.transferableCalls;
    final handOver = actions.onHandOver;
    final pending = actions.pendingInvite;
    final availability = params.addParticipantAvailability;
    final intoRoom = params.addParticipantIntoRoom;
    final onCancelInvite = params.onAddParticipantCancelled;
    final onBlindTransfer = actions.onBlindTransfer;
    final onAttendedTransferStart = actions.onAttendedTransferStart;

    // As the phone's menu: an entry the deployment or the call does not offer
    // is left out rather than shown dimmed.
    return WatchScrollList(
      opaque: true,
      title: l10n.call_CallActionsTooltip_transfer,
      spacing: context.adaptiveMetrics.gap / 2,
      children: [
        if (handOver != null)
          for (final (index, call) in listed.indexed)
            WatchListTile(
              title: call.nameOrNumber,
              subtitle: l10n.call_CallActionsTooltip_transferToCallHint,
              leading: const Icon(Icons.phone_paused_outlined),
              identifier: numberedId(callActionsTransferMenuNumberId, index),
              onTap: run(() => handOver(call)),
            ),
        // With calls to connect, the blind transfer is "another number".
        if (onBlindTransfer != null)
          WatchListTile(
            title: listed.isNotEmpty
                ? l10n.call_CallActionsTooltip_transfer_choose
                : l10n.call_CallActionsTooltip_unattended_transfer,
            subtitle: listed.isNotEmpty
                ? l10n.call_CallActionsTooltip_transferChooseHint
                : l10n.call_CallActionsTooltip_unattendedTransferHint,
            leading: const Icon(Icons.phone_forwarded_outlined),
            identifier: callActionsTransferMenuBlindInitId,
            onTap: run(onBlindTransfer),
          ),
        if (onAttendedTransferStart != null && !actions.focusedIsLeg)
          WatchListTile(
            title: l10n.call_CallActionsTooltip_attended_transfer,
            subtitle: l10n.call_CallActionsTooltip_attendedTransferHint,
            leading: const Icon(Icons.support_agent),
            identifier: callActionsTransferMenuAttendedInitId,
            onTap: run(onAttendedTransferStart),
          ),
        if (pending != null)
          WatchListTile(
            title: l10n.call_CallActionsTooltip_cancelInvite(pending),
            subtitle: intoRoom
                ? l10n.call_CallActionsTooltip_cancelInviteHint_conference
                : l10n.call_CallActionsTooltip_cancelInviteHint,
            leading: const Icon(Icons.person_remove_alt_1_outlined),
            identifier: callActionsTransferMenuCancelInviteId,
            // Giving up waits for nothing: the call to cancel only rings.
            onTap: onCancelInvite == null ? null : () => _leaveThen(onCancelInvite),
          )
        else if (availability != AddParticipantAvailability.hidden)
          WatchListTile(
            title: l10n.call_CallActionsTooltip_addParticipant,
            subtitle: availability == AddParticipantAvailability.noFreeLine
                ? l10n.call_Text_addParticipantNoFreeLine
                : intoRoom
                ? l10n.call_CallActionsTooltip_addParticipantHint_conference
                : l10n.call_CallActionsTooltip_addParticipantHint,
            leading: const Icon(Icons.person_add_alt_1_outlined),
            identifier: callActionsTransferMenuAddParticipantId,
            onTap: run(availability == AddParticipantAvailability.available ? params.onAddParticipant : null),
          ),
      ],
    );
  }

  void _leaveThen(VoidCallback action) {
    onDone();
    action();
  }
}

/// The calls, the one the face acts on outlined; choosing one returns to
/// it. Merge, where conferences are on, is the edge button.
class CallWatchCalls extends StatelessWidget {
  const CallWatchCalls({super.key, required this.params, required this.onDone});

  final CallControlsParams params;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.adaptiveMetrics.gap / 2;

    final rows = [
      for (final (index, call) in params.activeCalls.indexed)
        WatchListTile(
          title: call.nameOrNumber,
          subtitle: callWatchStatus(context, call),
          identifier: numberedId(callRowId, index),
          outlined: call.callId == params.focusedCall.callId,
          trailing: call.remoteVideo ? const Icon(Icons.videocam) : null,
          onTap: () => _select(call.callId),
        ),
    ];

    if (!params.callConfig.isConferenceEnabled) {
      return WatchScrollList(opaque: true, spacing: spacing, children: rows);
    }
    return WatchActionLayout(
      content: [
        for (final (index, row) in rows.indexed) ...[if (index > 0) SizedBox(height: spacing), row],
      ],
      action: WatchAction(label: l10n.call_CallList_merge, onPressed: params.onMerge, identifier: callMergeButtonId),
    );
  }

  void _select(String callId) {
    params.onCallSelected(callId);
    onDone();
  }
}

/// The room: the host's own microphone, each participant opening their
/// actions, the calls outside it, and ending the room as the edge button
/// while the face is in it. While the room stands aside for an outside call,
/// "You" goes back into it, and an outside call's row goes to that call - the
/// two conversations the phone's panel moves between.
class CallWatchConference extends StatelessWidget {
  const CallWatchConference({
    super.key,
    required this.params,
    required this.participant,
    required this.onParticipantOpened,
    required this.onDone,
  });

  final CallControlsParams params;

  /// The participant whose actions are open, or null for the room.
  final String? participant;
  final ValueChanged<String> onParticipantOpened;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final participant = this.participant;
    if (participant != null && params.conference.isLeg(participant)) {
      return _Participant(params: params, callId: participant, onDone: onDone);
    }

    final l10n = context.l10n;
    final conference = params.conference;
    final spacing = context.adaptiveMetrics.gap / 2;
    final legs = conference.legs.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final parked = params.conferenceParked;
    final onSelfMuted = params.onConferenceSelfMuted;
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final outside = params.activeCalls.where((call) => !conference.isLeg(call.callId)).toList();

    final rows = [
      WatchListTile(
        title: l10n.call_ConferencePanel_you,
        subtitle: parked ? l10n.call_ConferencePanel_hostStatusAside : l10n.call_ConferencePanel_hostStatus,
        leading: Icon(conference.selfMuted || parked ? Icons.mic_off : Icons.mic),
        identifier: conferenceSelfMuteId,
        // The room's microphone does nothing while it stands aside, so the
        // row takes the host back into it instead.
        onTap: parked
            ? (legs.isEmpty ? null : () => _switchTo(legs.first.key))
            : onSelfMuted == null
            ? null
            : () => onSelfMuted(!conference.selfMuted),
      ),
      for (final leg in legs)
        WatchListTile(
          title: _call(leg.key)?.nameOrNumber ?? leg.key,
          subtitle: conference.participantMuted(leg.key)
              ? l10n.call_ConferencePanel_participantMuted
              : l10n.call_ConferencePanel_participantStatus,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onParticipantOpened(leg.key),
        ),
      for (final (index, call) in outside.indexed)
        WatchListTile(
          title: call.nameOrNumber,
          subtitle: callWatchStatus(context, call),
          identifier: numberedId(callRowId, index),
          outlined: call.callId == params.focusedCall.callId,
          onTap: () => _switchTo(call.callId),
        ),
      if (params.onConferenceAdd case final onAdd?)
        WatchListTile(
          title: l10n.call_CallList_add,
          leading: const Icon(Icons.group_add_outlined),
          identifier: callAddToConferenceButtonId,
          onTap: onAdd,
        ),
    ];

    // The room is ended from inside it; while it stands aside for another
    // call, the face's own end button ends that call instead.
    if (!conference.isLeg(params.focusedCall.callId)) {
      return WatchScrollList(opaque: true, spacing: spacing, children: rows);
    }
    return WatchActionLayout(
      content: [
        for (final (index, row) in rows.indexed) ...[if (index > 0) SizedBox(height: spacing), row],
      ],
      primary: (overlay) => callWatchHangupButton(
        context,
        overlay,
        onPressed: params.onHangup,
        style: style?.actions?.hangup,
        label: l10n.call_SemanticsLabel_conferenceEnd,
      ),
    );
  }

  ActiveCall? _call(String callId) => params.activeCalls.where((call) => call.callId == callId).firstOrNull;

  /// Moves to the conversation [callId] belongs to - the room or a call
  /// outside it - and back to its face.
  void _switchTo(String callId) {
    (params.onConversationSwitched ?? params.onCallSelected)(callId);
    onDone();
  }
}

/// One participant of the room: muting them for everyone, and dropping them.
class _Participant extends StatelessWidget {
  const _Participant({required this.params, required this.callId, required this.onDone});

  final CallControlsParams params;
  final String callId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeData = Theme.of(context);
    final conference = params.conference;
    final name = params.activeCalls.where((call) => call.callId == callId).firstOrNull?.nameOrNumber ?? callId;
    final muted = conference.participantMuted(callId);
    final onMuted = params.onConferenceParticipantMuted;
    final onHangup = params.onConferenceParticipantHangup;

    return Material(
      color: themeData.scaffoldBackgroundColor,
      child: Padding(
        padding: context.watchContentPadding(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: themeData.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              muted ? l10n.call_ConferencePanel_participantMuted : l10n.call_ConferencePanel_participantStatus,
              textAlign: TextAlign.center,
              style: themeData.textTheme.labelSmall,
            ),
            SizedBox(height: context.adaptiveMetrics.gap * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                WatchRoundButton(
                  icon: Icon(muted ? Icons.mic : Icons.mic_off),
                  caption: l10n.call_Watch_muteForAll,
                  label: muted
                      ? l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
                      : l10n.call_SemanticsLabel_conferenceParticipantMute(name),
                  emphasis: muted ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
                  // The server answers a mute for a participant it has not
                  // finished wiring with a refusal, so it waits for them.
                  onPressed: onMuted == null || !conference.isReady(callId) ? null : () => onMuted(callId, !muted),
                ),
                WatchRoundButton(
                  icon: const Icon(Icons.call_end),
                  caption: l10n.call_Watch_drop,
                  label: l10n.call_SemanticsLabel_conferenceParticipantHangup(name),
                  emphasis: WatchRoundEmphasis.filled,
                  style: IconButton.styleFrom(
                    backgroundColor: themeData.colorScheme.error,
                    foregroundColor: themeData.colorScheme.onError,
                  ),
                  onPressed: onHangup == null ? null : () => _drop(onHangup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _drop(ValueChanged<String> onHangup) {
    onDone();
    onHangup(callId);
  }
}
