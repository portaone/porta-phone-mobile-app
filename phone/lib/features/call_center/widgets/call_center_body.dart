import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../bloc/bloc.dart';
import 'call_queue_tile.dart';
import 'queue_master_tile.dart';

/// The queues themselves, without any chrome of their own.
///
/// The two placements differ only in the bar above this: a section of the
/// bottom menu carries the bar every section carries, and the settings stack
/// carries a titled one with a way back.
class CallCenterBody extends StatelessWidget {
  const CallCenterBody({super.key});

  @override
  Widget build(BuildContext context) {
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
