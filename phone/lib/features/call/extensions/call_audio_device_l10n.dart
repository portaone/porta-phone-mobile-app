import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';

extension CallAudioDeviceL10n on CallAudioDevice {
  /// The device as the person knows it: the system's own name for a headset
  /// or a stream, the built-in ones by what they are.
  String l10n(BuildContext context) {
    return switch (type) {
      CallAudioDeviceType.speaker => context.l10n.call_CallActionsTooltip_device_speaker,
      CallAudioDeviceType.earpiece => context.l10n.call_CallActionsTooltip_device_earpiece,
      CallAudioDeviceType.wiredHeadset => context.l10n.call_CallActionsTooltip_device_wiredHeadset,
      CallAudioDeviceType.bluetooth => name ?? context.l10n.call_CallActionsTooltip_device_bluetooth,
      CallAudioDeviceType.streaming => name ?? context.l10n.call_CallActionsTooltip_device_streaming,
      _ => name ?? context.l10n.call_CallActionsTooltip_device_unknown,
    };
  }
}

extension CallAudioDeviceTypeIcon on CallAudioDeviceType {
  IconData get icon {
    return switch (this) {
      CallAudioDeviceType.speaker => Icons.volume_up,
      CallAudioDeviceType.bluetooth => Icons.bluetooth_audio,
      CallAudioDeviceType.wiredHeadset => Icons.headset,
      CallAudioDeviceType.earpiece => Icons.phone_in_talk,
      CallAudioDeviceType.streaming => Icons.usb,
      CallAudioDeviceType.unknown => Icons.device_unknown,
    };
  }
}
