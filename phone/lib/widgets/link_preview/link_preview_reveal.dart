import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/utils/link_preview.dart';

/// Shows [card] for [preview] once there is one, springing it open; nothing while there is none.
class LinkPreviewReveal extends StatelessWidget {
  const LinkPreviewReveal({required this.preview, required this.card, super.key});

  final LinkPreview? preview;
  final Widget Function(LinkPreview preview) card;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      sizeCurve: Curves.elasticOut,
      firstCurve: Curves.easeInExpo,
      alignment: Alignment.center,
      firstChild: preview == null ? const SizedBox.shrink() : card(preview),
      secondChild: const SizedBox.shrink(),
      crossFadeState: preview != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
