import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import '../call_queues_polling_owner.dart';

/// Reads the queues while [child] is on the screen, and stops when the last
/// screen showing them leaves.
///
/// The figures come from the PBX on every read and there is no push channel
/// behind them, so nothing reads them while nothing is showing them. Both
/// placements - the settings stack and the bottom-menu section - wrap their
/// screen in this, so neither can forget; the counting behind it is
/// [CallQueuesPollingOwner]'s.
class CallCenterPolling extends StatefulWidget {
  const CallCenterPolling({super.key, required this.child});

  final Widget child;

  @override
  State<CallCenterPolling> createState() => _CallCenterPollingState();
}

class _CallCenterPollingState extends State<CallCenterPolling> {
  late final CallQueuesPollingOwner _owner;

  @override
  void initState() {
    super.initState();
    _owner = context.read<CallQueuesPollingOwner>()..acquire();
  }

  @override
  void dispose() {
    _owner.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
