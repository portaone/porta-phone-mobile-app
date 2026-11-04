import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';

import 'configurable_theme_image.dart';

/// A themed logo sized for a watch face.
///
/// The theme sizes a logo for a phone: a share of the screen width and
/// paddings of tens of points around it. On a watch only its height counts,
/// and those paddings would shrink the picture itself to a speck, so they are
/// dropped and the logo is fitted into [height].
class WatchLogo extends StatelessWidget {
  const WatchLogo({super.key, required this.style, required this.height});

  final ThemeImageStyle? style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    if (style == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConfigurableThemeImage(
          style: ThemeImageStyle.merge(style, const ThemeImageStyle(padding: EdgeInsets.zero)),
        ),
      ),
    );
  }
}
