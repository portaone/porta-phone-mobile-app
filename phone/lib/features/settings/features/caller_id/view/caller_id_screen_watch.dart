import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../caller_id.dart';

/// Caller ID on a watch: the default number only, the main one and the
/// account's other numbers. Dial code matching - rules per country code, with
/// a form to add one - stays on the phone, and the page says so under the
/// numbers.
class CallerIdScreenWatch extends StatelessWidget {
  const CallerIdScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.settings_ListViewTileTitle_callerId;
    return BlocBuilder<CallerIdSettingsCubit, CallerIdSettingsState?>(
      builder: (context, state) {
        if (state == null) {
          return Scaffold(
            body: WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading),
          );
        }
        final main = state.mainNumber;
        return SettingsWatchChoicePage<String?>(
          title: title,
          header: [WatchListLabel(l10n.settings_callerId_defaultTitle)],
          // The main number stands for "no default of its own", stored as null.
          options: [
            if (main != null) SettingsWatchOption(value: null, label: main, fitTitle: true),
            for (final number in state.additionalNumbers)
              SettingsWatchOption(value: number, label: number, fitTitle: true),
          ],
          selected: state.settings.defaultNumber,
          onChosen: (number) => context.read<CallerIdSettingsCubit>().setDefaultNumber(number),
          footer: [WatchListNote(l10n.settings_Watch_onPhone(l10n.settings_callerId_dialCodeMatching_title))],
        );
      },
    );
  }
}
