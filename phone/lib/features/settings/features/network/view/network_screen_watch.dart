import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../bloc/network_cubit.dart';
import '../extensions/extensions.dart';
import '../models/incoming_call_type_model.dart';

/// The network settings on a watch: the two ways calls are delivered as a
/// choice, the page staying where it is; their explanations behind one row,
/// as a page of text; the SMS fallback as a toggle pill, as offered as the
/// phone's checkbox.
class NetworkScreenWatch extends StatelessWidget {
  const NetworkScreenWatch({super.key, required this.onTypeReminder, required this.onBatteryWarning});

  /// Reminds of what the chosen way needs, where it has a reminder.
  final Future<void> Function(IncomingCallType type) onTypeReminder;

  /// Asks through the given question whether to open the battery settings,
  /// where the persistent connection needs an exemption the app lacks.
  final Future<void> Function(Future<bool?> Function() ask) onBatteryWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NetworkCubit>();
    return BlocConsumer<NetworkCubit, NetworkState>(
      listenWhen: (previous, current) => previous.incomingCallType != current.incomingCallType,
      listener: (context, state) => _onIncomingTypeChanged(context, state),
      builder: (context, state) => SettingsWatchChoicePage<IncomingCallTypeModel>(
        title: l10n.settings_ListViewTileTitle_network,
        closeOnChoice: false,
        header: [WatchListLabel(l10n.settings_network_incomingCallType_title)],
        options: [
          for (final item in state.incomingCallTypeModels)
            SettingsWatchOption(
              value: item,
              label: item.incomingCallType.titleL10n(context),
              identifier: settingsOptionId(settingsIncomingCallTypeOptionIdPrefix, item.incomingCallType.name),
            ),
        ],
        selected: state.incomingCallTypeModels.firstWhereOrNull((value) => value.selected),
        onChosen: cubit.selectIncomingCallType,
        footer: [
          WatchListTile(
            leading: const Icon(Icons.info_outline),
            title: l10n.settings_network_Watch_howTheyDiffer,
            onTap: () => _onHowTheyDiffer(context, state),
          ),
          WatchListLabel(l10n.settings_network_fallbackCalls_title),
          WatchToggleChip(
            label: l10n.settings_network_smsFallback_toggle,
            value: state.smsFallbackEnabled,
            // As the phone's checkbox: shown enabled where the brand offers
            // the fallback, and changing nothing.
            onChanged: cubit.smsFallbackAvailable ? (_) {} : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onIncomingTypeChanged(BuildContext context, NetworkState state) async {
    if (state.isSelectedTypeInRemainder) await onTypeReminder(state.incomingCallType);
    if (state.incomingCallType == IncomingCallType.socket) await onBatteryWarning(() => _askBatteryWarning(context));
  }

  /// The battery warning as the watch confirm, its yes named Open Settings.
  Future<bool?> _askBatteryWarning(BuildContext context) async {
    if (!context.mounted) return false;
    return ConfirmDialog.show(
      context,
      title: context.l10n.batteryOptimizationWarningTitle,
      content: context.l10n.batteryOptimizationWarningContent,
      confirmLabel: context.l10n.batteryOptimizationWarningOpenSettings,
    );
  }

  /// Both explanations, each under its way's name, on the text page.
  void _onHowTheyDiffer(BuildContext context, NetworkState state) {
    final text = [
      for (final item in state.incomingCallTypeModels)
        '${item.incomingCallType.titleL10n(context)}\n\n${item.incomingCallType.descriptionL10n(context)}',
    ].join('\n\n');
    // Navigate rather than push: a second tap on the way there must not
    // stack the same text twice.
    unawaited(context.router.root.navigate(WatchTextScreenPageRoute(text: text)));
  }
}
