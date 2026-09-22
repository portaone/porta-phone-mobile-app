import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';

/// The control for every queue at once.
///
/// Material has no three-state switch, and the wire has no third state either:
/// what the backend takes is "log in to all" or "log out of all". So a mixed
/// list is shown by the thumb carrying a dash and by the caption counting the
/// queues, while the switch itself reads as off - which is also the direction
/// it acts in, logging the agent into everything, the start-of-shift action.
class QueueMasterTile extends StatelessWidget {
  const QueueMasterTile({
    super.key,
    required this.masterState,
    required this.loggedInCount,
    required this.totalCount,
    required this.pending,
    required this.onChanged,
  });

  final MasterSwitchState masterState;
  final int loggedInCount;
  final int totalCount;
  final bool pending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final title = Text(l10n.callCenter_Switch_allQueues);
    final subtitle = Text(l10n.callCenter_Text_loggedInOfTotal(loggedInCount, totalCount));

    // Named by its own caption rather than by a label of its own - see the
    // queue row for why - and an anchor rather than an action while the
    // request is in flight.
    if (pending) {
      return SemanticId(
        identifier: callCenterMasterSwitchId,
        child: ListTile(
          key: callCenterMasterSwitchKey,
          title: title,
          subtitle: subtitle,
          trailing: const SizedCircularProgressIndicator(size: 24, strokeWidth: 2),
        ),
      );
    }

    return SemanticAction(
      identifier: callCenterMasterSwitchId,
      child: SwitchListTile(
        key: callCenterMasterSwitchKey,
        title: title,
        subtitle: subtitle,
        value: masterState == MasterSwitchState.on,
        thumbIcon: masterState == MasterSwitchState.mixed ? const WidgetStatePropertyAll(Icon(Icons.remove)) : null,
        onChanged: onChanged,
      ),
    );
  }
}
