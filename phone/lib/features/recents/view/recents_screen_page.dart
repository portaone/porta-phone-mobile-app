import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

@RoutePage()
class RecentsScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const RecentsScreenPage();

  @override
  Widget build(BuildContext context) {
    final featureAccess = context.read<FeatureAccess>();
    final tab = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>();

    final widget = RecentsScreen(
      title: Text(EnvironmentConfig.APP_NAME),
      // On a watch the list is headed by the section's own name, as the hub
      // shows it.
      watchTitle: context.watchSectionTitle<RecentsBottomMenuTab>(
        fallback: context.l10n.main_BottomNavigationBarItemLabel_recents,
      ),
      transferEnabled: featureAccess.callConfig.capabilities.isBlindTransferEnabled,
      videoEnabled: featureAccess.callConfig.capabilities.isVideoCallEnabled,
      chatsEnabled: featureAccess.messagingConfig.chatsPresent,
      smssEnabled: featureAccess.messagingConfig.smsPresent,
      layout: tab?.layout ?? RecentsLayout.tabbed,
    );
    return widget;
  }
}
