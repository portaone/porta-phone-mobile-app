import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'queue_status_dot.dart';

/// One queue: what it is called, how loaded it is, and whether this agent is
/// taking its calls.
///
/// While the row's own request is in flight the control gives way to a
/// progress indicator instead of moving: the answer carries the truth, and a
/// switch that has already flipped would have to flip back if the PBX refused.
class CallQueueTile extends StatelessWidget {
  const CallQueueTile({super.key, required this.queue, required this.pending, required this.onChanged});

  final CallQueue queue;
  final bool pending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final title = Text(queue.name, maxLines: 1, overflow: TextOverflow.ellipsis);

    // Unknown is not zero. Where the PBX call control interface is out of
    // reach the figure is absent on every queue, permanently, so it reads as a
    // dash - telling an agent that nobody is waiting would be a lie the screen
    // cannot take back.
    final waiting = queue.callersWaiting == null
        ? l10n.callCenter_Text_callersWaitingUnknown
        : l10n.callCenter_Text_callersWaiting(queue.callersWaiting!);

    final subtitle = Row(
      children: [
        QueueStatusDot(loggedIn: queue.loggedIn),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            [
              queue.loggedIn ? l10n.callCenter_Text_online : l10n.callCenter_Text_offline,
              queue.id,
              waiting,
              l10n.callCenter_Text_agentsOfTotal(queue.agentsLoggedIn, queue.agentsTotal),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // The id sits on the row in both states, so a test and a screen reader
    // find it whether or not a request is in flight. No label is given: the
    // row's own title is the control's name, and a second one is announced on
    // top of it. While the request is in flight the row carries no control at
    // all, so it is an anchor rather than an action - SemanticAction would
    // merge a subtree that has nothing to activate.
    if (pending) {
      return SemanticId(
        identifier: callCenterQueueSwitchId(queue.id),
        child: ListTile(
          key: callCenterQueueSwitchKey(queue.id),
          title: title,
          subtitle: subtitle,
          trailing: const SizedCircularProgressIndicator(size: 24, strokeWidth: 2),
        ),
      );
    }

    return SemanticAction(
      identifier: callCenterQueueSwitchId(queue.id),
      child: SwitchListTile(
        key: callCenterQueueSwitchKey(queue.id),
        title: title,
        subtitle: subtitle,
        value: queue.loggedIn,
        onChanged: onChanged,
      ),
    );
  }
}
