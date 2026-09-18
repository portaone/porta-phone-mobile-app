import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/call_bloc.dart';
import '../models/models.dart';
import '../view/call_screen_style.dart';
import '../utils/contact_resolver.dart';
import 'call_list_action.dart';
import 'call_duration.dart';
import 'call_row_frame.dart';

/// The list-of-calls roster for the call screen.
///
/// Renders every active call as a tappable [CallRow] (name + status badge +
/// timer) under a header that says what the list is, with the one action the
/// list offers beside it. Tapping a row reports the call id via [onCallTap]
/// so the caller can focus it (see [CallControlEvent.callSelected]); the
/// focused row is highlighted.
class CallList extends StatelessWidget {
  const CallList({
    super.key,
    required this.calls,
    required this.focusedCallId,
    required this.onCallTap,
    this.header,
    this.action,
    this.contactResolver,
    this.style,
    this.listStyle,
  });

  final List<ActiveCall> calls;
  final String focusedCallId;
  final ValueChanged<String> onCallTap;

  /// What the list is, when it is something other than the roster of calls to
  /// choose between - the calls standing outside a conference, say.
  final String? header;

  /// The action offered beside the header; absent where there is none to
  /// offer, as on a deployment without conferences.
  final CallListAction? action;

  /// Resolves who a call is with, so each row can show that person's picture;
  /// `null` leaves the rows with initials only.
  final ContactResolver? contactResolver;

  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The roster header, and with it the Merge control, belongs to a set
        // of calls: one call is not a set to choose from and not a set to
        // merge. A list that says what it is carries its header either way.
        if (header != null || calls.length > 1)
          CallRowHeader(label: header ?? context.l10n.call_CallList_header(calls.length), action: action, style: style),
        // Each row is one control: the badge, the name and the duration are
        // its content, and the id is numbered because there are several of
        // them and a call id is not something a test can know in advance.
        for (final (index, call) in calls.indexed)
          SemanticAction.button(
            identifier: numberedId(callRowId, index),
            child: CallRow(
              key: ValueKey('CallRow-${call.callId}'),
              call: call,
              focused: call.callId == focusedCallId,
              onTap: () => onCallTap(call.callId),
              contactResolver: contactResolver,
              style: style,
              listStyle: listStyle,
            ),
          ),
      ],
    );
  }
}

/// One call in the [CallList]: status badge, name/number and a live duration
/// for answered calls (or the call direction while it is still ringing).
class CallRow extends StatelessWidget {
  const CallRow({
    super.key,
    required this.call,
    required this.focused,
    required this.onTap,
    this.contactResolver,
    this.style,
    this.listStyle,
  });

  final ActiveCall call;
  final bool focused;
  final VoidCallback onTap;
  final ContactResolver? contactResolver;
  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  String _statusBadge(BuildContext context) {
    if (!call.wasAccepted) return context.l10n.callProcessingStatus_ringing;
    if (call.held) return context.l10n.call_description_held;
    return context.l10n.call_CallList_statusOnCall;
  }

  /// Status dot from the themed call-list palette (CallListStyle, fed by the
  /// theme JSONs); the fallback is the row text color so an unthemed harness
  /// stays legible without any fixed colors.
  Color _statusDotColor(Color base) {
    if (!call.wasAccepted) return listStyle?.dotRinging ?? base;
    if (call.held) return listStyle?.dotHeld ?? base;
    return listStyle?.dotOnCall ?? base;
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = style?.callStatus ?? const TextStyle();
    final base = CallRowFrame.baseColor(context, style);

    return CallRowFrame(
      name: call.displayName ?? call.handle.value,
      status: _statusBadge(context),
      focused: focused,
      onTap: onTap,
      style: style,
      listStyle: listStyle,
      // The person, then their state on top of them. With several calls the
      // screen shows no single large picture - it would be one of them - so
      // each row carries its own.
      leading: CallRowAvatar(
        call: call,
        contactResolver: contactResolver,
        dotColor: _statusDotColor(base),
        // The row's own colour, asked of the row rather than worked out here:
        // two derivations would drift the moment the palette changed.
        dotBorderColor: CallRowFrame.rowColor(context, focused: focused, style: style, listStyle: listStyle),
      ),
      trailing: [
        // Video lines carry a camera glyph next to the trailing
        // duration/direction label.
        if (call.remoteVideo)
          Icon(Icons.videocam, key: const ValueKey('CallRowVideoBadge'), size: 16, color: statusStyle.color),
        CallDurationText(
          since: call.acceptedTime,
          style: statusStyle.copyWith(fontSize: 13),
          placeholder: call.isIncoming ? context.l10n.call_CallList_incoming : context.l10n.call_CallList_outgoing,
        ),
      ],
    );
  }
}
