import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'watch_text_screen.dart';

/// Pushed on the root router: a text somebody opens and closes belongs to no
/// feature's routes, and sign-in's are declared from its cubit's state.
@RoutePage()
class WatchTextScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const WatchTextScreenPage({
    required this.text,
    this.style,
    this.background,
    this.contentThemeOverride = ThemeMode.system,
  });

  final String text;
  final ExtendedTextStyle? style;
  final BackgroundStyle? background;
  final ThemeMode contentThemeOverride;

  @override
  Widget build(BuildContext context) {
    return WatchTextScreen(
      text: text,
      style: style,
      background: background,
      contentThemeOverride: contentThemeOverride,
    );
  }
}
