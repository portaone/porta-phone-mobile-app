import 'package:material_ui/material_ui.dart';

/// The class of device the app is laid out for.
///
/// It decides a screen's composition - what is on it and in which
/// arrangement - not its exact sizes; sizes within a class still follow the
/// constraints a screen is given. Orientation is a separate axis, decided by
/// `OrientationLayoutSelector` inside a class.
enum FormFactor {
  /// A watch face: both sides of the window are below
  /// [FormFactorBreakpoints.watchMaxSide].
  watch,

  /// A phone, upright or lying down; the class every screen has a layout for.
  handset,

  /// A tablet or a desktop window: the shortest side is at least
  /// [FormFactorBreakpoints.largeMinShortestSide].
  large;

  /// The class of a window of [size] logical pixels.
  ///
  /// Decided from the size alone, never from the platform: the same app
  /// runs on Wear OS, on plain Android in a watch body (which reports no
  /// watch feature) and in the configurator's device preview (where the
  /// platform is the browser). A phone window shrunk below the watch size
  /// gets the watch arrangement, which is the one designed for that space.
  static FormFactor fromSize(Size size) {
    if (size.longestSide < FormFactorBreakpoints.watchMaxSide) return FormFactor.watch;
    if (size.shortestSide >= FormFactorBreakpoints.largeMinShortestSide) return FormFactor.large;
    return FormFactor.handset;
  }

  /// Picks the value for this class.
  ///
  /// Only [handset] is required: a class without its own value falls back to
  /// it, so a screen can gain a watch or large value without every other
  /// screen having to.
  T resolve<T>({required T handset, T? watch, T? large}) {
    return switch (this) {
      FormFactor.watch => watch ?? handset,
      FormFactor.handset => handset,
      FormFactor.large => large ?? handset,
    };
  }
}

/// The window sizes, in logical pixels, where one [FormFactor] ends and the
/// next begins; the only place these numbers live.
abstract final class FormFactorBreakpoints {
  /// Every watch the app is previewed on fits under it (round 192 and 227,
  /// rectangular 162x197 and 208x248, and 320x240, a watch phone worn wider
  /// than tall); no phone does, its long side is above 500 even on the
  /// narrowest ones.
  static const double watchMaxSide = 340;

  /// Within the watch class, the faces too small for the larger sizes: the
  /// 192 round and the 162x197 rectangular sit below it, the 227 round and
  /// the 208x248 rectangular above. Edge button, logo and greeting all switch
  /// at this one line.
  static const double smallWatchMaxShortestSide = 200;

  /// Material's threshold for a tablet: a 7-inch tablet is 600 on its short
  /// side, the largest phone stays below it.
  static const double largeMinShortestSide = 600;
}

/// The [FormFactor] of the window this context is drawn in.
extension FormFactorContext on BuildContext {
  /// Read from the window, not from the constraints of the enclosing widget:
  /// the class describes the device, and a pane inside a large window is
  /// still on a large device. Rebuilds only when the window size changes.
  FormFactor get formFactor => FormFactor.fromSize(MediaQuery.sizeOf(this));
}
