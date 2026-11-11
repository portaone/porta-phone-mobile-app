import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/caller_id_settings.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../caller_id.dart';
import '../widgets/widgets.dart';

class CallerIdSettingsScreen extends StatefulWidget {
  const CallerIdSettingsScreen({super.key});

  @override
  State<CallerIdSettingsScreen> createState() => _CallerIdSettingsScreenState();
}

class _CallerIdSettingsScreenState extends State<CallerIdSettingsScreen> {
  bool showMatcherForm = false;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// The default number only: the main one and the account's other numbers.
  /// Dial code matching - rules per country code, with a form to add one -
  /// stays on the phone, and the page says so under the numbers.
  Widget _watch(BuildContext context) {
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

  Widget _handset(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings_ListViewTileTitle_callerId)),
      body: BlocBuilder<CallerIdSettingsCubit, CallerIdSettingsState?>(
        builder: (context, state) {
          if (state == null) return const Center(child: CircularProgressIndicator());

          return SemanticId(
            identifier: callerIdScreenId,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Text(
                      l10n.settings_callerId_defaultTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DefaultNumberForm(state: state),
                    Text(
                      l10n.settings_callerId_dialCodeMatching_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Numbered over the rows that are actually drawn, so the
                    // ids stay 1, 2, 3 whatever the list holds besides them.
                    for (final (index, matcher) in state.settings.matchers.whereType<PrefixMatcher>().indexed)
                      MatcherTile(matcher: matcher, index: index),
                    if (showMatcherForm == false)
                      Center(
                        child: SemanticAction(
                          label: l10n.callerId_SemanticsLabel_addMatch,
                          identifier: callerIdAddMatchId,
                          child: IconButton(
                            onPressed: () => setState(() => showMatcherForm = true),
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      )
                    else
                      MatcherAddingForm(
                        numbers: state.additionalNumbers,
                        addedPrefixes: state.settings.matchers.whereType<PrefixMatcher>().map((e) => e.prefix).toList(),
                        onSave: (prefix, number, country) {
                          context.read<CallerIdSettingsCubit>().addPrefixMatcher(prefix, number, country: country);
                          setState(() => showMatcherForm = false);
                        },
                        onCancel: () => setState(() => showMatcherForm = false),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
