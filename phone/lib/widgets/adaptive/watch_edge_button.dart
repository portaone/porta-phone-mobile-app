import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'screen_shape.dart';

/// The primary action of a watch screen, filling the bottom of the face.
///
/// On a round face the button is a cap whose bottom follows the bezel and
/// whose top is flat with rounded corners; on a rectangular watch it is a
/// capsule across the width. Either way it is the largest target the face
/// can offer and sits where the thumb lands, which is why watch screens put
/// their one action there instead of in the middle of the content.
///
/// The geometry is the window's: the widget must sit at the bottom of a
/// screen that fills the window, with nothing under it - no bottom bar, no
/// safe-area or keyboard padding - or its outline stops following the bezel.
///
/// [builder] draws the button itself - usually an [ElevatedButton] - with
/// the style it is given: the outline and the label padding. A screen merges
/// it over its own style (`overlay.merge(themeStyle)`), so the colours stay
/// the theme's; this widget only decides the size, the shape and the place.
class WatchEdgeButton extends StatelessWidget {
  const WatchEdgeButton({super.key, required this.builder, this.compact = false});

  final Widget Function(BuildContext context, ButtonStyle overlay) builder;

  /// A thinner button, for a screen whose content needs the room - a keypad.
  /// Still at least 44 points high, and as wide as the face allows.
  final bool compact;

  /// How much of the bottom of the window the button takes, gap included:
  /// what the content above it must leave free.
  static double reservedHeight(BuildContext context, {bool compact = false}) =>
      _Geometry.of(context, compact: compact).reserved;

  /// The padding of the button's label. The face narrows under the label, so
  /// on a round one the label sits above the middle of the cap and keeps off
  /// its sides; on a capsule it keeps off the rounded ends.
  static EdgeInsets _labelPadding(BuildContext context) =>
      context.isRoundScreen ? const EdgeInsets.fromLTRB(20, 0, 20, 12) : const EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final geometry = _Geometry.of(context, compact: compact);
    return Padding(
      padding: EdgeInsets.only(bottom: geometry.gap),
      child: SizedBox(
        width: geometry.width,
        height: geometry.height,
        child: builder(
          context,
          ButtonStyle(
            shape: WidgetStatePropertyAll(geometry.shape),
            padding: WidgetStatePropertyAll(_labelPadding(context)),
          ),
        ),
      ),
    );
  }
}

class _Geometry {
  const _Geometry({required this.gap, required this.width, required this.height, required this.shape});

  factory _Geometry.of(BuildContext context, {required bool compact}) {
    final size = MediaQuery.sizeOf(context);
    final small = context.isSmallWatch;
    if (context.isRoundScreen) {
      const gap = 3.0;
      final height = compact ? (small ? 44.0 : 50.0) : (small ? 54.0 : 62.0);
      final radius = size.shortestSide / 2 - gap;
      // The chord of the face at the button's top edge.
      final offset = radius - height;
      final width = 2 * math.sqrt(math.max(0, radius * radius - offset * offset));
      return _Geometry(
        gap: gap,
        width: width,
        height: height,
        shape: WatchEdgeButtonBorder(faceRadius: radius),
      );
    }
    const gap = 5.0;
    final height = compact ? 44.0 : (small ? 48.0 : 52.0);
    return _Geometry(gap: gap, width: size.width - 2 * gap, height: height, shape: const StadiumBorder());
  }

  final double gap;
  final double width;
  final double height;
  final OutlinedBorder shape;

  double get reserved => gap + height;
}

/// The outline of [WatchEdgeButton] on a round face: a rectangle with
/// rounded top corners, cut by the circle of the face.
///
/// The circle has [faceRadius] and touches the bottom of the button's rect
/// at its centre, so the bottom edge runs parallel to the bezel.
class WatchEdgeButtonBorder extends OutlinedBorder {
  const WatchEdgeButtonBorder({required this.faceRadius, this.topRadius = 22, super.side});

  final double faceRadius;
  final double topRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  /// The outline of [rect] grown by [delta] on every side (shrunk for a
  /// negative one), its circle kept around the same centre so the bottom edge
  /// stays parallel to the bezel.
  Path _outline(Rect rect, double delta) {
    final center = Offset(rect.center.dx, rect.bottom - faceRadius);
    final corner = Radius.circular(math.max(0, topRadius + delta));
    final top = RRect.fromRectAndCorners(rect.inflate(delta), topLeft: corner, topRight: corner);
    final face = Rect.fromCircle(center: center, radius: math.max(0, faceRadius + delta));
    return Path.combine(PathOperation.intersect, Path()..addRRect(top), Path()..addOval(face));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _outline(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _outline(rect, -side.strokeInset);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    // Centred on the line strokeAlign asks for - inside, on or outside the
    // outline - as the other Material borders do.
    canvas.drawPath(_outline(rect, side.strokeOffset / 2), side.toPaint());
  }

  @override
  WatchEdgeButtonBorder copyWith({BorderSide? side}) {
    return WatchEdgeButtonBorder(faceRadius: faceRadius, topRadius: topRadius, side: side ?? this.side);
  }

  @override
  ShapeBorder scale(double t) {
    return WatchEdgeButtonBorder(faceRadius: faceRadius * t, topRadius: topRadius * t, side: side.scale(t));
  }

  @override
  bool operator ==(Object other) {
    return other is WatchEdgeButtonBorder &&
        other.faceRadius == faceRadius &&
        other.topRadius == topRadius &&
        other.side == side;
  }

  @override
  int get hashCode => Object.hash(faceRadius, topRadius, side);
}
