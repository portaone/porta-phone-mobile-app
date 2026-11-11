import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import 'call_queue_tile.dart';
import 'queue_master_tile.dart';

/// The queues themselves, without any chrome of their own.
///
/// The two placements differ only in the bar above this: a section of the
/// bottom menu carries the bar every section carries, and the settings stack
/// carries a titled one with a way back.
class CallCenterBody extends StatelessWidget {
  const CallCenterBody({super.key, this.watchTitle});

  /// The title heading the queues on a watch, where the body draws the whole
  /// face; null for the phone's list.
  final String? watchTitle;

  @override
  Widget build(BuildContext context) => switch (watchTitle) {
    final title? => _watch(context, title),
    null => _handset(context),
  };

  /// All queues as a toggle pill saying how many it takes calls from, then a
  /// pill per queue - its name, online or offline and how many wait; a pill
  /// offers nothing while a change is on its way. Loading, failed and no
  /// queues are the watch's state pages; a refused change says why as the
  /// phone does.
  Widget _watch(BuildContext context, String title) {
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
              onChanged: state.isBusy ? null : (value) => _onAllChanged(context, value),
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
                onChanged: state.isPending(queue.id) ? null : (value) => _onQueueChanged(context, queue.id, value),
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

  Widget _handset(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CallQueuesCubit, CallQueuesState>(
      builder: (context, state) {
        // Nothing has answered yet. A read that failed says so and offers to
        // ask again - without this the screen spins for as long as it is open,
        // which is what a person sees where the backend is unreachable.
        if (!state.known) {
          if (!state.readFailed) return const Center(child: CircularProgressIndicator());

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l10n.callCenter_Text_loadFailed, textAlign: TextAlign.center),
                ),
                TextButton(
                  onPressed: () => context.read<CallQueuesCubit>().refresh(),
                  child: Text(l10n.callCenter_Button_retry),
                ),
              ],
            ),
          );
        }

        if (state.queues.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.callCenter_Text_noQueues, textAlign: TextAlign.center),
            ),
          );
        }

        return ListView.separated(
          itemCount: state.queues.length + 1,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return QueueMasterTile(
                masterState: state.masterState,
                loggedInCount: state.loggedInCount,
                totalCount: state.queues.length,
                // Busy, not just all-pending: a write over one queue makes
                // this control refuse too, and a switch that looks live while
                // it cannot act is worse than one that looks busy.
                pending: state.isBusy,
                onChanged: (value) => _onAllChanged(context, value),
              );
            }

            final queue = state.queues[index - 1];
            return CallQueueTile(
              queue: queue,
              pending: state.isPending(queue.id),
              onChanged: (value) => _onQueueChanged(context, queue.id, value),
            );
          },
        );
      },
    );
  }

  Future<void> _onQueueChanged(BuildContext context, String queueId, bool loggedIn) async {
    final outcome = await context.read<CallQueuesCubit>().setLoggedIn(queueId, loggedIn: loggedIn);
    if (context.mounted) _report(context, outcome);
  }

  // A mixed list logs into every queue rather than out of it: the control
  // reads as off there, and starting a shift is the action worth reaching by
  // accident.
  Future<void> _onAllChanged(BuildContext context, bool loggedIn) async {
    final outcome = await context.read<CallQueuesCubit>().setAllLoggedIn(loggedIn: loggedIn);
    if (context.mounted) _report(context, outcome);
  }

  void _report(BuildContext context, CallQueueWriteOutcome outcome) {
    final l10n = context.l10n;

    final message = switch (outcome) {
      CallQueueWriteOutcome.ok => null,
      CallQueueWriteOutcome.queueGone => l10n.callCenter_Snackbar_queueGone,
      CallQueueWriteOutcome.readOnly => l10n.callCenter_Snackbar_readOnly,
      CallQueueWriteOutcome.failed => l10n.callCenter_Snackbar_changeFailed,
    };

    if (message != null) context.showErrorSnackBar(message);
  }
}
