import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';
import '../view/call_screen_styles.dart';
import '../utils/contact_resolver.dart';
import 'call_info.dart';
import 'call_list.dart';
import 'call_list_action.dart';
import 'conference_panel.dart';

/// Who the screen is about: with a conference - the room's panel and, below
/// it, the roster of whatever calls are outside the room; with several calls
/// and no room - the tappable roster (every call a row, the focused one
/// highlighted); with a single call - its central info block.
///
/// The block is shared by the orientation layouts: each of them decides where
/// it stands, none of them what is inside.
class CallInfoBlock extends StatelessWidget {
  const CallInfoBlock({
    super.key,
    required this.activeCalls,
    required this.focusedCall,
    required this.onCallSelected,
    this.conference = const ConferenceState(),
    this.onSelfMutedChanged,
    this.onParticipantMutedChanged,
    this.onParticipantHangup,
    this.onAddPressed,
    this.mergeSupported = false,
    this.onMergePressed,
    this.contactResolver,
    this.textAlign = TextAlign.center,
  });

  final List<ActiveCall> activeCalls;

  /// The call the info block describes; the roster highlights its row.
  final ActiveCall focusedCall;

  final ValueChanged<String> onCallSelected;

  /// The room, when there is one; see [ConferencePanel].
  final ConferenceState conference;

  final ValueChanged<bool>? onSelfMutedChanged;
  final void Function(String callId, bool muted)? onParticipantMutedChanged;
  final ValueChanged<String>? onParticipantHangup;

  /// Brings the calls standing outside the room into it; `null` while none of
  /// them can join - one is still ringing, or the room is still assembling -
  /// which leaves the control visible and disabled.
  final VoidCallback? onAddPressed;

  /// Resolves who a call is with, for the picture on each roster row.
  final ContactResolver? contactResolver;

  /// Whether the deployment offers conferences; see [CallList.mergeSupported].
  final bool mergeSupported;

  /// Merges the calls, or `null` while they cannot be merged; see
  /// [CallList.onMergePressed]. Only the roster offers it - a single call is
  /// nothing to merge.
  final VoidCallback? onMergePressed;

  /// How the single-call info lines align; the roster rows range themselves.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;

    // The room is one conversation, not a set of calls to choose between, so
    // its legs leave the roster for the panel. A call that is not in the room
    // is still an ordinary call and keeps its row underneath.
    if (conference.isPresent) {
      final outside = activeCalls.where((call) => !conference.isLeg(call.callId)).toList();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConferencePanel(
            conference: conference,
            calls: activeCalls,
            onSelfMutedChanged: onSelfMutedChanged ?? (_) {},
            onParticipantMutedChanged: onParticipantMutedChanged ?? (_, _) {},
            onParticipantHangup: onParticipantHangup ?? (_) {},
            contactResolver: contactResolver,
            style: style?.callInfo,
            listStyle: style?.list,
            actionsStyle: style?.actions,
          ),
          if (outside.isNotEmpty)
            CallList(
              calls: outside,
              focusedCallId: focusedCall.callId,
              header: context.l10n.call_CallList_outsideHeader(outside.length),
              action: CallListAction(
                label: context.l10n.call_CallList_add,
                semanticsLabel: context.l10n.call_SemanticsLabel_add,
                identifier: callAddToConferenceButtonId,
                icon: Icons.group_add_outlined,
                onPressed: onAddPressed,
              ),
              contactResolver: contactResolver,
              style: style?.callInfo,
              listStyle: style?.list,
              onCallTap: onCallSelected,
            ),
        ],
      );
    }

    // List-based call screen: with more than one call every call is a
    // tappable row, and the info block + action area act on the focused call.
    if (activeCalls.length > 1) {
      return CallList(
        calls: activeCalls,
        focusedCallId: focusedCall.callId,
        action: mergeSupported
            ? CallListAction(
                label: context.l10n.call_CallList_merge,
                semanticsLabel: context.l10n.call_SemanticsLabel_merge,
                identifier: callMergeButtonId,
                icon: Icons.groups_outlined,
                onPressed: onMergePressed,
              )
            : null,
        contactResolver: contactResolver,
        style: style?.callInfo,
        listStyle: style?.list,
        onCallTap: onCallSelected,
      );
    }

    // With multiple calls the list rows carry the per-call info, so the
    // central info block is single-call only.
    final focusedTransfer = focusedCall.transfer;
    return CallInfo(
      transfering: focusedTransfer is Transfering,
      requestToAttendedTransfer: false,
      inviteToAttendedTransfer: focusedTransfer is InviteToAttendedTransfer,
      isIncoming: focusedCall.isIncoming,
      held: focusedCall.held,
      peerReportedConferenceMute: focusedCall.peerReportedConferenceMute,
      number: focusedCall.handle.value,
      username: focusedCall.displayName,
      acceptedTime: focusedCall.acceptedTime,
      style: style?.callInfo,
      processingStatus: focusedCall.processingStatus,
      textAlign: textAlign,
    );
  }
}
