import 'package:material_ui/material_ui.dart';

/// A value a watch page shows to be read, not pressed - a version, an id, a
/// field of an error: its label small above it, the value under it, centred.
/// A long value wraps rather than being cut, the page scrolling for it.
///
/// The value is a node of its own under the label, so automation that reads a
/// value by its [valueIdentifier] gets the value alone, as from the phone's
/// rows.
class WatchInfoRow extends StatelessWidget {
  const WatchInfoRow({super.key, required this.label, required this.value, this.valueIdentifier});

  final String label;
  final String value;

  /// The automation id of the value.
  final String? valueIdentifier;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: themeData.textTheme.labelSmall?.copyWith(
              color: themeData.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Semantics(
            identifier: valueIdentifier,
            // A node of its own, or the value merges into the label's.
            container: valueIdentifier != null,
            child: Text(value, textAlign: TextAlign.center, style: themeData.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
