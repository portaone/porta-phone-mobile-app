import 'package:material_ui/material_ui.dart';

/// The title of a group of rows inside a watch list - a settings section:
/// small, in the primary colour, centred over the rows it names. A heading
/// for a screen reader, so the groups can be moved between.
class WatchListLabel extends StatelessWidget {
  const WatchListLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          semanticsLabel: label,
          style: themeData.textTheme.labelSmall?.copyWith(
            color: themeData.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
