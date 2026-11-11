import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../../widgets/settings_watch_choice.dart';

/// The language on a watch: a row per language the screen offers, the one in
/// force ticked.
class LanguageScreenWatch extends StatelessWidget {
  const LanguageScreenWatch({super.key, required this.locales, required this.optionId});

  /// The languages offered, in the phone's order.
  final List<Locale> locales;

  /// The id of the row of a language.
  final String Function(Locale locale) optionId;

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AppBloc, Locale>((bloc) => bloc.state.locale);
    return SettingsWatchChoicePage<Locale>(
      title: context.l10n.settings_ListViewTileTitle_language,
      options: [
        for (final locale in locales)
          SettingsWatchOption(value: locale, label: locale.l10n(context), identifier: optionId(locale)),
      ],
      selected: locale,
      onChosen: (value) => context.read<AppBloc>().add(AppLocaleChanged(value)),
    );
  }
}
