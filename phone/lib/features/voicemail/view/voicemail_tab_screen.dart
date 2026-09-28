import 'package:flutter/material.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'voicemail_screen_styles.dart';

/// Voicemail as a section of the bottom menu: the same list under the bar
/// every section carries.
///
/// The actions that manage the mailbox are not here. Clearing the media cache
/// opens a screen that lives inside settings, and emptying the mailbox is
/// destructive over everything there is; both belong where the feature is
/// managed. What is left is the delete control for messages picked by hand,
/// which shows itself only once something is picked.
class VoicemailTabScreen extends StatelessWidget {
  const VoicemailTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      // The configured bar is transparent; the tint that keeps it from reading
      // as part of the background comes from this section's page style.
      extendBodyBehindAppBar: true,
      appBar: MainAppBar(
        title: Text(EnvironmentConfig.APP_NAME),
        context: context,
        flexibleSpace: BlurredSurface.fromStyle(
          Theme.of(context).extension<VoicemailScreenStyles>()?.primary?.appBarBlurredSurface,
        ),
        actions: const [VoicemailRestoreAction(), VoicemailDeleteAction(offersDeleteAll: false)],
        bottom: const VoicemailFilterRow(),
      ),
      // No inset of its own: the body runs behind the bar and Scaffold already
      // hands it a MediaQuery whose top padding is the bar plus the status bar,
      // which a list with no padding of its own takes.
      body: const VoicemailBody(),
    );
  }
}
