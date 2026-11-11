import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../bloc/bloc.dart';

/// Logs the user into or out of one queue; a refused change says why, on the
/// phone's list and on a watch's pills alike.
Future<void> changeQueueLoggedIn(BuildContext context, String queueId, {required bool loggedIn}) async {
  final outcome = await context.read<CallQueuesCubit>().setLoggedIn(queueId, loggedIn: loggedIn);
  if (context.mounted) _report(context, outcome);
}

/// Logs the user into or out of every queue at once.
///
/// A mixed list logs into every queue rather than out of it: the control reads
/// as off there, and starting a shift is the action worth reaching by accident.
Future<void> changeAllQueuesLoggedIn(BuildContext context, {required bool loggedIn}) async {
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
