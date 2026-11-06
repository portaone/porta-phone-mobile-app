import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// A text whole on a watch face, on a page that scrolls, for whatever a screen
/// has to cut short: going back returns to that screen.
class WatchTextScreen extends StatelessWidget {
  const WatchTextScreen({
    super.key,
    required this.text,
    this.style,
    this.background,
    this.contentThemeOverride = ThemeMode.system,
  });

  final String text;

  /// The style of the screen the text comes from, so it reads as part of it.
  final ExtendedTextStyle? style;

  final BackgroundStyle? background;
  final ThemeMode contentThemeOverride;

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      background: background,
      contentThemeOverride: contentThemeOverride,
      body: WatchScrollList(
        children: [ExtendedText(text, extendedStyle: style, textAlign: TextAlign.center)],
      ),
    );
  }
}
