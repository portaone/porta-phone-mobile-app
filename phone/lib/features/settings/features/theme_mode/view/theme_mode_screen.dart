import 'package:material_ui/material_ui.dart';
import 'package:webtrit_phone/app/keys.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/widgets.dart';

class ThemeModeScreen extends StatelessWidget {
  const ThemeModeScreen({super.key});

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// Where the brand fixes the theme the rows are shown dimmed, offering nothing.
  Widget _watch(BuildContext context) {
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

  Widget _handset(BuildContext context) {
    const themeModes = ThemeMode.values;
    final themeSettings = context.watch<ThemeSettings>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings_ListViewTileTitle_themeMode), leading: const ExtBackButton()),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return RadioGroup<ThemeMode>(
            groupValue: themeSettings.effectiveThemeMode(state.themeMode),
            onChanged: (ThemeMode? value) {
              if (!themeSettings.isThemeModeSupported || value == null) return;
              context.read<AppBloc>().add(AppThemeModeChanged(value));
            },
            child: ListView.separated(
              itemCount: themeModes.length,
              separatorBuilder: (context, index) => const ListTileSeparator(),
              itemBuilder: (context, index) {
                final themeMode = themeModes[index];
                return SemanticAction(
                  identifier: settingsOptionId(settingsThemeModeOptionIdPrefix, themeMode.name),
                  child: RadioListTile<ThemeMode>(
                    value: themeMode,
                    title: Text(themeMode.l10n(context)),
                    enabled: themeSettings.isThemeModeSupported,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
