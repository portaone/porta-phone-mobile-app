import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../favorites.dart';
import 'favorites_screen_style.dart';
import 'favorites_screen_styles.dart';

/// The favourites section on a watch. No app bar and no reorder button: the
/// list draws the whole face.
class FavoritesScreenWatch extends StatelessWidget {
  const FavoritesScreenWatch({super.key, required this.title, required this.cdrsEnabled, this.style});

  /// The section's name, heading the list.
  final String title;

  final bool cdrsEnabled;
  final FavoritesScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).extension<FavoritesScreenStyles>()?.primary;
    return ThemedScaffold(
      background: effectiveStyle?.background,
      contentThemeOverride: effectiveStyle?.contentThemeOverride ?? ThemeMode.system,
      body: FavoritesWatchList(
        cdrsEnabled: cdrsEnabled,
        body: (context, favorites, tileBuilder) =>
            FavoritesWatchBody(title: title, favorites: favorites, tileBuilder: tileBuilder),
      ),
    );
  }
}
