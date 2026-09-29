import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/feature_access.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class SystemNotificationsShell extends StatefulWidget {
  const SystemNotificationsShell({required this.child, super.key});

  final Widget child;

  @override
  State<SystemNotificationsShell> createState() => _SystemNotificationsShellState();
}

class _SystemNotificationsShellState extends State<SystemNotificationsShell> {
  late final localRepository = context.read<SystemNotificationsLocalRepository>();
  late final remotePushRepository = context.read<RemotePushRepository>();
  late final localPushRepository = context.read<LocalPushRepository>();

  late final featureAccess = context.read<FeatureAccess>();
  late final feature = featureAccess.systemNotificationsConfig;

  SystemNotificationsPushService? pushService;

  @override
  void initState() {
    super.initState();
    _startServices();
  }

  /// Starts what this session's configuration asks for.
  ///
  /// Read once, because the configuration cannot move underneath: [MainShell]
  /// pins one [FeatureAccess] snapshot for the whole session, and this widget
  /// captures it - and the flags read off it - when it mounts. This used to be
  /// re-evaluated every second in case they changed, which they could not; the
  /// loop only kept a timer alive for as long as the session lasted.
  void _startServices() {
    if (!feature.systemNotificationsSupport) {
      // A session that had the feature on may have left the periodic task
      // scheduled, and it outlives the process that scheduled it.
      SystemNotificationBackgroundWorker.cancelTask();
      return;
    }

    // Without server-side push the app produces the notification locally, and
    // the background task is what fetches one while the app is not running.
    final producePush = !feature.systemNotificationsPushSupport;

    pushService = SystemNotificationsPushService(
      remotePushRepository,
      localPushRepository,
      localRepository,
      openNotifications: openNotificationsScreen,
      producePush: producePush,
    )..init();

    if (producePush) SystemNotificationBackgroundWorker.dispatchTask();
  }

  void openNotificationsScreen() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    context.router.navigate(const SystemNotificationsPageRoute());
  }

  @override
  void dispose() {
    pushService?.dispose();
    SystemNotificationBackgroundWorker.cancelTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
