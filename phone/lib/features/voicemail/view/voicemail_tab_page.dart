import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/feature_access/bottom_menu_feature.dart';

import 'voicemail_screen_host.dart';
import 'voicemail_tab_screen.dart';

/// Route of the bottom-menu voicemail section.
@RoutePage()
class VoicemailTabPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const VoicemailTabPage();

  @override
  Widget build(BuildContext context) {
    return VoicemailScreenHost(
      child: VoicemailTabScreen(
        // On a watch the list is headed by the section's own name, as the hub
        // shows it.
        watchTitle: context.watchSectionTitle<VoicemailBottomMenuTab>(
          fallback: context.l10n.main_BottomNavigationBarItemLabel_voicemail,
        ),
      ),
    );
  }
}
