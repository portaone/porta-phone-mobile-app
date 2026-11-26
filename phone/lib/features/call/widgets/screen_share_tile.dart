// The tile that stands in for the camera preview while the phone's screen is shown in the call:
// the same size and place as the preview, the menu's colour, a screen icon, "Sharing screen" and a
// Stop in the end-call colour. Shown by CallShell in the floating overlay of the call screen; the
// Stop goes to CallBloc as CallControlEvent.screenShareStopped.
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../utils/thumbnail_layout.dart';
import '../view/call_screen_styles.dart';

/// Says the screen is being shown in place of the camera and offers to stop it.
///
/// A preview of the screen would show the person the screen they are already looking at, and
/// the picture of what they share is the far end's; so the tile only says what goes on.
class ScreenShareTile extends StatelessWidget {
  const ScreenShareTile({
    super.key,
    required this.orientation,
    required this.onStopPressed,
    this.smallerSide = ThumbnailLayout.defaultSmallerSide,
  });

  /// Current device orientation; the tile is upright in portrait and lying down in landscape,
  /// as the camera preview it replaces.
  final Orientation orientation;

  /// Stops the share.
  final VoidCallback onStopPressed;

  /// The smaller side of the tile; the other one follows the aspect ratio.
  final double smallerSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    // The Stop takes the end-call button's look: it ends something, as that one does.
    final hangupStyle = theme.extension<CallScreenStyles>()?.primary?.actions?.hangup;
    final stopStyle = TextButton.styleFrom(
      minimumSize: const Size(56, 28),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
      textStyle: theme.textTheme.labelMedium,
    ).merge(hangupStyle);

    return SemanticId(
      identifier: callScreenShareTileId,
      child: SizedBox.fromSize(
        size: ThumbnailLayout.calcFrameSize(orientation: orientation, smallerSide: smallerSide),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            // The colour of the call screen's menu, where the share is started and stopped.
            color: colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(8),
              // Scaled down rather than cut: lying down in landscape the tile is short.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(Icons.screen_share_outlined, color: colorScheme.onSurface, size: 28),
                    Text(
                      l10n.call_ScreenShareTile_title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
                    ),
                    SemanticAction.button(
                      label: l10n.call_ScreenShareTile_stop,
                      identifier: callScreenShareStopId,
                      child: TextButton(
                        onPressed: onStopPressed,
                        style: stopStyle,
                        // Named once, by the action around it.
                        child: ExcludeSemantics(child: Text(l10n.call_ScreenShareTile_stop)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
