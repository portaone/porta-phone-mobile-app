import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/feature_access/bottom_menu_feature.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

@RoutePage()
class FavoritesScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const FavoritesScreenPage();

  @override
  Widget build(BuildContext context) {
    final featureAccess = context.read<FeatureAccess>();

    final cdrsEnabled = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>()?.supportsCallHistory;

    final widget = FavoritesScreen(
      title: Text(EnvironmentConfig.APP_NAME),
      // On a watch the list is headed by the section's own name, as the hub
      // shows it.
      watchTitle: context.watchSectionTitle<FavoritesBottomMenuTab>(
        fallback: context.l10n.main_BottomNavigationBarItemLabel_favorites,
      ),
      transferEnabled: featureAccess.callConfig.capabilities.isBlindTransferEnabled,
      videoEnabled: featureAccess.callConfig.capabilities.isVideoCallEnabled,
      chatsEnabled: featureAccess.messagingConfig.chatsPresent,
      smssEnabled: featureAccess.messagingConfig.smsPresent,
      cdrsEnabled: cdrsEnabled ?? false,
    );
    final provider = BlocProvider(
      create: (context) =>
          FavoritesBloc(favoritesRepository: context.read<FavoritesRepository>())..add(const FavoritesStarted()),
      child: widget,
    );
    return provider;
  }
}
