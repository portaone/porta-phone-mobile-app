import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/styles/styles.dart';

/// A small mark on the rim of a round call control: something about what this
/// control stands for needs attention.
///
/// A mark and nothing more. It takes no tap, so the control keeps its own, and
/// it says nothing to a screen reader: the control's label carries the words.
class CallAttentionDot extends StatelessWidget {
  const CallAttentionDot({super.key, required this.shown, required this.child});

  /// The diameter of the dot, its ring included.
  static const double size = 14;

  /// The point of a round control's rim the dot's centre sits on: its upper
  /// end corner, at 45 degrees.
  static const AlignmentDirectional rimPoint = AlignmentDirectional(math.sqrt1_2, -math.sqrt1_2);

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!shown) return child;

    final themeData = Theme.of(context);
    final color =
        themeData.extension<SnackBarStyles>()?.primary?.warningBackgroundColor ?? themeData.colorScheme.tertiary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: rimPoint,
            // A box of no size puts the dot's centre, not its corner, on the point.
            child: SizedBox.shrink(
              child: OverflowBox(
                minWidth: size,
                maxWidth: size,
                minHeight: size,
                maxHeight: size,
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('call-attention-dot'),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: themeData.colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
