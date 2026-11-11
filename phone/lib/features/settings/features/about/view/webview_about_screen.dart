import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'webview_about_screen_watch.dart';

class WebAboutScreen extends StatelessWidget {
  const WebAboutScreen({
    super.key,
    required this.baseAppAboutUrl,
    required this.userAgent,
    required this.packageInfo,
    required this.infoRepository,
  });

  final Uri baseAppAboutUrl;
  final String userAgent;
  final PackageInfo packageInfo;
  final SystemInfoRepository infoRepository;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    handset: _handset,
    watch: (_) => WebAboutScreenWatch(uri: _uri),
  );

  Widget _handset(BuildContext context) {
    return WebViewContainer(
      title: Text(context.l10n.settings_ListViewTileTitle_about),
      initialUri: _uri,
      userAgent: userAgent,
    );
  }

  /// The brand's about page, told which app and which Core it describes.
  Uri get _uri => baseAppAboutUrl.replace(
    queryParameters: {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,

      /// TODO: use session repository
      'coreUrl': infoRepository.getCoreUrl().toString(),
    },
  );
}
