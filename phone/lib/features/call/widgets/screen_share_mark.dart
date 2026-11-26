// The sign that the host shares his screen to his room: a ring and a small screen badge in the
// theme's accent around the control that holds the share's Stop - More on the room's full screen
// (conference_full_screen.dart) and the call screen's options menu (call_controls.dart).
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// A ring and a small screen badge in the accent around [child], the control that holds the
/// share's Stop; the badge is [identifier] for a case. Drawing only: the touch is the control's,
/// and both stay inside its bounds, as it may sit at the screen's edge.
class ScreenShareMark extends StatelessWidget {
  const ScreenShareMark({super.key, required this.identifier, required this.child});

  final String identifier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: SemanticId(
              identifier: identifier,
              child: DecoratedBox(
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(Icons.screen_share, size: 12, color: colors.onPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
