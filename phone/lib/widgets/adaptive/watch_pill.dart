import 'package:material_ui/material_ui.dart';

/// The shape of a full-width button inside a watch screen's column - a list
/// entry, a secondary action, a link: a pill at the tap floor's height.
///
/// A screen merges it over the button's own style, so the colours stay the
/// theme's: `WatchPill.style.merge(themeStyle)`.
abstract final class WatchPill {
  static const double height = 48;

  static const ButtonStyle style = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(height)),
    shape: WidgetStatePropertyAll(StadiumBorder()),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
  );
}
