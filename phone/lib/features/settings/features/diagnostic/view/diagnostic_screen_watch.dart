import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/bloc/network_tester_cubit.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/agreement_status.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/diagnostic_cubit.dart';
import '../extensions/extensions.dart';
import '../models/models.dart';
import '../widgets/diagnostic_watch.dart';
import '../widgets/widgets.dart';

/// The diagnostic on a watch: the same checks as the phone's, as rows a watch
/// lists worst first; each opens its page, where the fix is the edge button.
class DiagnosticScreenWatch extends StatelessWidget {
  const DiagnosticScreenWatch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final androidTarget = PlatformInfo.isAndroid;
    final contactsAgreementStatus = context.watch<AppBloc>().state.contactsAgreementStatus;
    // Only what the network row shows: the tester changes with every
    // candidate gathered.
    final networkSummary = context.select((NetworkTesterCubit cubit) => NetworkTestSummary.of(cubit.state, l10n));
    final cubit = context.read<DiagnosticCubit>();

    return BlocBuilder<DiagnosticCubit, DiagnosticState>(
      builder: (context, state) {
        final push = state.pushTokenStatus;
        final checks = [
          DiagnosticWatchCheck(
            title: l10n.diagnosticScreen_pushNotificationService_title,
            status: push.type.title(context),
            level: switch (push.type) {
              PushTokenStatusType.success => DiagnosticWatchLevel.ok,
              PushTokenStatusType.error => DiagnosticWatchLevel.fail,
              _ => DiagnosticWatchLevel.checking,
            },
            // As the phone's sheet: the steps to try only for an error, nothing
            // while the token is still on its way. Each step ends in its own
            // line break, so they are joined as they are.
            description: switch (push.type) {
              PushTokenStatusType.success => l10n.diagnosticPushDetails_successMessage,
              PushTokenStatusType.error => [
                ?push.error,
                [
                  l10n.diagnosticPushDetails_errorMessage_intro,
                  l10n.diagnosticPushDetails_errorMessage_step1,
                  l10n.diagnosticPushDetails_errorMessage_step2,
                  l10n.diagnosticPushDetails_errorMessage_step3,
                  l10n.diagnosticPushDetails_errorMessage_step4,
                  l10n.diagnosticPushDetails_errorMessage_step5,
                ].join().trimRight(),
              ].join('\n'),
              PushTokenStatusType.progress => '',
            },
          ),
          if (androidTarget)
            DiagnosticWatchCheck(
              title: l10n.diagnostic_battery_tile_title,
              status: state.batteryMode.title(context),
              level: switch (state.batteryMode) {
                CallkeepAndroidBatteryMode.unrestricted => DiagnosticWatchLevel.ok,
                CallkeepAndroidBatteryMode.restricted => DiagnosticWatchLevel.fail,
                CallkeepAndroidBatteryMode.optimized || CallkeepAndroidBatteryMode.unknown => DiagnosticWatchLevel.warn,
              },
              description: _withHint(state.batteryMode.description(context), l10n.diagnostic_battery_navigate_section),
              fix: _manage(context, cubit.openAppSettings),
            ),
          if (androidTarget && state.callDeliveryMode == CallkeepAndroidCallDeliveryMode.standalone)
            DiagnosticWatchCheck(
              title: l10n.diagnostic_callingMode_tile_title,
              status: l10n.diagnostic_callingMode_standalone_title,
              level: DiagnosticWatchLevel.warn,
              description: l10n.diagnostic_callingMode_standalone_description,
            ),
          for (final permission in state.filterPermissionsByAgreement(
            exclude: [if (!contactsAgreementStatus.isAccepted) Permission.contacts],
          ))
            DiagnosticWatchCheck(
              title: permission.permission.title(context),
              status: permission.status.title(context),
              // The phone's colours: granted green, denied red, the limited
              // kinds of access orange.
              level: switch (permission.severity) {
                PermissionStatus.granted => DiagnosticWatchLevel.ok,
                PermissionStatus.denied || PermissionStatus.permanentlyDenied => DiagnosticWatchLevel.fail,
                _ => DiagnosticWatchLevel.warn,
              },
              description: permission.permission.description(context),
              fix: permission.isWorking
                  ? null
                  : WatchAction(
                      label: permission.status == PermissionStatus.denied
                          ? l10n.diagnostic_Watch_allow
                          : l10n.diagnostic_Watch_openSettings,
                      onPressed: () => cubit.handleRequestPermission(permission),
                    ),
            ),
          if (androidTarget)
            _special(
              context,
              title: l10n.diagnostic_fullScreenIntent_tile_title,
              description: _withHint(
                l10n.diagnostic_fullScreenIntent_description,
                l10n.diagnostic_fullScreenIntent_navigate_section,
              ),
              status: state.fullScreenIntentStatus,
              onFix: cubit.openFullScreenIntentSettings,
            ),
          if (androidTarget && state.isXiaomiDevice) ...[
            _special(
              context,
              title: l10n.diagnostic_xiaomi_backgroundActivityStart_tile_title,
              description: _withHint(
                l10n.diagnostic_xiaomi_backgroundActivityStart_description,
                l10n.diagnostic_xiaomi_navigate_section,
              ),
              status: state.backgroundActivityStartStatus,
              onFix: cubit.openBackgroundActivityStartSettings,
            ),
            _special(
              context,
              title: l10n.diagnostic_xiaomi_showWhenLocked_tile_title,
              description: _withHint(
                l10n.diagnostic_xiaomi_showWhenLocked_description,
                l10n.diagnostic_xiaomi_navigate_section,
              ),
              status: state.showWhenLockedStatus,
              onFix: cubit.openShowWhenLockedSettings,
            ),
          ],
          if (context.read<DiagnosticScreenContext>().isLocalContactsFeatureEnabled)
            DiagnosticWatchCheck(
              title: l10n.diagnosticScreen_contacts_agreement_title,
              status: l10n.diagnosticScreen_contacts_agreement_description,
              level: switch (contactsAgreementStatus) {
                AgreementStatus.accepted => DiagnosticWatchLevel.ok,
                AgreementStatus.declined => DiagnosticWatchLevel.fail,
                AgreementStatus.pending => DiagnosticWatchLevel.warn,
              },
              description: l10n.contacts_agreement_description,
              page: (_) => DiagnosticWatchAgreementPage(
                title: l10n.diagnosticScreen_contacts_agreement_title,
                description: l10n.contacts_agreement_description,
                status: contactsAgreementStatus,
                onApply: (value) => context.read<AppBloc>().add(AppAgreementAccepted.updateContactsAgreement(value)),
              ),
            ),
          DiagnosticWatchCheck(
            title: l10n.diagnostic_network_groupTitle,
            status: networkSummary.title,
            level: networkWatchLevel(networkSummary.level),
            description: networkSummary.subtitle,
            identifier: diagnosticNetworkTestId,
            page: (_) => BlocProvider.value(
              value: context.read<NetworkTesterCubit>(),
              child: DiagnosticWatchNetworkPage(title: l10n.diagnostic_network_groupTitle),
            ),
          ),
        ];
        return DiagnosticWatchList(title: l10n.diagnostic_AppBar_title, checks: checks);
      },
    );
  }

  /// What the check means and, under it, where in the settings to go: the
  /// phone's sheet names the section under its Manage permission, and the
  /// settings the fix opens do not lead there by themselves.
  String _withHint(String description, String navigationHint) => '$description\n\n$navigationHint';

  /// Opens the watch's own settings for the check, as the phone's Manage
  /// permission does.
  WatchAction _manage(BuildContext context, VoidCallback open) =>
      WatchAction(label: context.l10n.diagnostic_Watch_openSettings, onPressed: open);

  DiagnosticWatchCheck _special(
    BuildContext context, {
    required String title,
    required String description,
    required CallkeepSpecialPermissionStatus status,
    required VoidCallback onFix,
  }) => DiagnosticWatchCheck(
    title: title,
    status: status.title(context),
    level: switch (status) {
      CallkeepSpecialPermissionStatus.granted => DiagnosticWatchLevel.ok,
      CallkeepSpecialPermissionStatus.denied => DiagnosticWatchLevel.fail,
      CallkeepSpecialPermissionStatus.unknown => DiagnosticWatchLevel.warn,
    },
    description: description,
    fix: status == CallkeepSpecialPermissionStatus.granted ? null : _manage(context, onFix),
  );
}
