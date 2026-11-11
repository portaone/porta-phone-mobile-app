import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../widgets/widgets.dart';

/// The queues from the settings stack on a watch.
///
/// No app bar: the queues draw the whole face under the screen's name.
class CallCenterScreenWatch extends StatelessWidget {
  const CallCenterScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CallCenterWatchBody(title: context.l10n.callCenter_AppBarTitle));
  }
}
