import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The brand's about page on a watch face. A watch has no web view: the page
/// opens on the paired phone.
class WebAboutScreenWatch extends StatelessWidget {
  const WebAboutScreenWatch({super.key, required this.uri});

  /// The page the phone's web view opens.
  final Uri uri;

  @override
  Widget build(BuildContext context) => WatchOpenOnPhonePage(
    title: context.l10n.settings_ListViewTileTitle_about,
    // In the app's language, as the web view on a phone opens it.
    uri: WebViewContainer.withLocaleName(uri, context.l10n.localeName),
  );
}
