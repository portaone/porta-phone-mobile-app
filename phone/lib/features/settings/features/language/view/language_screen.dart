import 'package:material_ui/material_ui.dart';
import 'package:webtrit_phone/app/keys.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/widgets.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// With a single supported language there is nothing to follow the system
  /// to, so the "default" (follow-system) entry is dropped and that one
  /// language offered.
  static final List<Locale> _locales = AppLocalizations.supportedLocales.length == 1
      ? AppLocalizations.supportedLocales
      : [LocaleExtension.defaultNull, ...AppLocalizations.supportedLocales];

  /// The row's id: the language it selects, "system" for the default entry.
  static String _optionId(Locale locale) =>
      settingsOptionId(settingsLanguageOptionIdPrefix, locale.isDefaultNull ? 'system' : locale.languageCode);

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  Widget _watch(BuildContext context) {
    final locale = context.select<AppBloc, Locale>((bloc) => bloc.state.locale);
    return SettingsWatchChoicePage<Locale>(
      title: context.l10n.settings_ListViewTileTitle_language,
      options: [
        for (final locale in _locales)
          SettingsWatchOption(value: locale, label: locale.l10n(context), identifier: _optionId(locale)),
      ],
      selected: locale,
      onChosen: (value) => context.read<AppBloc>().add(AppLocaleChanged(value)),
    );
  }

  Widget _handset(BuildContext context) {
    final locales = _locales;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings_ListViewTileTitle_language), leading: const ExtBackButton()),
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return RadioGroup<Locale?>(
            groupValue: state.locale,
            onChanged: (value) {
              context.read<AppBloc>().add(AppLocaleChanged(value ?? LocaleExtension.defaultNull));
            },
            child: ListView.separated(
              itemCount: locales.length,
              separatorBuilder: (context, index) => const ListTileSeparator(),
              itemBuilder: (context, index) {
                final locale = locales[index];
                // The visible title is translated, so the row is identified by
                // the language it selects; the "system default" entry is a
                // sentinel locale rather than a real language.
                return SemanticAction(
                  identifier: _optionId(locale),
                  child: RadioListTile<Locale?>(value: locale, title: Text(locale.l10n(context))),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
