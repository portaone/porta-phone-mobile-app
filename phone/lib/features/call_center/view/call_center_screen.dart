import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'call_center_screen_watch.dart';

/// The queues as a screen of the settings stack: its own title, and a way back
/// to the list that led here.
class CallCenterScreen extends StatelessWidget {
  const CallCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: (_) => const CallCenterScreenWatch());

  Widget _handset(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.callCenter_AppBarTitle), leading: const ExtBackButton()),
      body: const CallCenterBody(),
    );
  }
}
