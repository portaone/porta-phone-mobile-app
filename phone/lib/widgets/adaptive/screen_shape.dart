import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:device_profile/device_profile.dart' show PlatformDeviceProfile;
import 'package:provider/provider.dart';

import 'adaptive_metrics.dart';
import 'form_factor.dart';

/// What the platform reports about the shape of the screen.
///
/// Read once at startup and shared with the widget tree; screens ask
/// [ScreenShapeContext.isRoundScreen] rather than this directly.
@immutable
class ScreenShape {
  const ScreenShape({this.isRound});

  /// Whether the display is round, as Android reports it
  /// (`Configuration.isScreenRound`); null where nothing reports it - other
  /// platforms, the web preview, a failed call.
  final bool? isRound;

  /// Asks the platform. Never throws: without an answer the shape is inferred
  /// from the window. The plugin keeps its one read, so this and the device
  /// name at startup share a single platform call.
  static Future<ScreenShape> query() async {
    final profile = await const PlatformDeviceProfile().read();
    return ScreenShape(isRound: profile?.screenShape.isRound);
  }

  @override
  bool operator ==(Object other) => other is ScreenShape && other.isRound == isRound;

  @override
  int get hashCode => isRound.hashCode;
}

/// The shape and size class of the watch face this context is drawn in.
extension ScreenShapeContext on BuildContext {
  /// Whether this is a round watch face.
  ///
  /// The platform's answer wins when there is one ([ScreenShape] in the
  /// tree). Without it - the configurator's preview, tests - a watch whose
  /// window is square counts as round: round faces are square windows (192,
  /// 227), rectangular watches are taller than wide (162x197, 208x248).
  bool get isRoundScreen {
    final size = MediaQuery.sizeOf(this);
    if (FormFactor.fromSize(size) != FormFactor.watch) return false;
    final reported = Provider.of<ScreenShape?>(this, listen: false)?.isRound;
    return reported ?? (size.width - size.height).abs() < 1;
  }

  /// Whether this is a watch below [FormFactorBreakpoints.smallWatchMaxShortestSide].
  bool get isSmallWatch {
    final size = MediaQuery.sizeOf(this);
    return FormFactor.fromSize(size) == FormFactor.watch &&
        size.shortestSide < FormFactorBreakpoints.smallWatchMaxShortestSide;
  }

  /// The padding of a screen's content on a watch face: in from a round
  /// face's edge far enough that the top line and the side columns stay
  /// clear of the bezel; the layout's inset and gap on a rectangular watch.
  EdgeInsets watchContentPadding() {
    final size = MediaQuery.sizeOf(this);
    if (isRoundScreen) {
      final side = size.width * _roundContentSide;
      return EdgeInsets.fromLTRB(side, size.height * _roundContentTop, side, 0);
    }
    final metrics = adaptiveMetrics;
    return EdgeInsets.fromLTRB(metrics.gap, metrics.inset, metrics.gap, 0);
  }

  /// The padding of a scrolling list on a watch face.
  ///
  /// On a round face an item near the top or bottom is clipped where the
  /// face narrows, so the list keeps further in and leaves room to scroll its
  /// last item up to the wide middle. [minBottom] keeps the last item clear
  /// of anything drawn over the bottom edge, such as a fade.
  EdgeInsets watchListPadding({double minBottom = 0}) {
    final size = MediaQuery.sizeOf(this);
    if (isRoundScreen) {
      final side = size.width * _roundListSide;
      return EdgeInsets.fromLTRB(
        side,
        size.height * _roundListTop,
        side,
        math.max(size.height * _roundListBottom, minBottom),
      );
    }
    final inset = adaptiveMetrics.inset;
    return EdgeInsets.fromLTRB(inset, inset, inset, math.max(inset, minBottom));
  }
}

/// Whether a watch screen's body shrinks for the keyboard: it does not. The
/// watch keyboard covers the whole face, so shrinking the body for it would
/// only lift the edge button off the bezel underneath.
const watchResizesForKeyboard = false;

/// The inset that keeps content inside the square inscribed in a round face
/// of [diameter]: (1 - 1 / sqrt 2) / 2 of it, 28 on a 192 face.
double roundSafeInset(double diameter) => diameter * 0.1464;

// A list is narrower than the inscribed square would make it: its items are
// pills, whose rounded ends fit into the curve.
const _roundListSide = 0.13;
const _roundListTop = 0.12;
const _roundListBottom = 0.2;

// Content that does not scroll keeps to the middle of a round face; these
// leave the corners of a three-column grid and the top line inside it.
const _roundContentSide = 0.12;
const _roundContentTop = 0.1;
