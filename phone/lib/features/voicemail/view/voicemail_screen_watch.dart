import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/app_localizations.g.mapper.dart';

import '../widgets/widgets.dart';

/// Voicemail from the settings list on a watch.
///
/// No app bar: the list draws the whole face under the screen's name, and
/// what manages the whole mailbox stays on the phone.
class VoicemailScreenWatch extends StatelessWidget {
  const VoicemailScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: VoicemailWatchBody(title: context.l10n.voicemail_Widget_screenTitle));
  }
}
