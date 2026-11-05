import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'watch_pill.dart';

/// A link inside a watch column - a page to read, a code to send again: an
/// underlined label, not a second pill, so it does not compete with the
/// screen's action; the whole line stays a fingertip's target.
class WatchLink extends StatelessWidget {
  const WatchLink({super.key, required this.label, required this.onPressed, this.identifier, this.linkKey});

  final String label;

  /// Null disables the link.
  final VoidCallback? onPressed;

  /// The automation id of the link.
  final String? identifier;

  /// The key automation finds the link by.
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    final link = TextButton(
      key: linkKey,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(WatchPill.height),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(decoration: TextDecoration.underline),
      ),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
    final identifier = this.identifier;
    return identifier == null ? link : SemanticAction(identifier: identifier, child: link);
  }
}
