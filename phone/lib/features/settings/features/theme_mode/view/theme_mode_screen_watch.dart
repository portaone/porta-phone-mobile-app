import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';

import '../../../widgets/settings_watch_choice.dart';

/// The theme mode on a watch: a row per mode, the one in force ticked. Where
/// the brand fixes the theme the rows are shown dimmed, offering nothing.
class ThemeModeScreenWatch extends StatelessWidget {
  const ThemeModeScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettings>();
    final mode = context.select<AppBloc, ThemeMode>((bloc) => bloc.state.themeMode);
    return SettingsWatchChoicePage<ThemeMode>(
      title: context.l10n.settings_ListViewTileTitle_themeMode,
      options: [
        for (final themeMode in ThemeMode.values)
          SettingsWatchOption(
            value: themeMode,
            label: themeMode.l10n(context),
            identifier: settingsOptionId(settingsThemeModeOptionIdPrefix, themeMode.name),
          ),
      ],
      selected: themeSettings.effectiveThemeMode(mode),
      enabled: themeSettings.isThemeModeSupported,
      onChosen: (value) => context.read<AppBloc>().add(AppThemeModeChanged(value)),
    );
  }
}
