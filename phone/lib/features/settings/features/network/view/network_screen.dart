import 'dart:async';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webtrit_phone/app/keys.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../bloc/network_cubit.dart';
import '../models/incoming_call_type_model.dart';
import '../../../widgets/settings_watch_choice.dart';
import '../widgets/widgets.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  late final NetworkCubit _cubit = context.read<NetworkCubit>();

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// The two ways calls are delivered as a choice, the page staying where it
  /// is; their explanations behind one row, as a page of text; the SMS
  /// fallback as a toggle pill, as offered as the phone's checkbox.
  Widget _watch(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<NetworkCubit, NetworkState>(
      listenWhen: (previous, current) => previous.incomingCallType != current.incomingCallType,
      listener: (context, state) => _onIncomingTypeChanged(state),
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
        onChosen: _cubit.selectIncomingCallType,
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
            onChanged: _cubit.smsFallbackAvailable ? (_) {} : null,
          ),
        ],
      ),
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

  Widget _handset(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings_ListViewTileTitle_network), leading: const ExtBackButton()),
      body: BlocConsumer<NetworkCubit, NetworkState>(
        listenWhen: (previous, current) {
          return previous.incomingCallType != current.incomingCallType;
        },
        listener: (context, state) => _onIncomingTypeChanged(state),
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    context.l10n.settings_network_incomingCallType_title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RadioGroup<IncomingCallTypeModel?>(
                  groupValue: state.incomingCallTypeModels.firstWhereOrNull((value) => value.selected),
                  onChanged: (value) {
                    if (value == null) return;

                    _cubit.selectIncomingCallType(value);
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.incomingCallTypeModels.length,
                    itemBuilder: (context, index) {
                      final item = state.incomingCallTypeModels[index];
                      return SemanticAction(
                        identifier: settingsOptionId(
                          settingsIncomingCallTypeOptionIdPrefix,
                          item.incomingCallType.name,
                        ),
                        child: RadioListTile<IncomingCallTypeModel?>(
                          value: item,
                          title: Text(item.incomingCallType.titleL10n(context)),
                          secondary: InfoTooltip(message: item.incomingCallType.descriptionL10n(context)),
                        ),
                      );
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    context.l10n.settings_network_fallbackCalls_title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: InfoTooltip(message: context.l10n.settings_network_fallbackCalls_description),
                ),
                CheckboxListTile(
                  value: state.smsFallbackEnabled,
                  enabled: _cubit.smsFallbackAvailable,
                  controlAffinity: ListTileControlAffinity.leading,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {},
                  title: Text(
                    context.l10n.settings_network_smsFallback_toggle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onIncomingTypeChanged(NetworkState state) async {
    if (state.isSelectedTypeInRemainder) await _showTypeReminder(state.incomingCallType);
    if (state.incomingCallType == IncomingCallType.socket) await _checkAndShowBatteryWarning();
  }

  Future<void> _showTypeReminder(IncomingCallType type) async {
    final title = type.remainderTitleL10n(context);
    final description = type.remainderDescriptionL10n(context);

    if (context.mounted && title != null && description != null) {
      await AcknowledgeDialog.show(context, title: title, content: description);
    }
  }

  Future<void> _checkAndShowBatteryWarning() async {
    final needsWarning = await _cubit.isSocketMissingBatteryExemption();
    if (!needsWarning || !mounted) return;

    final openSettings = context.formFactor == FormFactor.watch
        ? await ConfirmDialog.show(
            context,
            title: context.l10n.batteryOptimizationWarningTitle,
            content: context.l10n.batteryOptimizationWarningContent,
            confirmLabel: context.l10n.batteryOptimizationWarningOpenSettings,
          )
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(ctx.l10n.batteryOptimizationWarningTitle),
              content: Text(ctx.l10n.batteryOptimizationWarningContent),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(ctx.l10n.alertDialogActions_no)),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(ctx.l10n.batteryOptimizationWarningOpenSettings),
                ),
              ],
            ),
          );
    if (openSettings == true && mounted) {
      await _cubit.openBatterySettings();
    }
  }
}
