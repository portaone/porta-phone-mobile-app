import 'package:material_ui/material_ui.dart';

/// Fades [child] out over a band of [fadeHeight] ending [bottomInset] above
/// its bottom edge, and hides it below that.
///
/// A watch screen's scrolling content runs under the edge button; the fade
/// lets it end softly above the button instead of being cut by it, and tells
/// the user there is more to scroll. With a [bottomInset] of zero it fades
/// into the bottom of the face. A [topFadeHeight] fades its top edge the same
/// way, for content that scrolls up out of a box rather than off the face.
class WatchFadeMask extends StatelessWidget {
  const WatchFadeMask({
    super.key,
    required this.child,
    this.bottomInset = 0,
    this.fadeHeight = 24,
    this.topFadeHeight = 0,
  });

  /// What fades.
  final Widget child;

  /// How far above the bottom edge the fade ends; below that nothing shows.
  final double bottomInset;

  /// The height of the band the bottom fades over.
  final double fadeHeight;

  /// The height of the band the top fades in over; none by default.
  final double topFadeHeight;

  @override
  Widget build(BuildContext context) {
    // A mask: only the alpha of its colours counts.
    final opaque = Theme.of(context).colorScheme.onSurface;
    final clear = opaque.withValues(alpha: 0);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final end = ((bounds.height - bottomInset) / bounds.height).clamp(0.0, 1.0);
        final top = (topFadeHeight / bounds.height).clamp(0.0, end);
        final start = ((bounds.height - bottomInset - fadeHeight) / bounds.height).clamp(top, end);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [if (topFadeHeight > 0) clear, opaque, opaque, clear, clear],
          stops: [if (topFadeHeight > 0) 0, top, start, end, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
