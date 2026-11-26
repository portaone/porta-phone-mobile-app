// The border in the theme's accent that marks who the conference room shows as speaking, laid over
// what already shows him: a tile, a thumbnail or a shared screen of the room's full screen
// (conference_full_screen.dart), a row of the room's panel (conference_panel.dart), the host's own
// camera preview (view/call_shell.dart). It takes no place and no taps and moves nothing under it:
// the layout stays as it was, only the border comes and goes. Who speaks, and the hold against
// flicker, are the room's (ConferenceState.speaker); the accent is the one the screen share's ring
// on More uses (screen_share_mark.dart).
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// A border of [width] in the theme's accent, rounded by [radius], over the box it fills less
/// [margin] - the place of what it marks. Its node carries [identifier] alone, for automation.
class SpeakingFrame extends StatelessWidget {
  const SpeakingFrame({
    super.key,
    required this.identifier,
    required this.radius,
    this.width = 3,
    this.margin = EdgeInsets.zero,
  });

  final String identifier;
  final double radius;
  final double width;

  /// Where what it marks lies inside the box: a row of the panel is inset in its own.
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: margin,
        child: SemanticId(
          identifier: identifier,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: width),
            ),
          ),
        ),
      ),
    );
  }
}
