import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import 'call_center_screen.dart';

/// The queues screen, and the only place their counters are polled from.
///
/// The figures come from the PBX on every read and there is no push channel
/// behind them, so they are asked for while this screen is on the screen and
/// not a moment longer: the task is registered when it opens and unregistered
/// when it closes. [PollingService] stops the timers by itself while the app
/// is in the background.
@RoutePage()
class CallCenterScreenPage extends StatefulWidget {
  const CallCenterScreenPage({super.key});

  @override
  State<CallCenterScreenPage> createState() => _CallCenterScreenPageState();
}

class _CallCenterScreenPageState extends State<CallCenterScreenPage> {
  PollingTaskHandle? _task;

  @override
  void initState() {
    super.initState();

    final repository = context.read<CallQueuesRepository>();
    // A repository that has stopped - the deployment does not offer the
    // feature - is not worth a task the service would unregister on its first
    // tick anyway.
    if (!repository.isActive) return;

    _task = context.read<PollingService>().register(
      PollingRegistration(
        listener: repository,
        interval: Duration(seconds: EnvironmentConfig.CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS),
      ),
    );
  }

  @override
  void dispose() {
    _task?.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const CallCenterScreen();
}
