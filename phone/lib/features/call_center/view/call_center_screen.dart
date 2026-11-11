import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';

/// The queues as a screen of the settings stack: its own title, and a way back
/// to the list that led here.
class CallCenterScreen extends StatelessWidget {
  const CallCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    handset: (context) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.callCenter_AppBarTitle), leading: const ExtBackButton()),
      body: const CallCenterBody(),
    ),
    // No app bar: the queues draw the whole face under the screen's name.
    watch: (context) => Scaffold(body: CallCenterBody(watchTitle: context.l10n.callCenter_AppBarTitle)),
  );
}
