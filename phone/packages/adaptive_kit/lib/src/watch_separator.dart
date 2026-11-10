import 'package:material_ui/material_ui.dart';

/// What separates a list's controls - its search, its filter - from its
/// rows on a watch: a short centred bar. A line across would run into the
/// bezel of a round face; this one reads the same on every shape.
///
/// Decoration only: it is not read out.
class WatchSeparator extends StatelessWidget {
  const WatchSeparator({super.key});

  static const width = 64.0;
  static const thickness = 3.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: width,
          height: thickness,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(thickness),
          ),
        ),
      ),
    );
  }
}
