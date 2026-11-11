import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.initialUri, required this.userAgent});

  final Uri initialUri;
  final String userAgent;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// A watch has no web view: Help opens on the paired phone, in the app's
  /// language as the phone's web view would open it.
  Widget _watch(BuildContext context) => WatchOpenOnPhonePage(
    title: context.l10n.settings_ListViewTileTitle_help,
    uri: WebViewContainer.withLocaleName(initialUri, context.l10n.localeName),
  );

  Widget _handset(BuildContext context) => WebViewContainer(
    title: Text(context.l10n.settings_ListViewTileTitle_help),
    initialUri: initialUri,
    userAgent: userAgent,
  );
}
