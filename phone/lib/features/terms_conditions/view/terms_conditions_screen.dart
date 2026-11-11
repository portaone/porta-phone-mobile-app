import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'terms_conditions_screen_watch.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key, required this.initialUri, required this.userAgent});

  final Uri initialUri;
  final String userAgent;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    handset: _handset,
    watch: (_) => TermsConditionsScreenWatch(initialUri: initialUri),
  );

  Widget _handset(BuildContext context) {
    return WebViewContainer(initialUri: initialUri, userAgent: userAgent);
  }
}
