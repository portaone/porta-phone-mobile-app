import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/encoding_settings.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../media_settings.dart';
import 'components/components.dart';

/// The media settings on a watch: the quality preset as a choice, the page
/// staying where it is; "Custom" among them only while it is in force, its
/// sliders being the phone's. The speaker toggle where the deployment offers
/// it, Reset to default after the watch confirm, and a line naming what stays
/// on the phone.
class MediaSettingsScreenWatch extends StatelessWidget {
  const MediaSettingsScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MediaSettingsCubit>();
    return BlocBuilder<MediaSettingsCubit, MediaSettingsState>(
      builder: (context, state) => SettingsWatchChoicePage<EncodingPreset?>(
        title: l10n.settings_ListViewTileTitle_mediaSettings,
        closeOnChoice: false,
        options: [
          for (final preset in <EncodingPreset?>[null, ...EncodingPreset.values])
            if (preset != EncodingPreset.custom || state.encodingPreset == EncodingPreset.custom)
              SettingsWatchOption(value: preset, label: encodingPresetLabel(context, preset)),
        ],
        selected: state.encodingPreset,
        onChosen: cubit.setEncodingPreset,
        footer: [
          if (state.speakerOnMinimizeConfigurable)
            WatchToggleChip(
              label: l10n.settings_speakerOnMinimize_switch,
              value: state.speakerOnMinimize,
              onChanged: cubit.setSpeakerOnMinimize,
            ),
          WatchListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: l10n.settings_encoding_AppBar_reset_tooltip,
            onTap: () => _onReset(context),
          ),
          WatchListNote(l10n.settings_media_Watch_onPhone),
        ],
      ),
    );
  }

  /// Asked first on a watch: the reset clears settings the watch cannot show
  /// or put back.
  Future<void> _onReset(BuildContext context) async {
    final cubit = context.read<MediaSettingsCubit>();
    final reset = await ConfirmDialog.show(context, title: context.l10n.settings_media_Watch_resetQuestion);
    if (reset == true) cubit.reset();
  }
}
