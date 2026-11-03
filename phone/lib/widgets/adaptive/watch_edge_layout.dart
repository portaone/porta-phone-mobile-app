import 'package:material_ui/material_ui.dart';

import 'screen_shape.dart';
import 'watch_edge_button.dart';

/// A watch screen whose content stays put above one main action along the
/// bottom of the face: a call, a keypad. [WatchActionLayout] is the one whose
/// content scrolls.
///
/// [body] gets the face less the edge button's room; [padding] is the rest
/// of its padding (the content's sides and top by default). [backdrop], when
/// given, is drawn behind it over the whole face.
class WatchEdgeLayout extends StatelessWidget {
  const WatchEdgeLayout({
    super.key,
    required this.body,
    required this.edge,
    this.compact = false,
    this.padding,
    this.backdrop,
  });

  final Widget body;

  /// Builds the edge button's button over the edge's own style.
  final Widget Function(BuildContext context, ButtonStyle overlay) edge;

  /// The thinner edge button a keypad uses.
  final bool compact;
  final EdgeInsets? padding;
  final Widget? backdrop;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding ?? context.watchContentPadding();
    final backdrop = this.backdrop;
    return Stack(
      fit: StackFit.expand,
      children: [
        ?backdrop,
        Padding(
          padding: padding.copyWith(bottom: padding.bottom + WatchEdgeButton.reservedHeight(context, compact: compact)),
          child: body,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: WatchEdgeButton(compact: compact, builder: edge),
        ),
      ],
    );
  }
}
