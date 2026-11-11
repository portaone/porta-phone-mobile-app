import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import 'call_queue_change.dart';
import 'call_queue_tile.dart';

/// The queues on a watch, drawing the whole face under [title].
///
/// All queues as a toggle pill saying how many it takes calls from, then a
/// pill per queue - its name, online or offline and how many wait; a pill
/// offers nothing while a change is on its way. Loading, failed and no
/// queues are the watch's state pages; a refused change says why as the
/// phone does.
class CallCenterWatchBody extends StatelessWidget {
  const CallCenterWatchBody({super.key, required this.title});

  /// The name heading the queues.
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CallQueuesCubit, CallQueuesState>(
      builder: (context, state) {
        if (!state.known) {
          if (!state.readFailed) {
            return WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading);
          }
          return WatchStatePage(
            title: title,
            icon: const Icon(Icons.error_outline),
            message: l10n.callCenter_Text_loadFailed,
            action: WatchAction(
              label: l10n.callCenter_Button_retry,
              onPressed: () => context.read<CallQueuesCubit>().refresh(),
            ),
          );
        }
        if (state.queues.isEmpty) {
          return WatchStatePage(
            title: title,
            icon: const Icon(Icons.support_agent),
            message: l10n.callCenter_Text_noQueues,
          );
        }
        return WatchScrollList(
          title: title,
          spacing: context.adaptiveMetrics.gap,
          children: [
            WatchToggleChip(
              identifier: callCenterMasterSwitchId,
              toggleKey: callCenterMasterSwitchKey,
              label: l10n.callCenter_Switch_allQueues,
              subtitle: l10n.callCenter_Text_loggedInOfTotal(state.loggedInCount, state.queues.length),
              // Mixed reads as off, and a tap logs into every queue, as on
              // the phone; the count says it is mixed.
              value: state.masterState == MasterSwitchState.on,
              onChanged: state.isBusy ? null : (value) => changeAllQueuesLoggedIn(context, loggedIn: value),
            ),
            for (final queue in state.queues)
              WatchToggleChip(
                identifier: callCenterQueueSwitchId(queue.id),
                toggleKey: callCenterQueueSwitchKey(queue.id),
                label: queue.name,
                subtitle: _queueLine(l10n, queue).join(' \u00B7 '),
                // Read with a pause, not as the dot drawn between them.
                subtitleSemanticsLabel: _queueLine(l10n, queue).join(', '),
                value: queue.loggedIn,
                onChanged: state.isPending(queue.id)
                    ? null
                    : (value) => changeQueueLoggedIn(context, queue.id, loggedIn: value),
              ),
          ],
        );
      },
    );
  }

  /// How a queue stands under its name: the user in it or not, and who waits.
  static List<String> _queueLine(AppLocalizations l10n, CallQueue queue) => [
    queue.loggedIn ? l10n.callCenter_Text_online : l10n.callCenter_Text_offline,
    callersWaitingLabel(l10n, queue),
  ];
}
