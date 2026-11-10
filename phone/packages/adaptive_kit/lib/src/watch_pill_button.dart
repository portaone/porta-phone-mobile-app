import 'package:material_ui/material_ui.dart';

import 'screen_shape.dart';
import 'semantic_action.dart';
import 'watch_pill.dart';

/// A tonal pill of a watch list's controls - a filter, an address book, an
/// action closing a list: an icon and a short label, one button for
/// assistive technology named by [semanticsLabel].
///
/// The label is set smaller to fit rather than cut when the pill shares a
/// row; on a small face it takes the icon's room too.
class WatchPillButton extends StatelessWidget {
  const WatchPillButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    this.icon,
    this.identifier,
    this.buttonKey,
  });

  final String label;

  /// The pill's name for a screen reader: what it shows and what a tap does.
  final String semanticsLabel;

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? identifier;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return SemanticAction(
      label: semanticsLabel,
      identifier: identifier,
      child: FilledButton.tonal(
        key: buttonKey,
        style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)))
            .merge(WatchPill.style),
        onPressed: onPressed,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (icon != null && !context.isSmallWatch) Icon(icon, size: 16),
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
