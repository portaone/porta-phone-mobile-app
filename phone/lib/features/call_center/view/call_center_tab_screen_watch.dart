import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';

/// The queues as a section of the bottom menu on a watch.
///
/// No bar: the queues draw the whole face under the section's name.
class CallCenterTabScreenWatch extends StatelessWidget {
  const CallCenterTabScreenWatch({super.key, required this.title});

  /// The section's name, heading the queues.
  final String title;

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(body: CallCenterWatchBody(title: title));
  }
}
