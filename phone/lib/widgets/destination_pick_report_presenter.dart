import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';

/// Says what came of a choice, wherever the person now is.
///
/// One of these for every feature that asks for somebody to be chosen: the
/// sentence and the retry are the feature's, and this only puts them on
/// screen. It sits above the sections because the screen that asked is, by the
/// time there is anything to say, wherever the person walked away from.
class DestinationPickReportPresenter extends StatelessWidget {
  const DestinationPickReportPresenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinationPickingCubit, DestinationPickingState>(
      listenWhen: (previous, current) => previous.report != current.report && current.report != null,
      listener: _present,
      child: child,
    );
  }

  void _present(BuildContext context, DestinationPickingState state) {
    final report = state.report!;
    context.read<DestinationPickingCubit>().reportShown();

    if (!report.isFailure) {
      context.showSnackBar(report.message);
      return;
    }

    context.showErrorSnackBar(
      report.message,
      action: report.isRetryable ? SnackBarAction(label: report.retryLabel!, onPressed: report.onRetry!) : null,
    );
  }
}
