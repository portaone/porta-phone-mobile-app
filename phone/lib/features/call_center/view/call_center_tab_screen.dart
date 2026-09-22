import 'package:flutter/material.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';

/// The queues as a section of the bottom menu: the same bar every section
/// carries, so the header does not change from tab to tab.
class CallCenterTabScreen extends StatelessWidget {
  const CallCenterTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      // The configured bar is transparent, and a section with no page style of
      // its own takes the tint from the adaptive fallback - without it the bar
      // reads as part of the background.
      extendBodyBehindAppBar: true,
      appBar: MainAppBar(
        title: Text(EnvironmentConfig.APP_NAME),
        context: context,
        flexibleSpace: BlurredSurface.adaptive(context),
      ),
      body: const CallCenterBody(),
    );
  }
}
