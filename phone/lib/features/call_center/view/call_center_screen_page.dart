import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';

import 'call_center_polling.dart';
import 'call_center_screen.dart';

/// Route of the call center screen inside the settings stack.
///
/// The cubit comes from the settings router above it, which the settings row
/// reads as well; the polling task is this screen's own - see
/// [CallCenterPolling].
@RoutePage()
class CallCenterScreenPage extends StatelessWidget {
  const CallCenterScreenPage({super.key});

  @override
  Widget build(BuildContext context) => const CallCenterPolling(child: CallCenterScreen());
}
