import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

class Description extends StatelessWidget {
  const Description({super.key, required this.text, this.launchLinkableElement = false});

  final String text;
  final bool launchLinkableElement;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Linkify(
      text: text,
      onOpen: !launchLinkableElement ? null : _open,
      highlightLinkifyElement: launchLinkableElement,
      style: LinkifyStyle(
        style: themeData.textTheme.bodyMedium,
        linkStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _open(LinkableElement link) async {
    final url = Uri.parse(link.url);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
