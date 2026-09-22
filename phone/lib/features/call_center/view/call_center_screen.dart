import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// The agent's queues: what they are, how loaded they are, and the two ways of
/// going on or off the line - one queue, or all of them.
class CallCenterScreen extends StatelessWidget {
  const CallCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.callCenter_AppBarTitle)),
      body: BlocBuilder<CallQueuesCubit, CallQueuesState>(
        builder: (context, state) {
          // Nothing has answered yet, so an empty list says nothing: waiting is
          // the only honest thing to draw.
          if (!state.known) {
            return const Center(child: CircularProgressIndicator());
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
                  pending: state.allPending,
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
      ),
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
