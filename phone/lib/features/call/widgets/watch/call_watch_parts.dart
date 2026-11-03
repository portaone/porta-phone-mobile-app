import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../extensions/extensions.dart';
import '../../models/models.dart';
import '../../view/call_screen_styles.dart';
import '../call_duration.dart';
import '../call_info.dart';

/// Who the call is with and the line under the name: before an answer what
/// the call is doing, after it the description the phone shows too.
class CallWatchHeader extends StatelessWidget {
  const CallWatchHeader({super.key, required this.call, this.color});

  final ActiveCall call;

  /// The text colour; the call background's by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = this.color ?? Theme.of(context).colorScheme.surface;
    final heldColor = Theme.of(context).extension<CallScreenStyles>()?.primary?.list?.dotHeld ?? color;
    final transfer = call.transfer;
    final inviteToAttendedTransfer = transfer is InviteToAttendedTransfer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          call.nameOrNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        CallDuration(
          since: call.acceptedTime,
          builder: (context, elapsed) {
            // An invitation to a transfer is what the person decides on, so it
            // wins over the ringing, as the phone's own line under the name.
            final processing = call.wasAccepted || inviteToAttendedTransfer
                ? null
                : call.processingStatus.l10n(context).nullify;
            final description = callDescription(
              context,
              duration: elapsed,
              transfering: transfer is Transfering,
              requestToAttendedTransfer: false,
              inviteToAttendedTransfer: inviteToAttendedTransfer,
              isIncoming: call.isIncoming,
              held: call.held,
              peerReportedConferenceMute: call.peerReportedConferenceMute ?? false,
              peerReportedConferenceHostAway: call.peerReportedConferenceHostAway ?? false,
            );
            return Text(
              // Before an answer the step under way says more than "Outgoing
              // call" does.
              processing ?? description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: call.held ? heldColor : color.withValues(alpha: 0.85),
                fontWeight: call.held ? FontWeight.w600 : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The red button that ends a call, built over [overlay] - the edge
/// button's or a layout's - for whatever ends it: the focused call, the
/// room, the call while its keypad is open.
class CallWatchHangupButton extends StatelessWidget {
  const CallWatchHangupButton({super.key, required this.overlay, required this.onPressed, this.style, this.label});

  final ButtonStyle overlay;
  final VoidCallback? onPressed;

  /// The theme's hangup style, laid over [overlay].
  final ButtonStyle? style;

  /// The name assistive technology reads; "hang up" when absent.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SemanticAction(
      label: label ?? context.l10n.call_CallActionsTooltip_hangup,
      identifier: callActionsHangupId,
      child: ElevatedButton(
        key: callActionsHangupKey,
        onPressed: onPressed,
        style: overlay.merge(
          (style ?? const ButtonStyle()).merge(
            ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
          ),
        ),
        child: const Icon(Icons.call_end),
      ),
    );
  }
}

/// What a call in a list is doing: ringing, held, or on.
String callWatchStatus(BuildContext context, ActiveCall call) {
  if (!call.wasAccepted) return context.l10n.callProcessingStatus_ringing;
  if (call.held) return context.l10n.call_description_held;
  return context.l10n.call_CallList_statusOnCall;
}
