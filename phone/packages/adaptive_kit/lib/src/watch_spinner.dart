import 'package:material_ui/material_ui.dart';

/// The spinner of something on its way on a watch, in the one size every
/// watch screen shows it at - a section's loading page, a list's rows still
/// coming. [label] is what a screen reader says for it: the app's own word,
/// the kit having no strings of its own.
class WatchSpinner extends StatelessWidget {
  const WatchSpinner({super.key, required this.label});

  final String label;

  static const size = 24.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(strokeWidth: 3, semanticsLabel: label),
    );
  }
}
