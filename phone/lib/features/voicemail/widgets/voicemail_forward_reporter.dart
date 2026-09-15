import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../cubits/cubits.dart';
import '../models/models.dart';

/// Says what came of passing a message on, wherever the person now is.
///
/// It sits above the sections rather than on the voicemail screen: by the time
/// there is an outcome the person is in the address book, and the screen that
/// started the forward is two tabs away.
class VoicemailForwardReporter extends StatelessWidget {
  const VoicemailForwardReporter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoicemailForwardingCubit, VoicemailForwardingState>(
      listenWhen: (previous, current) => previous.report != current.report && current.report != null,
      listener: _report,
      child: child,
    );
  }

  void _report(BuildContext context, VoicemailForwardingState state) {
    final report = state.report!;
    final cubit = context.read<VoicemailForwardingCubit>();
    final l10n = context.l10n;
    cubit.reportShown();

    if (report.outcome == VoicemailForwardOutcome.sent) {
      context.showSnackBar(l10n.voicemail_Snackbar_forwarded(report.recipientName));
      return;
    }

    final message = switch (report.outcome) {
      VoicemailForwardOutcome.tooLarge => l10n.voicemail_Snackbar_forwardTooLarge,
      VoicemailForwardOutcome.recipientFull => l10n.voicemail_Snackbar_forwardRecipientFull(report.recipientName),
      VoicemailForwardOutcome.unavailable => l10n.voicemail_Snackbar_forwardUnavailable,
      _ => l10n.voicemail_Snackbar_forwardFailed,
    };

    context.showErrorSnackBar(
      message,
      // Offered only where trying again could end differently. A recording that
      // is too big stays too big, and a colleague who is full stays full.
      action: report.outcome.isRetryable
          ? SnackBarAction(label: l10n.voicemail_Label_retry, onPressed: () => cubit.retry(report))
          : null,
    );
  }
}
