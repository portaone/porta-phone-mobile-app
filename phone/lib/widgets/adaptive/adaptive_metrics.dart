import 'package:material_ui/material_ui.dart';

import 'form_factor.dart';

/// The spacing a layout uses on the current [FormFactor].
///
/// New layout code takes its insets and gaps from here instead of fixed
/// constants, so the same widget tightens on a watch without a branch of its
/// own. The handset values are the ones the app has always used, so moving a
/// widget onto these metrics changes nothing on a phone.
@immutable
class AdaptiveMetrics {
  const AdaptiveMetrics({required this.inset, required this.gap, required this.minTapTarget});

  /// Phones and, until they get their own, larger screens.
  static const handset = AdaptiveMetrics(
    inset: kMinInteractiveDimension / 2,
    gap: 8,
    minTapTarget: kMinInteractiveDimension,
  );

  /// A watch face of about 200 logical pixels: a phone's 24 on each side
  /// would leave three quarters of it.
  static const watch = AdaptiveMetrics(inset: 8, gap: 4, minTapTarget: kMinInteractiveDimension);

  /// The metrics of [formFactor].
  static AdaptiveMetrics of(FormFactor formFactor) => formFactor.resolve(handset: handset, watch: watch);

  /// The space between the screen edge and its content.
  final double inset;

  /// The space between neighbouring elements of one group.
  final double gap;

  /// The smallest side of anything the user taps. The same on a watch: a
  /// fingertip does not shrink with the screen, and Wear OS asks for 48 too.
  final double minTapTarget;

  @override
  bool operator ==(Object other) =>
      other is AdaptiveMetrics && other.inset == inset && other.gap == gap && other.minTapTarget == minTapTarget;

  @override
  int get hashCode => Object.hash(inset, gap, minTapTarget);
}

/// The [AdaptiveMetrics] of the window this context is drawn in.
extension AdaptiveMetricsContext on BuildContext {
  AdaptiveMetrics get adaptiveMetrics => AdaptiveMetrics.of(formFactor);
}
