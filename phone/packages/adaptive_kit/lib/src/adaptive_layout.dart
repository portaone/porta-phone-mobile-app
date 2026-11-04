import 'package:material_ui/material_ui.dart';

import 'form_factor.dart';

/// Picks which of a screen's arrangements to show for the device's
/// [FormFactor].
///
/// The one place a screen decides on the device class: the arrangements it
/// hands over never read the class themselves. Only [handset] is required;
/// a class without its own arrangement falls back to it, so screens move to
/// watch or large layouts one at a time and the rest keep working as before.
///
/// Everything the arrangements share - the bloc, controllers, text the user
/// typed - must live above this widget: crossing a class boundary swaps the
/// subtree and drops whatever state it held.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.handset, this.watch, this.large});

  /// The arrangement for a phone, and for any class without its own.
  final WidgetBuilder handset;

  /// The arrangement for a watch face.
  final WidgetBuilder? watch;

  /// The arrangement for a tablet or a desktop window.
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    final builder = context.formFactor.resolve(handset: handset, watch: watch, large: large);
    return builder(context);
  }
}
