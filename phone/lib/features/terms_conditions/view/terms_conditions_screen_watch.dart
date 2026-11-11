import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The terms on a watch face. A watch has no web view: the terms open on the
/// paired phone.
class TermsConditionsScreenWatch extends StatelessWidget {
  const TermsConditionsScreenWatch({super.key, required this.initialUri});

  /// The page the phone's web view opens.
  final Uri initialUri;

  @override
  Widget build(BuildContext context) => WatchOpenOnPhonePage(
    title: context.l10n.settings_ListViewTileTitle_termsConditions,
    // In the app's language, as the web view on a phone opens it.
    uri: WebViewContainer.withLocaleName(initialUri, context.l10n.localeName),
  );
}
