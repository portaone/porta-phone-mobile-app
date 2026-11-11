import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Help on a watch face. A watch has no web view: Help opens on the paired
/// phone, in the app's language as the phone's web view would open it.
class HelpScreenWatch extends StatelessWidget {
  const HelpScreenWatch({super.key, required this.initialUri});

  /// The page the phone's web view opens.
  final Uri initialUri;

  @override
  Widget build(BuildContext context) => WatchOpenOnPhonePage(
    title: context.l10n.settings_ListViewTileTitle_help,
    uri: WebViewContainer.withLocaleName(initialUri, context.l10n.localeName),
  );
}
