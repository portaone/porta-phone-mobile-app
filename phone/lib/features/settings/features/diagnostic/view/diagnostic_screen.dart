import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/bloc/network_tester_cubit.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/agreement_status.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/widgets.dart';
import '../bloc/diagnostic_cubit.dart';
import '../models/models.dart';
import '../widgets/diagnostic_watch.dart';
import '../widgets/widgets.dart';
import '../extensions/extensions.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DiagnosticScreenState createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DiagnosticCubit>().fetchStatuses();
    }
  }

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// The same checks as the phone's, as rows a watch lists worst first; each
  /// opens its page, where the fix is the edge button.
  Widget _watch(BuildContext context) {
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
                      onPressed: () => _handleRequestPermission(permission),
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
              onFix: _openFullScreenIntentSettings,
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
              onFix: _openBackgroundActivityStartSettings,
            ),
            _special(
              context,
              title: l10n.diagnostic_xiaomi_showWhenLocked_tile_title,
              description: _withHint(
                l10n.diagnostic_xiaomi_showWhenLocked_description,
                l10n.diagnostic_xiaomi_navigate_section,
              ),
              status: state.showWhenLockedStatus,
              onFix: _openShowWhenLockedSettings,
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

  Widget _handset(BuildContext context) {
    final androidTarget = PlatformInfo.isAndroid;
    final contactsAgreementStatus = context.watch<AppBloc>().state.contactsAgreementStatus;
    // The system bar below the list, not the keyboard: this screen has no text
    // field, so the keyboard inset this used to read was always zero and the
    // padding below did nothing - the last row was drawn under the navigation
    // bar. `padding` rather than `viewPadding` on purpose: with a keyboard up
    // the scaffold already resizes the body, and the bar is covered anyway.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<DiagnosticCubit, DiagnosticState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(leading: const AutoLeadingButton(), title: Text(context.l10n.diagnostic_AppBar_title)),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                ListTile(
                  title: Text(context.l10n.diagnosticScreen_pushNotificationService_title),
                  trailing: Icon(
                    state.pushTokenStatus.type.isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: state.pushTokenStatus.type.isSuccess ? Colors.green : Colors.red,
                  ),
                  subtitle: Text(state.pushTokenStatus.type.title(context)),
                  onTap: () {
                    context.showModalBottomSheet(
                      builder: (BuildContext context) => DiagnosticPushDetails(
                        status: state.pushTokenStatus,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    );
                  },
                ),
                if (androidTarget) GroupTitleListTile(titleData: context.l10n.diagnostic_battery_groupTitle),
                if (androidTarget)
                  DiagnosticBatteryModeItem(
                    batteryMode: state.batteryMode,
                    onTap: () {
                      context.showModalBottomSheet(
                        builder: (BuildContext context) => DiagnosticBatteryModeDetails(
                          batteryMode: state.batteryMode,
                          onTap: () {
                            _openPermissions();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                if (androidTarget && state.callDeliveryMode == CallkeepAndroidCallDeliveryMode.standalone) ...[
                  GroupTitleListTile(titleData: context.l10n.diagnostic_callingMode_groupTitle),
                  DiagnosticCallingModeItem(
                    onTap: () => context.showModalBottomSheet(
                      builder: (BuildContext context) => const DiagnosticCallingModeDetails(),
                    ),
                  ),
                ],
                GroupTitleListTile(titleData: context.l10n.diagnosticScreen_permissionsGroup_title),
                ...state
                    .filterPermissionsByAgreement(
                      exclude: [if (!contactsAgreementStatus.isAccepted) Permission.contacts],
                    )
                    .map(
                      (permission) => DiagnosticPermissionItem(
                        permissionWithStatus: permission,
                        onTap: () => context.showModalBottomSheet(
                          builder: (BuildContext context) {
                            return DiagnosticPermissionDetails(
                              permissionWithStatus: permission,
                              onTap: () {
                                _handleRequestPermission(permission);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                if (androidTarget) ...[
                  GroupTitleListTile(titleData: context.l10n.diagnostic_fullScreenIntent_groupTitle),
                  DiagnosticSpecialPermissionItem(
                    title: context.l10n.diagnostic_fullScreenIntent_tile_title,
                    status: state.fullScreenIntentStatus,
                    onTap: () {
                      context.showModalBottomSheet(
                        builder: (BuildContext context) => DiagnosticSpecialPermissionDetails(
                          title: context.l10n.diagnostic_fullScreenIntent_tile_title,
                          description: context.l10n.diagnostic_fullScreenIntent_description,
                          navigationHint: context.l10n.diagnostic_fullScreenIntent_navigate_section,
                          status: state.fullScreenIntentStatus,
                          onTap: () {
                            _openFullScreenIntentSettings();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ],
                if (androidTarget && state.isXiaomiDevice) ...[
                  GroupTitleListTile(titleData: context.l10n.diagnostic_xiaomi_groupTitle),
                  DiagnosticSpecialPermissionItem(
                    title: context.l10n.diagnostic_xiaomi_backgroundActivityStart_tile_title,
                    status: state.backgroundActivityStartStatus,
                    onTap: () {
                      context.showModalBottomSheet(
                        builder: (BuildContext context) => DiagnosticSpecialPermissionDetails(
                          title: context.l10n.diagnostic_xiaomi_backgroundActivityStart_tile_title,
                          description: context.l10n.diagnostic_xiaomi_backgroundActivityStart_description,
                          navigationHint: context.l10n.diagnostic_xiaomi_navigate_section,
                          status: state.backgroundActivityStartStatus,
                          onTap: () {
                            _openBackgroundActivityStartSettings();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                  DiagnosticSpecialPermissionItem(
                    title: context.l10n.diagnostic_xiaomi_showWhenLocked_tile_title,
                    status: state.showWhenLockedStatus,
                    onTap: () {
                      context.showModalBottomSheet(
                        builder: (BuildContext context) => DiagnosticSpecialPermissionDetails(
                          title: context.l10n.diagnostic_xiaomi_showWhenLocked_tile_title,
                          description: context.l10n.diagnostic_xiaomi_showWhenLocked_description,
                          navigationHint: context.l10n.diagnostic_xiaomi_navigate_section,
                          status: state.showWhenLockedStatus,
                          onTap: () {
                            _openShowWhenLockedSettings();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ],
                Visibility(
                  visible: context.read<DiagnosticScreenContext>().isLocalContactsFeatureEnabled,
                  child: GroupTitleListTile(titleData: context.l10n.diagnosticScreen_contacts_agreement_group_title),
                ),
                Visibility(
                  visible: context.read<DiagnosticScreenContext>().isLocalContactsFeatureEnabled,
                  child: DiagnosticAgreementItem(
                    title: context.l10n.diagnosticScreen_contacts_agreement_title,
                    description: context.l10n.diagnosticScreen_contacts_agreement_description,
                    status: contactsAgreementStatus,
                    onTap: () {
                      context.showModalBottomSheet(
                        builder: (BuildContext context) => DiagnosticAgreementDetails(
                          title: context.l10n.diagnosticScreen_contacts_agreement_title,
                          description: context.l10n.contacts_agreement_description,
                          status: contactsAgreementStatus,
                          onApply: (AgreementStatus value) {
                            context.read<AppBloc>().add(AppAgreementAccepted.updateContactsAgreement(value));
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
                GroupTitleListTile(titleData: context.l10n.diagnostic_network_groupTitle),
                DiagnosticNetworkTestItem(
                  onTap: () {
                    context.showModalBottomSheet(
                      builder: (_) => BlocProvider.value(
                        value: context.read<NetworkTesterCubit>(),
                        child: DiagnosticNetworkTestDetails(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRequestPermission(PermissionWithStatus permission) {
    context.read<DiagnosticCubit>().handleRequestPermission(permission);
  }

  void _openPermissions() {
    context.read<DiagnosticCubit>().openAppSettings();
  }

  void _openShowWhenLockedSettings() {
    context.read<DiagnosticCubit>().openShowWhenLockedSettings();
  }

  void _openBackgroundActivityStartSettings() {
    context.read<DiagnosticCubit>().openBackgroundActivityStartSettings();
  }

  void _openFullScreenIntentSettings() {
    context.read<DiagnosticCubit>().openFullScreenIntentSettings();
  }
}
