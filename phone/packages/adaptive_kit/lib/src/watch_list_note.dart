import 'package:material_ui/material_ui.dart';

/// A line in a watch list's place of rows: there are none, or a search found
/// none. Centred, muted, read out when it appears, so a list that empties
/// while someone types says so without them moving to it.
class WatchListNote extends StatelessWidget {
  const WatchListNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: themeData.textTheme.labelLarge?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
