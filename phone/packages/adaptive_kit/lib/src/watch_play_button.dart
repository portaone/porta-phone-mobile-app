import 'package:material_ui/material_ui.dart';

import 'screen_shape.dart';
import 'semantic_action.dart';

/// Play and pause of a recording on a watch: one round button, the ring
/// around it filling as the recording plays, and [time] under it - a face has
/// no room for a slider, and a finger on one would cover what it moves.
///
/// One node for assistive technology: [label] says what the press does
/// ("Play", "Pause"), [value] how far it has got, in words. While the
/// recording is on its way the ring turns without an end.
class WatchPlayButton extends StatelessWidget {
  const WatchPlayButton({
    super.key,
    required this.playing,
    required this.label,
    required this.onPressed,
    this.progress = 0,
    this.loading = false,
    this.time,
    this.value,
    this.identifier,
    this.buttonKey,
  });

  /// Whether the recording plays: the button offers to pause it.
  final bool playing;

  /// What a screen reader says for the button: what the press does.
  final String label;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;

  /// How far the recording has played, from 0 to 1.
  final double progress;

  /// Whether the recording is on its way: the ring turns without an end.
  final bool loading;

  /// Where it stands, for the eye - `0:12 / 0:42`; read out as [value].
  final String? time;

  /// Where it stands in words, for a screen reader.
  final String? value;

  final String? identifier;
  final Key? buttonKey;

  /// The button's side on this face.
  static double sizeOf(BuildContext context) => context.isSmallWatch ? 44.0 : 56.0;

  static const _ring = 4.0;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final side = sizeOf(context);
    final time = this.time;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        SemanticAction.button(
          label: label,
          identifier: identifier,
          child: Semantics(
            value: value,
            child: SizedBox.square(
              dimension: side + _ring * 2 + 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: CircularProgressIndicator(
                        value: loading ? null : progress.clamp(0, 1),
                        strokeWidth: _ring,
                        color: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: buttonKey,
                    constraints: BoxConstraints.tightFor(width: side, height: side),
                    style: IconButton.styleFrom(padding: EdgeInsets.zero, iconSize: side * 0.46),
                    onPressed: onPressed,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (time != null)
          // Drawn for the eye: read out, `0:12` is a time of day.
          ExcludeSemantics(
            child: Text(
              time,
              maxLines: 1,
              style: themeData.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
