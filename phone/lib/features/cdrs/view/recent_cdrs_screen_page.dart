import 'package:auto_route/auto_route.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../cdrs.dart';

@RoutePage()
class RecentCdrsScreenPage extends StatelessWidget {
  const RecentCdrsScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final featureAccess = context.read<FeatureAccess>();
    final tab = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>();
    final cdrsSync = context.read<CdrsSync>();
    final historyWalk = context.read<CdrsHistoryWalk>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FullRecentCdrsCubit(
            context.read<CdrsLocalRepository>(),
            context.read<CdrsRemoteRepository>(),
            cdrsSync,
            cdrsSync,
            historyWalk: historyWalk,
          )..init(),
        ),
        BlocProvider(
          create: (context) => CdrsHistoryClearCubit(
            context.read<CdrsRemoteRepository>(),
            context.read<CdrsLocalRepository>(),
            cdrsSync,
          ),
        ),
        BlocProvider(
          create: (context) => MissedRecentCdrsCubit(
            context.read<CdrsLocalRepository>(),
            context.read<CdrsRemoteRepository>(),
            cdrsSync,
            cdrsSync,
            historyWalk: historyWalk,
          )..init(),
        ),
      ],
      child: RecentCdrsScreen(
        title: Text(EnvironmentConfig.APP_NAME),
        // On a watch the list is headed by the section's own name, as the hub
        // shows it.
        watchTitle: context.watchSectionTitle<RecentsBottomMenuTab>(
          fallback: context.l10n.main_BottomNavigationBarItemLabel_recents,
        ),
        layout: tab?.layout ?? RecentsLayout.tabbed,
        transferEnabled: featureAccess.callConfig.capabilities.isBlindTransferEnabled,
        videoEnabled: featureAccess.callConfig.capabilities.isVideoCallEnabled,
        chatsEnabled: featureAccess.messagingConfig.chatsPresent,
        smssEnabled: featureAccess.messagingConfig.smsPresent,
      ),
    );
  }
}
