import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/iterable.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../models/presence_settings_preset.dart';

/// Side of the presence mark shown beside a preset in the chooser.
///
/// The glyph inside the mark is a share of it (`side * 0.55`), so at the 16 dp
/// this used to be it came out at 9 dp against a 14 dp label and read as a
/// smudge; this keeps the two about the same size.
const _presetMarkSide = 24.0;

/// The preset [settings] match, null when they match none.
PresenceSettingsPreset? matchingPresenceSettingsPreset(
  List<PresenceSettingsPreset> presets,
  PresenceSettings settings,
) => presets.firstWhereOrNull(
  (element) =>
      element.available == settings.available &&
      element.note == settings.note &&
      element.activity == settings.activity &&
      element.dndMode == settings.dndMode,
);

/// The settings [preset] sets, over what it leaves alone in [settings].
PresenceSettings applyPresenceSettingsPreset(PresenceSettings settings, PresenceSettingsPreset preset) => settings
    .copyWithAvailable(preset.available)
    .copyWithNote(preset.note)
    .copyWithActivity(preset.activity)
    .copyWithDndMode(preset.dndMode);

/// The presence mark of a preset, as a contact with that presence shows it.
class PresenceSettingsPresetMark extends StatelessWidget {
  const PresenceSettingsPresetMark({super.key, required this.preset});

  final PresenceSettingsPreset preset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _presetMarkSide,
      height: _presetMarkSide,
      child: SipPresenceIndicator(
        presenceInfo: [
          PresenceInfo(
            id: 'id',
            number: 'number',
            available: preset.available,
            note: preset.note,
            activities: [?preset.activity],
            statusIcon: null,
            device: 'device',
            timeOffsetMin: 0,
            timestamp: DateTime.now(),
            source: PresenceInfoSource.direct,
            arrivalTime: DateTime.now(),
          ),
        ],
        presenceRect: const Rect.fromLTWH(0, 0, _presetMarkSide, _presetMarkSide),
        dialogInfo: const [],
      ),
    );
  }
}
