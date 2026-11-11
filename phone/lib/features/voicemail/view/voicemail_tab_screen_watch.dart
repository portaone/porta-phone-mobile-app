import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';

/// Voicemail as a section of the bottom menu on a watch.
///
/// No bar: the list draws the whole face under the section's name.
class VoicemailTabScreenWatch extends StatelessWidget {
  const VoicemailTabScreenWatch({super.key, required this.title});

  /// The section's name, heading the list.
  final String title;

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(body: VoicemailWatchBody(title: title));
  }
}
