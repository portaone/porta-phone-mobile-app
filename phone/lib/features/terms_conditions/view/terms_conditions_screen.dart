import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key, required this.initialUri, required this.userAgent});

  final Uri initialUri;
  final String userAgent;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// A watch has no web view: the terms open on the paired phone.
  Widget _watch(BuildContext context) => WatchOpenOnPhonePage(
    title: context.l10n.settings_ListViewTileTitle_termsConditions,
    // In the app's language, as the web view on a phone opens it.
    uri: WebViewContainer.withLocaleName(initialUri, context.l10n.localeName),
  );

  Widget _handset(BuildContext context) => WebViewContainer(initialUri: initialUri, userAgent: userAgent);
}
