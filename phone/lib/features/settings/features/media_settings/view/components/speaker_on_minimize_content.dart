import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/features/settings/features/media_settings/media_settings.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// Lets a person decide whether an audio call moves to the loudspeaker when
/// its screen is left.
///
/// Shown only where the deployment asked for it - see
/// [MediaSettingsState.speakerOnMinimizeConfigurable].
class SpeakerOnMinimizeContent extends StatelessWidget {
  const SpeakerOnMinimizeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MediaSettingsCubit>();

    return BlocBuilder<MediaSettingsCubit, MediaSettingsState>(
      buildWhen: (p, c) => p.speakerOnMinimize != c.speakerOnMinimize,
      builder: (context, state) {
        return SwitchListTile(
          title: Text(context.l10n.settings_speakerOnMinimize_switch),
          value: state.speakerOnMinimize,
          onChanged: cubit.setSpeakerOnMinimize,
        );
      },
    );
  }
}
