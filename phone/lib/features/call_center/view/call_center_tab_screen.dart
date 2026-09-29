import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'call_center_screen_styles.dart';

/// The queues as a section of the bottom menu: the same bar every section
/// carries, so the header does not change from tab to tab.
class CallCenterTabScreen extends StatelessWidget {
  const CallCenterTabScreen({super.key});

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
          Theme.of(context).extension<CallCenterScreenStyles>()?.primary?.appBarBlurredSurface,
        ),
      ),
      body: const CallCenterBody(),
    );
  }
}
