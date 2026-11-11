import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../cubit/presence_settings_cubit.dart';
import '../models/presence_settings_preset.dart';
import 'presence_settings_presets.dart';

/// SIP presence on a watch: the presets only, each with its mark; settings
/// that match none show "Custom" over them. The configuration itself stays on
/// the phone.
class PresenceSettingsScreenWatch extends StatelessWidget {
  const PresenceSettingsScreenWatch({super.key, required this.presets});

  /// The presets offered, in the phone's order.
  final List<PresenceSettingsPreset> presets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PresenceSettingsCubit>();
    return BlocBuilder<PresenceSettingsCubit, PresenceSettings>(
      builder: (context, state) {
        final selected = matchingPresenceSettingsPreset(presets, state);
        return SettingsWatchChoicePage<PresenceSettingsPreset>(
          title: l10n.settings_ListViewTileTitle_presence,
          // Blank settings are the Available preset, so they never read Custom.
          header: [if (selected == null) WatchListNote(l10n.presence_settings_presets_label_custom)],
          options: [
            for (final preset in presets)
              SettingsWatchOption(
                value: preset,
                label: preset.name,
                leading: PresenceSettingsPresetMark(preset: preset),
              ),
          ],
          selected: selected,
          onChosen: (preset) => cubit.setPresenceSettings(applyPresenceSettingsPreset(state, preset)),
          footer: [WatchListNote(l10n.presence_Watch_configOnPhone)],
        );
      },
    );
  }
}
