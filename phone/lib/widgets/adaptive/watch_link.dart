import 'package:material_ui/material_ui.dart';

import 'watch_pill.dart';

/// A link inside a watch column - a page to read, a code to send again: an
/// underlined label, not a second pill, so it does not compete with the
/// screen's action; the whole line stays a fingertip's target.
class WatchLink extends StatelessWidget {
  const WatchLink({super.key, required this.label, required this.onPressed});

  final String label;

  /// Null disables the link.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(WatchPill.height),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(decoration: TextDecoration.underline),
      ),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
